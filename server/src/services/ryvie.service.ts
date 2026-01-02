import { Injectable, Logger } from '@nestjs/common';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { RyvieTunnelInfoDto } from 'src/dtos/ryvie.dto';

@Injectable()
export class RyvieService {
  private logger = new Logger(RyvieService.name);
  private readonly configPath = '/etc/ryvie/config.json';

  /**
   * Récupère les informations du tunnel Ryvie depuis le fichier de configuration
   * Compatible avec le format attendu par Ryvie-Desktop
   */
  async getTunnelInfo(): Promise<RyvieTunnelInfoDto> {
    try {
      // Vérifier si le fichier de configuration existe
      if (!fs.existsSync(this.configPath)) {
        this.logger.warn(`Configuration file not found at ${this.configPath}`);
        return this.getDefaultResponse();
      }

      // Lire le fichier de configuration
      const configContent = fs.readFileSync(this.configPath, 'utf-8');
      const config = JSON.parse(configContent);

      // Construire la réponse
      const response: RyvieTunnelInfoDto = {
        success: true,
        ryvieId: config.ryvieId || undefined,
        tunnelHost: config.tunnelHost || config.netbird?.ip || undefined,
        publicUrl: this.buildPublicUrl(config),
        domains: {
          app: config.domains?.app || undefined,
          api: config.domains?.api || undefined,
        },
        setupKey: config.netbird?.setupKey || undefined,
      };

      this.logger.log('Tunnel info retrieved successfully');
      return response;
    } catch (error) {
      this.logger.error(`Error reading Ryvie configuration: ${error}`);
      return this.getDefaultResponse();
    }
  }

  /**
   * Construit l'URL publique à partir de la configuration
   */
  private buildPublicUrl(config: any): string | undefined {
    // Priorité 1: URL publique explicite
    if (config.publicUrl) {
      return config.publicUrl;
    }

    // Priorité 2: Domaine app avec HTTPS
    if (config.domains?.app) {
      return `https://${config.domains.app}`;
    }

    // Priorité 3: Tunnel host avec port 3000
    if (config.tunnelHost) {
      return `http://${config.tunnelHost}:3000`;
    }

    // Priorité 4: IP NetBird avec port 3000
    if (config.netbird?.ip) {
      return `http://${config.netbird.ip}:3000`;
    }

    return undefined;
  }

  /**
   * Retourne une réponse par défaut quand aucune configuration n'est disponible
   */
  private getDefaultResponse(): RyvieTunnelInfoDto {
    return {
      success: false,
    };
  }

  /**
   * Sauvegarde les informations du tunnel (pour usage futur)
   */
  async saveTunnelInfo(
    ryvieId?: string,
    tunnelHost?: string,
    publicUrl?: string,
    domains?: { app?: string; api?: string },
    setupKey?: string,
  ): Promise<void> {
    try {
      const configDir = path.dirname(this.configPath);
      
      // Créer le répertoire s'il n'existe pas
      if (!fs.existsSync(configDir)) {
        fs.mkdirSync(configDir, { recursive: true });
      }

      // Lire la configuration existante ou créer une nouvelle
      let config: any = {};
      if (fs.existsSync(this.configPath)) {
        const configContent = fs.readFileSync(this.configPath, 'utf-8');
        config = JSON.parse(configContent);
      }

      // Mettre à jour les valeurs
      if (ryvieId !== undefined) config.ryvieId = ryvieId;
      if (tunnelHost !== undefined) config.tunnelHost = tunnelHost;
      if (publicUrl !== undefined) config.publicUrl = publicUrl;
      if (domains !== undefined) config.domains = domains;
      if (setupKey !== undefined) {
        if (!config.netbird) config.netbird = {};
        config.netbird.setupKey = setupKey;
      }

      // Sauvegarder le fichier
      fs.writeFileSync(this.configPath, JSON.stringify(config, null, 2));
      this.logger.log('Tunnel info saved successfully');
    } catch (error) {
      this.logger.error(`Error saving Ryvie configuration: ${error}`);
      throw error;
    }
  }
}
