import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;
  String? _salaIdActual;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connect({
    required String baseUrl,
    required String salaId,
    required void Function(dynamic data) onUserJoined,
  }) async {
    if (isConnected && _salaIdActual == salaId) return;

    await disconnect();

    _salaIdActual = salaId;

    _connection = HubConnectionBuilder()
        .withUrl('$baseUrl/salaHub')
        .withAutomaticReconnect()
        .build();

    _connection!.on('UsuarioEntrado', (args) {
      if (args == null || args.isEmpty) return;
      onUserJoined(args[0]);
    });

    await _connection!.start();

    await _connection!.invoke(
      'JoinSala',
      args: [salaId],
    );
  }

  Future<void> disconnect() async {
    final connection = _connection;
    final salaId = _salaIdActual;

    if (connection != null &&
        connection.state == HubConnectionState.Connected &&
        salaId != null) {
      try {
        await connection.invoke('LeaveSala', args: [salaId]);
      } catch (_) {}
    }

    try {
      await connection?.stop();
    } catch (_) {}

    _connection = null;
    _salaIdActual = null;
  }
}