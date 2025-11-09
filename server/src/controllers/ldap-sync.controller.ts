import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { UserRepository } from 'src/repositories/user.repository';
import { CryptoRepository } from 'src/repositories/crypto.repository';
import { LoggingRepository } from 'src/repositories/logging.repository';
import { SALT_ROUNDS } from 'src/constants';
import * as ldap from 'ldapjs';
import { promisify } from 'util';
import { randomUUID } from 'crypto';

interface LdapUser {
  mail: string;
  cn: string[];
  userPassword?: string;
  isAdmin: boolean;
}

@ApiTags('LDAP Sync')
@Controller('ldap')
export class LdapSyncController {
  private ldapClient: ldap.Client | null = null;

  constructor(
    private userRepository: UserRepository,
    private cryptoRepository: CryptoRepository,
    private logger: LoggingRepository,
  ) {}

  private getLdapClient(): ldap.Client {
    if (!this.ldapClient) {
      this.ldapClient = ldap.createClient({
        url: process.env.LDAP_URL || 'ldap://openldap:1389'
      });
    }
    return this.ldapClient;
  }

  private async bindLdap(): Promise<void> {
    const client = this.getLdapClient();
    const bind = promisify(client.bind.bind(client));
    await bind(
      process.env.LDAP_BIND_DN || 'cn=admin,dc=example,dc=org',
      process.env.LDAP_BIND_PASSWORD || 'adminpassword'
    );
  }

  private async isUserInGroup(userDn: string, groupCn: string): Promise<boolean> {
    const client = this.getLdapClient();
    const search = promisify<string, ldap.SearchOptions, ldap.SearchCallbackResponse>(client.search.bind(client));
    const results = await search(process.env.LDAP_USER_BASE_DN || 'ou=users,dc=example,dc=org', {
      scope: 'sub',
      filter: `(&(objectClass=groupOfNames)(cn=${groupCn})(member=${userDn}))`,
    });

    return new Promise((resolve) => {
      let found = false;
      
      results.on('searchEntry', () => {
        found = true;
      });

      results.on('end', () => {
        resolve(found);
      });

      results.on('error', () => {
        resolve(false);
      });
    });
  }

  private async getAllLdapUsers(): Promise<LdapUser[]> {
    const client = this.getLdapClient();
    const search = promisify<string, ldap.SearchOptions, ldap.SearchCallbackResponse>(client.search.bind(client));
    this.logger.log('Searching LDAP users...');
    
    const results = await search(process.env.LDAP_USER_BASE_DN || 'ou=users,dc=example,dc=org', {
      scope: 'sub',
      filter: process.env.LDAP_USER_FILTER || '(objectClass=inetOrgPerson)',
    });

    return new Promise((resolve, reject) => {
      const entries: LdapUser[] = [];
      const promises: Promise<void>[] = [];
      
      results.on('searchEntry', (entry: ldap.SearchEntry) => {
        const ldapUser = entry.pojo as any;
        this.logger.log('Raw LDAP data:', JSON.stringify(ldapUser, null, 2));
        
        if (!ldapUser.objectName || !ldapUser.attributes) {
          this.logger.warn(`Invalid LDAP user - DN: ${ldapUser.objectName}`);
          return;
        }

        const attributes = ldapUser.attributes.reduce((acc: any, attr: any) => {
          acc[attr.type] = attr.values;
          return acc;
        }, {});

        const emailAttr = process.env.LDAP_EMAIL_ATTRIBUTE || 'mail';
        const nameAttr = process.env.LDAP_NAME_ATTRIBUTE || 'cn';
        const passwordAttr = process.env.LDAP_PASSWORD_ATTRIBUTE || 'userPassword';

        if (!attributes[emailAttr] || !attributes[nameAttr]) {
          this.logger.warn(`LDAP user without email or cn - DN: ${ldapUser.objectName}`);
          return;
        }

        const adminGroup = process.env.LDAP_ADMIN_GROUP || 'admins';
        promises.push(
          this.isUserInGroup(ldapUser.objectName, adminGroup)
            .then(isAdmin => {
              entries.push({
                mail: attributes[emailAttr][0],
                cn: attributes[nameAttr],
                userPassword: attributes[passwordAttr] ? attributes[passwordAttr][0] : undefined,
                isAdmin
              });
            })
        );
      });

      results.on('error', (err: Error) => {
        this.logger.error('Error during LDAP search:', err);
        reject(err);
      });

      results.on('end', async () => {
        try {
          await Promise.all(promises);
          this.logger.log(`Total LDAP users found: ${entries.length}`);
          this.logger.log(`Valid users:`, entries);
          resolve(entries);
        } catch (error) {
          reject(error);
        }
      });
    });
  }

  @Get('sync')
  @ApiOperation({ summary: 'Synchronize users from LDAP (Public endpoint)' })
  async syncLdap() {
    this.logger.log('Starting LDAP users synchronization');
    try {
      await this.bindLdap();
      this.logger.log('LDAP connection established');
      
      const ldapUsers = await this.getAllLdapUsers();
      this.logger.log(`Starting synchronization for ${ldapUsers.length} users`);
      
      let created = 0;
      let skipped = 0;
      let updated = 0;

      for (const ldapUser of ldapUsers) {
        try {
          this.logger.log(`Processing LDAP user: ${ldapUser.mail}`);

          if (!ldapUser.userPassword) {
            this.logger.warn(`No password for user ${ldapUser.mail}, skipped`);
            skipped++;
            continue;
          }

          const hashedPassword = await this.cryptoRepository.hashBcrypt(ldapUser.userPassword, SALT_ROUNDS);

          const existingUser = await this.userRepository.getByEmail(ldapUser.mail);
          if (existingUser) {
            let needsUpdate = false;
            const updates: any = {};

            if (existingUser.isAdmin !== ldapUser.isAdmin) {
              updates.isAdmin = ldapUser.isAdmin;
              needsUpdate = true;
            }

            updates.password = hashedPassword;
            needsUpdate = true;

            if (needsUpdate) {
              await this.userRepository.update(existingUser.id, updates);
              this.logger.log(`Updated user ${ldapUser.mail}`);
              updated++;
            } else {
              this.logger.log(`No update needed for ${ldapUser.mail}`);
              skipped++;
            }
            continue;
          }

          const storageLabel = `user-${randomUUID()}`;
          await this.userRepository.create({
            isAdmin: ldapUser.isAdmin,
            email: ldapUser.mail,
            name: ldapUser.cn[0],
            password: hashedPassword,
            storageLabel,
            shouldChangePassword: false,
          });
          created++;
          this.logger.log(`Created user account for ${ldapUser.mail}`);
        } catch (error) {
          this.logger.error(`Error processing user ${ldapUser.mail}:`, error);
        }
      }

      this.logger.log(`LDAP synchronization completed. Created: ${created}, Updated: ${updated}, Skipped: ${skipped}`);
      return { created, updated, skipped };
    } catch (err) {
      const error = err as Error;
      this.logger.error(`LDAP synchronization failed: ${error.message}`);
      throw error;
    }
  }
}
