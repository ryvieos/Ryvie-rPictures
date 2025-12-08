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

  ServerHealthCheckNotifier(this._ref);

  /// Lance un health check unique (au démarrage de l'app)
  void performHealthCheck() {
    _log.info('🏥 Lancement du health check au démarrage');
    checkServerHealth();
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

      // Marquer comme connecté
      _ref.read(connectionStatusProvider.notifier).setConnected(serverUrl);
    } on TimeoutException catch (e) {
      _log.severe('❌ Timeout du health check', e);
      _ref
          .read(connectionStatusProvider.notifier)
          .setTunnelUnavailable(
            'Impossible de se connecter à votre Ryvie.\n\n'
            'Vérifiez que :\n'
            '• Votre téléphone a accès à Internet\n'
            '• L\'application Ryvie Connect est ouverte sur votre téléphone principal\n\n'
            'Si vous êtes chez vous, reconnectez-vous au WiFi.',
          );
    } on SocketException catch (e) {
      _log.severe('❌ Erreur réseau lors du health check', e);
      _ref
          .read(connectionStatusProvider.notifier)
          .setTunnelUnavailable(
            'Impossible de se connecter à votre Ryvie.\n\n'
            'Vérifiez que :\n'
            '• Votre téléphone a accès à Internet\n'
            '• L\'application Ryvie Connect est ouverte sur votre téléphone principal\n\n'
            'Si vous êtes chez vous, reconnectez-vous au WiFi.',
          );
    } catch (e, stackTrace) {
      _log.severe('❌ Erreur inattendue lors du health check', e, stackTrace);
      _ref
          .read(connectionStatusProvider.notifier)
          .setTunnelUnavailable(
            'Impossible de se connecter à votre Ryvie.\n\n'
            'Vérifiez que :\n'
            '• Votre téléphone a accès à Internet\n'
            '• L\'application Ryvie Connect est ouverte sur votre téléphone principal\n\n'
            'Si vous êtes chez vous, reconnectez-vous au WiFi.',
          );
    } finally {
      _isChecking = false;
    }
  }
}
