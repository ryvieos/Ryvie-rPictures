# Sélection Intelligente d'URL Serveur

## Vue d'ensemble

L'application rPictures mobile implémente désormais une sélection intelligente de l'URL du serveur, inspirée de Ryvie-Desktop. Cette fonctionnalité permet à l'application de choisir automatiquement la meilleure URL pour se connecter au serveur Ryvie.

## Fonctionnement

### Logique de Sélection

1. **Connexion Locale (Prioritaire)**

   - L'application tente d'abord de se connecter à `http://ryvie.local:3000`
   - Si la connexion réussit, cette URL est utilisée
   - Avantage: Connexion rapide et directe sur le réseau local

2. **Connexion Publique (Fallback)**
   - Si la connexion locale échoue, l'application utilise l'URL publique configurée
   - L'URL publique peut être:
     - Une URL complète (ex: `https://votre-domaine.com`)
     - Construite à partir du `tunnelHost` (ex: `http://100.64.0.1:3000`)

### Configuration

#### Automatique (Recommandé)

L'application récupère **automatiquement** les informations du tunnel depuis le serveur Ryvie lorsqu'elle se connecte en local (`ryvie.local:3000`). Aucune configuration manuelle n'est nécessaire !

**Comment ça marche :**

1. L'application se connecte à `http://ryvie.local:3000`
2. Elle appelle l'API `/api/server/ryvie-tunnel-info` en arrière-plan
3. Les informations (tunnelHost, publicUrl) sont automatiquement sauvegardées
4. Un indicateur vert s'affiche dans les paramètres pour confirmer la configuration automatique

#### Manuelle (Optionnelle)

Si nécessaire, vous pouvez aussi configurer manuellement :

1. Ouvrez l'application rPictures
2. Allez dans **Paramètres** → **Réseau** → **Configuration du Tunnel**
3. Remplissez les champs:
   - **Hôte du Tunnel**: Adresse IP ou hostname du tunnel (ex: `100.64.0.1`)
   - **URL Publique**: URL publique complète (ex: `https://votre-domaine.com` ou `http://100.64.0.1:3000`)
4. Cliquez sur **Enregistrer**

#### Activation de la Sélection Intelligente

La sélection intelligente d'URL est automatiquement utilisée lorsque:

- La fonctionnalité "Automatic URL switching" est activée dans les paramètres réseau
- L'application appelle `setOpenApiServiceEndpoint()`

## Architecture Technique

### Fichiers Créés/Modifiés

1. **`lib/services/smart_url_selector.service.dart`** (Nouveau)

   - Service principal pour la sélection intelligente d'URL
   - Teste la connectivité des URLs
   - Gère la sauvegarde/récupération des informations du tunnel

2. **`lib/domain/models/store.model.dart`** (Modifié)

   - Ajout des clés `tunnelHost` et `publicUrl` dans `StoreKey`

3. **`lib/services/auth.service.dart`** (Modifié)

   - Intégration du `SmartUrlSelectorService`
   - Ajout des méthodes `saveTunnelInfo()` et `getTunnelInfo()`
   - Modification de `setOpenApiServiceEndpoint()` pour utiliser la sélection intelligente

4. **`lib/providers/auth.provider.dart`** (Modifié)

   - Ajout des méthodes proxy pour `saveTunnelInfo()` et `getTunnelInfo()`

5. **`lib/widgets/settings/networking_settings/tunnel_settings.dart`** (Nouveau)

   - Widget UI pour configurer les informations du tunnel

6. **`lib/widgets/settings/networking_settings/networking_settings.dart`** (Modifié)

   - Intégration du widget `TunnelSettings`

7. **Fichiers de traduction** (Modifiés)
   - `i18n/en.json`: Ajout des traductions anglaises
   - `i18n/fr.json`: Ajout des traductions françaises

### Flux de Données

```
User Input (UI)
    ↓
AuthProvider.saveTunnelInfo()
    ↓
AuthService.saveTunnelInfo()
    ↓
SmartUrlSelectorService.saveTunnelInfo()
    ↓
Store (StoreKey.tunnelHost, StoreKey.publicUrl)
```

```
App Startup / Network Change
    ↓
AuthService.setOpenApiServiceEndpoint()
    ↓
SmartUrlSelectorService.selectServerUrl()
    ↓
1. Test http://ryvie.local:3000
    ↓ (si échec)
2. Récupère publicUrl ou construit depuis tunnelHost
    ↓
3. Test URL publique
    ↓
4. Retourne URL sélectionnée
    ↓
ApiService.resolveAndSetEndpoint()
```

## Comparaison avec Ryvie-Desktop

### Similitudes

- Même logique de priorité: local d'abord, puis public
- Même URL locale: `http://ryvie.local:3000`
- Récupération automatique des informations du tunnel depuis le serveur
- Sauvegarde des informations de tunnel
- Timeout de 5 secondes pour les tests de connexion

### Différences

- **Ryvie-Desktop**: Récupère depuis `http://ryvie.local:3002/api/settings/ryvie-domains`
- **rPictures Mobile**: Récupère depuis `http://ryvie.local:3000/api/server/ryvie-tunnel-info`
- **rPictures Mobile**: Possibilité de configuration manuelle en plus de l'automatique

## Utilisation

### Scénario 1: À la maison (réseau local)

1. L'utilisateur ouvre l'application
2. L'application détecte automatiquement `ryvie.local:3000`
3. Connexion rapide et directe

### Scénario 2: En déplacement (réseau externe)

1. L'utilisateur ouvre l'application
2. `ryvie.local:3000` n'est pas accessible
3. L'application utilise l'URL publique configurée (tunnel)
4. Connexion via le tunnel

### Scénario 3: Première utilisation

1. L'utilisateur se connecte pour la première fois en local
2. L'application récupère automatiquement les informations du tunnel
3. Active "Automatic URL switching" dans les paramètres
4. L'application gère automatiquement la sélection d'URL (local/public)

## Dépannage

### L'application ne se connecte pas

1. Vérifiez que "Automatic URL switching" est activé
2. Vérifiez que les informations du tunnel sont correctement configurées
3. Testez manuellement les URLs:
   - `http://ryvie.local:3000` (sur le réseau local)
   - Votre URL publique (depuis n'importe où)

### Logs de débogage

Les logs sont disponibles dans la console avec le tag `SmartUrlSelectorService`:

- `🔍 Test connexion LOCALE: ...`
- `✅ Connexion LOCALE réussie`
- `❌ Connexion locale échouée`
- `✅ Connexion PUBLIQUE réussie`
- etc.

## Évolutions Futures

1. ✅ **Auto-découverte**: Récupérer automatiquement les informations du tunnel depuis le serveur Ryvie (IMPLÉMENTÉ)
2. **Détection de réseau**: Utiliser la détection de réseau pour optimiser la sélection
3. **Cache de connectivité**: Mémoriser quelle URL a fonctionné récemment pour accélérer la connexion
4. **Notifications**: Informer l'utilisateur du mode de connexion utilisé (local/public)
5. **Synchronisation serveur**: Créer un fichier `/etc/ryvie/config.json` sur le serveur pour stocker les informations
