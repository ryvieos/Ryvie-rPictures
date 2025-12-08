import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

enum ConnectionStatus { connected, disconnected, tunnelUnavailable, noTunnelConfig }

class ConnectionStatusState {
  final ConnectionStatus status;
  final String? errorMessage;
  final String? serverUrl;

  const ConnectionStatusState({required this.status, this.errorMessage, this.serverUrl});

  ConnectionStatusState copyWith({ConnectionStatus? status, String? errorMessage, String? serverUrl}) {
    return ConnectionStatusState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}

class ConnectionStatusNotifier extends StateNotifier<ConnectionStatusState> {
  final _log = Logger('ConnectionStatusNotifier');

  ConnectionStatusNotifier() : super(const ConnectionStatusState(status: ConnectionStatus.disconnected));

  void setConnected(String serverUrl) {
    _log.info('✅ Connexion établie: $serverUrl');
    _log.info('🔄 Changement état vers: connected');
    state = ConnectionStatusState(status: ConnectionStatus.connected, serverUrl: serverUrl);
    _log.info('✅ État changé: ${state.status}');
  }

  void setTunnelUnavailable(String errorMessage) {
    _log.warning('⚠️  Tunnel inaccessible: $errorMessage');
    _log.info('🔄 Changement état vers: tunnelUnavailable');
    state = ConnectionStatusState(status: ConnectionStatus.tunnelUnavailable, errorMessage: errorMessage);
    _log.info('✅ État changé: ${state.status}');
  }

  void setNoTunnelConfig(String errorMessage) {
    _log.warning('⚠️  Pas de configuration tunnel: $errorMessage');
    _log.info('🔄 Changement état vers: noTunnelConfig');
    state = ConnectionStatusState(status: ConnectionStatus.noTunnelConfig, errorMessage: errorMessage);
    _log.info('✅ État changé: ${state.status}');
  }

  void setDisconnected() {
    _log.info('ℹ️  Déconnecté');
    _log.info('🔄 Changement état vers: disconnected');
    state = const ConnectionStatusState(status: ConnectionStatus.disconnected);
    _log.info('✅ État changé: ${state.status}');
  }
}

final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatusState>((ref) {
  return ConnectionStatusNotifier();
});
