import 'dart:async';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/providers/connection_status.provider.dart';
import 'package:logging/logging.dart';

final serverHealthCheckProvider = Provider<ServerHealthCheckNotifier>((ref) {
  return ServerHealthCheckNotifier(ref);
});

class ServerHealthCheckNotifier {
  final Ref _ref;
  final _log = Logger('ServerHealthCheck');
  bool _isChecking = false;
  Timer? _retryTimer;
  bool _errorAlreadyShown = false;

  ServerHealthCheckNotifier(this._ref);

  /// Lance un health check unique (au démarrage de l'app)
  void performHealthCheck() {
    _log.info('🏥 Lancement du health check au démarrage');
    checkServerHealth();
  }

  /// Démarre les tentatives de reconnexion périodiques (toutes les 5 secondes)
  void startRetryLoop() {
    if (_retryTimer != null && _retryTimer!.isActive) {
      _log.info('⏭️  Retry loop déjà actif');
      return;
    }

    _log.info('🔄 Démarrage du retry loop (toutes les 5 secondes)');
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) => checkServerHealth());
  }

  /// Arrête les tentatives de reconnexion
  void stopRetryLoop() {
    if (_retryTimer != null) {
      _log.info('🛑 Arrêt du retry loop');
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  /// Vérifie la santé du serveur avec un timeout de 5 secondes
  Future<void> checkServerHealth() async {
    if (_isChecking) {
      _log.info('⏭️  Health check déjà en cours, skip');
      return;
    }

    _isChecking = true;
    _log.info('🔍 Health check du serveur...');

    try {
      final serverUrl = Store.tryGet(StoreKey.serverUrl);

      if (serverUrl == null || serverUrl.isEmpty) {
        _log.warning('⚠️  Pas d\'URL serveur configurée');
        _isChecking = false;
        return;
      }

      _log.info('🌐 Test de connexion à: $serverUrl');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final uri = Uri.parse(serverUrl);
      final request = await client
          .getUrl(uri)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              _log.severe('❌ Timeout lors du health check (5 secondes)');
              throw TimeoutException('Health check timeout');
            },
          );

      final response = await request.close().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log.severe('❌ Timeout lors de la réponse du health check');
          throw TimeoutException('Health check response timeout');
        },
      );

      client.close();

      _log.info('✅ Serveur accessible (HTTP ${response.statusCode})');

      // Arrêter le retry loop si actif
      stopRetryLoop();

      // Réinitialiser le flag d'erreur pour la prochaine fois
      _errorAlreadyShown = false;

      // Marquer comme connecté
      _ref.read(connectionStatusProvider.notifier).setConnected(serverUrl);

      // Actualiser la page principale (invalider les providers pour forcer le refresh)
      _log.info('🔄 Actualisation de la page principale après reconnexion');
      _ref.invalidate(connectionStatusProvider);
    } on TimeoutException catch (e) {
      _log.severe('❌ Timeout du health check', e);

      // N'afficher le message d'erreur qu'une seule fois
      if (!_errorAlreadyShown) {
        _log.info('🔴 Affichage du message d\'erreur (première fois)');
        _ref
            .read(connectionStatusProvider.notifier)
            .setTunnelUnavailable(
              'Impossible de se connecter à votre Ryvie.\n\n'
              'Vérifiez que :\n'
              '• Votre téléphone a accès à Internet\n'
              '• L\'application Ryvie Connect est ouverte sur votre téléphone principal\n\n'
              'Si vous êtes chez vous, reconnectez-vous au WiFi.',
            );
        _errorAlreadyShown = true;
      } else {
        _log.info('⏭️  Erreur détectée mais message déjà affiché, skip');
      }

      // Démarrer le retry loop pour tenter de se reconnecter
      startRetryLoop();
    } on SocketException catch (e) {
      _log.severe('❌ Erreur réseau lors du health check', e);

      // N'afficher le message d'erreur qu'une seule fois
      if (!_errorAlreadyShown) {
        _log.info('🔴 Affichage du message d\'erreur (première fois)');
        _ref
            .read(connectionStatusProvider.notifier)
            .setTunnelUnavailable(
              'Impossible de se connecter à votre Ryvie.\n\n'
              'Vérifiez que :\n'
              '• Votre téléphone a accès à Internet\n'
              '• L\'application Ryvie Connect est ouverte sur votre téléphone principal\n\n'
              'Si vous êtes chez vous, reconnectez-vous au WiFi.',
            );
        _errorAlreadyShown = true;
      } else {
        _log.info('⏭️  Erreur détectée mais message déjà affiché, skip');
      }

      // Démarrer le retry loop pour tenter de se reconnecter
      startRetryLoop();
    } catch (e, stackTrace) {
      _log.severe('❌ Erreur inattendue lors du health check', e, stackTrace);

      // N'afficher le message d'erreur qu'une seule fois
      if (!_errorAlreadyShown) {
        _log.info('🔴 Affichage du message d\'erreur (première fois)');
        _ref
            .read(connectionStatusProvider.notifier)
            .setTunnelUnavailable(
              'Impossible de se connecter à votre Ryvie.\n\n'
              'Vérifiez que :\n'
              '• Votre téléphone a accès à Internet\n'
              '• L\'application Ryvie Connect est ouverte sur votre téléphone principal\n\n'
              'Si vous êtes chez vous, reconnectez-vous au WiFi.',
            );
        _errorAlreadyShown = true;
      } else {
        _log.info('⏭️  Erreur détectée mais message déjà affiché, skip');
      }

      // Démarrer le retry loop pour tenter de se reconnecter
      startRetryLoop();
    } finally {
      _isChecking = false;
    }
  }
}
