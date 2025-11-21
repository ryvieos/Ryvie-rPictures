# Synchronisation LDAP pour Immich

## Description

Ce module permet de synchroniser automatiquement les utilisateurs depuis un serveur LDAP vers la base de données Immich. Il a été créé en s'inspirant de l'implémentation dans rPictures.

## Configuration

Les variables d'environnement suivantes doivent être configurées pour utiliser la synchronisation LDAP :

### Variables obligatoires

- `LDAP_URL` : URL du serveur LDAP (par défaut: `ldap://openldap:1389`)
- `LDAP_BIND_DN` : DN de connexion pour le bind LDAP (par défaut: `cn=admin,dc=example,dc=org`)
- `LDAP_BIND_PASSWORD` : Mot de passe pour le bind LDAP (par défaut: `adminpassword`)
- `LDAP_USER_BASE_DN` : Base DN pour la recherche des utilisateurs (par défaut: `ou=users,dc=example,dc=org`)

### Variables optionnelles

- `LDAP_USER_FILTER` : Filtre LDAP pour les utilisateurs (par défaut: `(objectClass=inetOrgPerson)`)
- `LDAP_EMAIL_ATTRIBUTE` : Attribut LDAP pour l'email (par défaut: `mail`)
- `LDAP_NAME_ATTRIBUTE` : Attribut LDAP pour le nom (par défaut: `cn`)
- `LDAP_PASSWORD_ATTRIBUTE` : Attribut LDAP pour le mot de passe (par défaut: `userPassword`)
- `LDAP_ADMIN_GROUP` : Nom du groupe LDAP pour les administrateurs (par défaut: `admins`)

## Exemple de configuration dans docker-compose.yml

```yaml
services:
  immich-server:
    environment:
      - LDAP_URL=ldap://openldap:1389
      - LDAP_BIND_DN=cn=admin,dc=example,dc=org
      - LDAP_BIND_PASSWORD=adminpassword
      - LDAP_USER_BASE_DN=ou=users,dc=example,dc=org
      - LDAP_USER_FILTER=(objectClass=inetOrgPerson)
      - LDAP_EMAIL_ATTRIBUTE=mail
      - LDAP_NAME_ATTRIBUTE=cn
      - LDAP_PASSWORD_ATTRIBUTE=userPassword
      - LDAP_ADMIN_GROUP=admins
```

## Utilisation

### Endpoint API

La synchronisation peut être déclenchée via l'endpoint suivant :

```
GET /ldap/sync
```

Cet endpoint est **public** et ne nécessite pas d'authentification. Pour des raisons de sécurité, vous devriez le protéger au niveau du reverse proxy ou ajouter une authentification si nécessaire.

### Exemple avec curl

```bash
curl -X GET http://localhost:2283/api/ldap/sync
```

### Réponse

L'endpoint retourne un objet JSON avec les statistiques de synchronisation :

```json
{
  "created": 5,
  "updated": 2,
  "skipped": 3
}
```

- `created` : Nombre d'utilisateurs créés
- `updated` : Nombre d'utilisateurs mis à jour
- `skipped` : Nombre d'utilisateurs ignorés (pas de mot de passe ou aucune modification nécessaire)

## Fonctionnement

1. **Connexion LDAP** : Le module se connecte au serveur LDAP avec les credentials fournis
2. **Recherche des utilisateurs** : Récupère tous les utilisateurs correspondant au filtre LDAP
3. **Vérification des groupes** : Pour chaque utilisateur, vérifie s'il appartient au groupe admin
4. **Synchronisation** :
   - Si l'utilisateur existe déjà : met à jour son mot de passe et son statut admin si nécessaire
   - Si l'utilisateur n'existe pas : crée un nouveau compte avec les informations LDAP
   - Si l'utilisateur n'a pas de mot de passe : ignore l'utilisateur

## Logs

Le module génère des logs détaillés pour suivre le processus de synchronisation :

- Connexion LDAP établie
- Nombre d'utilisateurs trouvés
- Traitement de chaque utilisateur
- Résumé de la synchronisation (créés, mis à jour, ignorés)
- Erreurs éventuelles

## Sécurité

⚠️ **Important** : 

- Les mots de passe LDAP sont hashés avec bcrypt (10 rounds) avant d'être stockés
- L'endpoint de synchronisation est public par défaut - protégez-le au niveau du reverse proxy
- Assurez-vous que les credentials LDAP sont stockés de manière sécurisée
- Utilisez LDAPS (LDAP over SSL) en production

## Dépendances

- `ldapjs` : Client LDAP pour Node.js
- `@types/ldapjs` : Types TypeScript pour ldapjs

Ces dépendances ont été installées automatiquement lors de la création du module.
