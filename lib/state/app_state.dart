import 'package:flutter/material.dart';

import '../models/chat_model.dart';
import '../models/chat_preview_state.dart';
import '../models/message_model.dart';
import '../models/request_model.dart';

import '../services/api_service.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/app_navigator.dart';

class AppState extends ChangeNotifier {
  bool _isHost = false;
  String? _userName;
  String? _roomCode;

  String? _userId;
  String? _salaId;
  HubConnection? _hubConnection;

  DateTime? _birthDate;
  String? _instagram;
  String? _profilePhoto;
  String? _estado;
  List<String> _respuestas = [];
  bool? _sexo;

  List<String> _preguntasRapidas = [];
  bool _cargandoPreguntasRapidas = false;
  String? _errorPreguntasRapidas;

  List<String> get preguntasRapidas => _preguntasRapidas;
  bool get cargandoPreguntasRapidas => _cargandoPreguntasRapidas;
  String? get errorPreguntasRapidas => _errorPreguntasRapidas;

  // ✅ Términos y condiciones
  bool _aceptaTerminos = false;

  bool get aceptaTerminos => _aceptaTerminos;
  bool get aceptaPrivacidad => _aceptaTerminos;
  bool get aceptaBiometria => _aceptaTerminos;

  final List<RequestModel> _sentRequests = [];
  final List<RequestModel> _receivedRequests = [];
  final List<ChatModel> _dynamicChats = [];
  final List<MessageModel> _messages = [];
  bool _loadingChats = false;
  String? _activeChatId;
  bool get loadingChats => _loadingChats;

  List<SalaUsuarioModel> _salaUsuarios = [];
  bool _loadingUsuarios = false;
  String? _loadingError;

  List<SalaUsuarioModel> get salaUsuarios => List.unmodifiable(_salaUsuarios);
  bool get loadingUsuarios => _loadingUsuarios;
  String? get loadingError => _loadingError;

  RequestModel? _activeAcceptedRequest;

  bool get isHost => _isHost;
  String? get userName => _userName;
  bool? get sexo => _sexo;
  String? get roomCode => _roomCode;
  String? get userId => _userId;
  String? get salaId => _salaId;

  DateTime? get birthDate => _birthDate;
  String? get instagram => _instagram;
  String? get profilePhoto => _profilePhoto;
  String? get estado => _estado;
  List<String> get respuestas => List.unmodifiable(_respuestas);

  List<RequestModel> get sentRequests => List.unmodifiable(_sentRequests);
  List<RequestModel> get receivedRequests => List.unmodifiable(_receivedRequests);
  List<ChatModel> get dynamicChats => List.unmodifiable(_dynamicChats);
  List<MessageModel> get messages => List.unmodifiable(_messages);

  RequestModel? get activeAcceptedRequest => _activeAcceptedRequest;

  double? _latitudGuest;
  double? _longitudGuest;
  double? get latitudGuest => _latitudGuest;
  double? get longitudGuest => _longitudGuest;

  int _retosVersion = 0;
  int get retosVersion => _retosVersion;

  RequestModel? get blockingIncomingRequest {
    try {
      return _receivedRequests.firstWhere(
        (request) => request.status == RequestStatus.pending,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    var deviceId = prefs.getString('deviceId');

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = DateTime.now().microsecondsSinceEpoch.toString();
      await prefs.setString('deviceId', deviceId);
    }

    return deviceId;
  }

  Future<void> cargarPreguntasRapidasPorEstado(String estado) async {
    _cargandoPreguntasRapidas = true;
    _errorPreguntasRapidas = null;
    _preguntasRapidas = [];
    notifyListeners();

    try {
      final preguntas = await ApiService.obtenerPreguntasPorEstado(estado);

      if (preguntas.length < 3) {
        throw Exception('El backend debe devolver mínimo 3 preguntas.');
      }

      _preguntasRapidas = preguntas.take(3).toList();
    } catch (e) {
      _errorPreguntasRapidas = e.toString();
    } finally {
      _cargandoPreguntasRapidas = false;
      notifyListeners();
    }
  }

  bool get hasBlockingIncomingRequest => blockingIncomingRequest != null;
  bool get isRespondingToAcceptedRequest => _activeAcceptedRequest != null;

  void setUser({
    required bool isHost,
    required String userName,
    required String roomCode,
    String? userId,
    String? salaId,
  }) {
    _isHost = isHost;
    _userName = userName;
    _roomCode = roomCode;
    _userId = userId ?? _userId;
    _salaId = salaId ?? _salaId;
    notifyListeners();
  }

  void clear() {
    _isHost = false;
    _userName = null;
    _sexo = null;
    _roomCode = null;
    _sentRequests.clear();
    _receivedRequests.clear();
    _dynamicChats.clear();
    _messages.clear();
    _activeAcceptedRequest = null;
    _userId = null;
    _salaId = null;
    _birthDate = null;
    _instagram = null;
    _profilePhoto = null;
    _estado = null;
    _respuestas = [];
    _aceptaTerminos = false;
    _latitudGuest = null;
    _longitudGuest = null;
    notifyListeners();
  }

  Future<void> guardarSesionLocal() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('salaId', _salaId ?? '');
    await prefs.setString('userName', _userName ?? '');
    await prefs.setString('roomCode', _roomCode ?? '');
    await prefs.setBool('isHost', _isHost);
  }

  Future<void> borrarSesionLocal() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('salaId');
    await prefs.remove('userName');
    await prefs.remove('roomCode');
    await prefs.remove('isHost');
  }

  Future<bool> restaurarSesionLocal() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId') ?? '';
    final salaId = prefs.getString('salaId') ?? '';
    final userName = prefs.getString('userName') ?? '';
    final roomCode = prefs.getString('roomCode') ?? '';
    final isHost = prefs.getBool('isHost') ?? false;

    if (userId.isEmpty || salaId.isEmpty) return false;

    try {
      final usuario = await ApiService.getUsuarioPorId(userId);

      if (usuario.baneado) {
        await borrarSesionLocal();
        clear();
        return false;
      }

      await ApiService.getUsuariosSala(salaId);

      _userId = userId;
      _salaId = salaId;
      _userName = userName.isNotEmpty ? userName : usuario.nombre;
      _roomCode = roomCode;
      _isHost = isHost;
      _estado = usuario.estado;
      _birthDate = usuario.fechaNacimiento;
      _profilePhoto = usuario.foto;

      if ((_userId ?? '').isNotEmpty && (_salaId ?? '').isNotEmpty) {
        guardarSesionLocal();
      }

      notifyListeners();

      await cargarSesionCompleta();

      return true;
    } catch (_) {
      await borrarSesionLocal();
      clear();
      return false;
    }
  }

  Future<void> cerrarSesionPorSalaCerrada() async {
    await borrarSesionLocal();
    clear();

    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/',
      (_) => false,
    );
  }

  Future<void> cargarSesionCompleta() async {
    final id = _userId;
    final sala = _salaId;

    if (id == null || id.isEmpty || sala == null || sala.isEmpty) return;

    final usuario = await ApiService.getUsuarioPorId(id);

    if (usuario.baneado) {
      await borrarSesionLocal();
      clear();
      return;
    }

    _userName = usuario.nombre;
    _birthDate = usuario.fechaNacimiento;
    _estado = usuario.estado;
    _profilePhoto = usuario.foto;

    await cargarUsuariosSala();
    await cargarChats();

    final enviadas = await ApiService.getSolicitudesEnviadas(id);
    final recibidas = await ApiService.getSolicitudesRecibidas(id);

    _sentRequests
      ..clear()
      ..addAll(enviadas);

    _receivedRequests
      ..clear()
      ..addAll(recibidas.where((r) => r.status == RequestStatus.pending));

    await iniciarSignalR();

    notifyListeners();
  }

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;

    if (chatId != null) {
      marcarChatComoLeidoLocal(chatId);
    }
  }

  void marcarChatComoLeidoLocal(String chatId) {
    final index = _dynamicChats.indexWhere((chat) => chat.id == chatId);
    if (index == -1) return;

    final oldChat = _dynamicChats[index];

    _dynamicChats[index] = oldChat.copyWith(
      unreadCount: 0,
      previewState: ChatPreviewState.normal,
    );

    notifyListeners();
  }

  Future<void> sendRequest({
    required String targetUserId,
    required String targetUserName,
    required RequestType type,
    required String content,
    required Color statusColor,
  }) async {
    final hasBlockingState = _sentRequests.any(
      (request) =>
          request.targetUserId == targetUserId &&
          (request.status == RequestStatus.pending ||
              request.status == RequestStatus.answered ||
              request.status == RequestStatus.rejected),
    );

    if (hasBlockingState) return;

    final myId = _userId;
    if (myId == null || myId.isEmpty) return;

    final solicitudId = await ApiService.crearSolicitud(
      emisorId: myId,
      receptorId: targetUserId,
      type: type,
      content: content,
    );

    final request = RequestModel(
      id: solicitudId,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      type: type,
      content: content,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _sentRequests.insert(0, request);

    final alreadyInChats = _dynamicChats.any(
      (chat) => chat.otherUserId == targetUserId,
    );
    if (!alreadyInChats) {
      _dynamicChats.insert(
        0,
        ChatModel(
          id: targetUserId,
          otherUserId: targetUserId,
          userName: targetUserName,
          lastMessage:
              '$targetUserName está en una misión ahora mismo ¡intenta con otro!',
          time: _formatNow(),
          unreadCount: 0,
          statusColor: statusColor,
          previewState: ChatPreviewState.missionBusy,
        ),
      );
    }

    notifyListeners();

    debugPrint('ENVIANDO SOLICITUD SIGNALR');
    debugPrint('solicitudId: $solicitudId');
    debugPrint('fromUserId: $_userId');
    debugPrint('targetUserId: $targetUserId');
    debugPrint('hubState: ${_hubConnection?.state}');

    if (_hubConnection?.state != HubConnectionState.Connected) {
      await iniciarSignalR();
    }

    await _hubConnection?.invoke(
      'EnviarSolicitud',
      args: [
        solicitudId,
        _userId ?? '',
        _userName ?? '',
        targetUserId,
        _requestTypeToString(type),
        content,
      ],
    );
  }

  RequestType _requestTypeFromString(String value) {
    switch (value) {
      case 'truth':
        return RequestType.truth;
      case 'dare':
        return RequestType.dare;
      case 'messageRequest':
        return RequestType.messageRequest;
      default:
        return RequestType.messageRequest;
    }
  }

  String _requestTypeToString(RequestType type) {
    switch (type) {
      case RequestType.truth:
        return 'truth';
      case RequestType.dare:
        return 'dare';
      case RequestType.messageRequest:
        return 'messageRequest';
    }
  }

  void setRegisterData({
    required String userName,
    required DateTime birthDate,
    required String profilePhoto,
    required bool sexo,
    required bool aceptaTerminos,
    String? instagram,
  }) {
    _userName = userName;
    _birthDate = birthDate;
    _profilePhoto = profilePhoto;
    _sexo = sexo;
    _instagram = instagram;
    _aceptaTerminos = aceptaTerminos;
    notifyListeners();
  }

  void setStatusData(String estado) {
    _estado = estado;
    notifyListeners();
  }

  void setQuestionsData(List<String> respuestas) {
    _respuestas = respuestas;
    notifyListeners();
  }

  RequestModel? getPendingRequestForUser(String userId) {
    try {
      return _sentRequests.firstWhere(
        (request) =>
            request.targetUserId == userId &&
            request.status == RequestStatus.pending,
      );
    } catch (_) {
      return null;
    }
  }

  RequestModel? getInteractionRequestForUser(String userId) {
    try {
      return _sentRequests.firstWhere(
        (request) => request.targetUserId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  bool shouldHideUserFromHome(String userId) {
    final hasOutgoingState = _sentRequests.any(
      (request) =>
          request.targetUserId == userId &&
          (request.status == RequestStatus.pending ||
              request.status == RequestStatus.answered ||
              request.status == RequestStatus.rejected),
    );

    final hasChat = _dynamicChats.any(
      (chat) => chat.otherUserId == userId,
    );

    return hasOutgoingState || hasChat;
  }

  void addIncomingRequest({
    required String solicitudId,
    required String fromUserId,
    required String fromUserName,
    required RequestType type,
    required String content,
  }) {
    final alreadyExists = _receivedRequests.any(
      (request) =>
          request.id == solicitudId ||
          (request.targetUserId == fromUserId &&
              request.status == RequestStatus.pending),
    );

    if (alreadyExists) return;

    final request = RequestModel(
      id: solicitudId,
      targetUserId: fromUserId,
      targetUserName: fromUserName,
      type: type,
      content: content,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _receivedRequests.insert(0, request);
    notifyListeners();
  }

  void rejectIncomingRequest(String requestId) {
    final index = _receivedRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _receivedRequests[index];

    ApiService.rechazarVerdadReto(request.id);

    _receivedRequests.removeAt(index);

    final existingIndex = _sentRequests.indexWhere(
      (r) => r.targetUserId == request.targetUserId,
    );

    final rejectedRequest = request.copyWith(status: RequestStatus.rejected);

    if (existingIndex == -1) {
      _sentRequests.insert(0, rejectedRequest);
    } else {
      _sentRequests[existingIndex] = rejectedRequest;
    }

    notifyListeners();
  }

  void reopenRejectedIncomingRequest(String userId) {
    final index = _sentRequests.indexWhere(
      (request) =>
          request.targetUserId == userId &&
          request.status == RequestStatus.rejected,
    );

    if (index == -1) return;

    final request = _sentRequests[index].copyWith(
      status: RequestStatus.pending,
    );

    _sentRequests.removeAt(index);
    _receivedRequests.insert(0, request);

    notifyListeners();
  }

  Future<void> acceptIncomingRequest(String requestId) async {
    final index = _receivedRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _receivedRequests[index].copyWith(
      status: RequestStatus.accepted,
    );

    _receivedRequests.removeAt(index);
    _activeAcceptedRequest = request;
    notifyListeners();

    final myId = _userId;
    if (myId == null || myId.isEmpty) return;

    await ApiService.aceptarVerdadReto(request.id);

    _sentRequests.removeWhere((r) => r.targetUserId == request.targetUserId);

    await cargarChats();
  }

  void restoreAcceptedRequestToPending() {
    final request = _activeAcceptedRequest;
    if (request == null) return;

    _receivedRequests.insert(
      0,
      request.copyWith(status: RequestStatus.pending),
    );
    _activeAcceptedRequest = null;
    notifyListeners();
  }

  Future<void> finishAcceptedRequestResponse(String responseText) async {
    final request = _activeAcceptedRequest;
    if (request == null) return;

    final myId = _userId;
    if (myId == null || myId.isEmpty) return;

    final chatId = await ApiService.crearOObtenerChat(
      usuarioAId: myId,
      usuarioBId: request.targetUserId,
    );

    await sendChatMessage(
      chatId: chatId,
      targetUserId: request.targetUserId,
      text: responseText,
      isMine: true,
    );

    _activeAcceptedRequest = null;
    notifyListeners();
  }

  void registerIncomingAnswer({
    required String chatId,
    required String answerText,
  }) {
    final chatIndex = _dynamicChats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex == -1) return;

    final oldChat = _dynamicChats[chatIndex];

    _messages.add(
      MessageModel(
        id: '${chatId}_incoming_answer_${DateTime.now().microsecondsSinceEpoch}',
        chatId: chatId,
        text: answerText,
        isMine: false,
        time: _formatNow(),
      ),
    );

    _dynamicChats.removeAt(chatIndex);
    _dynamicChats.insert(
      0,
      oldChat.copyWith(
        lastMessage: answerText,
        time: _formatNow(),
        unreadCount: oldChat.unreadCount + 1,
        previewState: ChatPreviewState.answeredRequest,
      ),
    );

    notifyListeners();
  }

  void markAnsweredRequestAsSeen(String chatId) {
    final chatIndex = _dynamicChats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final oldChat = _dynamicChats[chatIndex];
      _dynamicChats[chatIndex] = oldChat.copyWith(
        previewState: ChatPreviewState.normal,
        unreadCount: 0,
      );
    }

    notifyListeners();
  }

  void rejectOutgoingRequestSilently(String targetUserId) {
    final sentIndex = _sentRequests.indexWhere(
      (request) =>
          request.targetUserId == targetUserId &&
          (request.status == RequestStatus.pending ||
              request.status == RequestStatus.answered),
    );

    if (sentIndex != -1) {
      _sentRequests[sentIndex] = _sentRequests[sentIndex].copyWith(
        status: RequestStatus.rejected,
      );
    }

    final chatIndex = _dynamicChats.indexWhere((chat) => chat.id == targetUserId);
    if (chatIndex != -1) {
      final oldChat = _dynamicChats[chatIndex];
      _dynamicChats[chatIndex] = oldChat.copyWith(
        lastMessage:
            '${oldChat.userName} está en una misión ahora mismo ¡intenta con otro!',
        previewState: ChatPreviewState.missionBusy,
        unreadCount: 0,
      );
    }

    notifyListeners();
  }

  List<MessageModel> getMessagesForChat(String chatId) {
    return _messages.where((message) => message.chatId == chatId).toList();
  }

  Future<void> cargarMensajesChat(String chatId) async {
    final id = _userId;
    if (id == null || id.isEmpty) return;

    final mensajes = await ApiService.getMensajesChat(
      chatId: chatId,
      usuarioId: id,
    );

    _messages.removeWhere((m) => m.chatId == chatId);
    _messages.addAll(mensajes);

    notifyListeners();
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String targetUserId,
    required String text,
    required bool isMine,
  }) async {
    final myId = _userId;
    if (myId == null || myId.isEmpty) return;

    final tempTime = _formatNow();

    final tempMessage = MessageModel(
      id: '${chatId}_local_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      text: text,
      isMine: true,
      time: tempTime,
    );

    _messages.add(tempMessage);

    final chatIndex = _dynamicChats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final oldChat = _dynamicChats[chatIndex];

      _dynamicChats.removeAt(chatIndex);
      _dynamicChats.insert(
        0,
        oldChat.copyWith(
          lastMessage: text,
          time: tempTime,
          unreadCount: 0,
          previewState: ChatPreviewState.normal,
        ),
      );
    }

    notifyListeners();

    try {
      await ApiService.enviarMensajeChat(
        chatId: chatId,
        emisorId: myId,
        receptorId: targetUserId,
        contenido: text,
      );

      await _hubConnection?.invoke(
        'EnviarMensajeChat',
        args: [
          chatId,
          myId,
          targetUserId,
          text,
          tempTime,
        ],
      );
    } catch (e) {
      debugPrint('Error enviando mensaje: $e');
    }
  }

  List<ChatModel> buildChatsList(List<ChatModel> mockChats) {
    return List.unmodifiable(_dynamicChats);
  }

  Future<void> cargarChats() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;

    _loadingChats = true;
    notifyListeners();

    try {
      final backendChats = await ApiService.getChatsUsuario(id);

      final localMissionChats = _dynamicChats.where((chat) {
        final hasBackendChat = backendChats.any(
          (backendChat) => backendChat.otherUserId == chat.otherUserId,
        );

        return !hasBackendChat &&
            (chat.previewState == ChatPreviewState.missionBusy ||
                isPendingOutgoingChat(chat.otherUserId));
      }).toList();

      _dynamicChats
        ..clear()
        ..addAll(localMissionChats)
        ..addAll(backendChats);
    } finally {
      _loadingChats = false;
      notifyListeners();
    }
  }

  bool isPendingOutgoingChat(String chatId) {
    return _sentRequests.any(
      (request) =>
          request.targetUserId == chatId &&
          request.status == RequestStatus.pending,
    );
  }

  Color _statusColorFromType(RequestType type) {
    switch (type) {
      case RequestType.truth:
        return const Color(0xFF22C55E);
      case RequestType.dare:
        return const Color(0xFFEF4444);
      case RequestType.messageRequest:
        return const Color(0xFF52A9FF);
    }
  }

  String _formatNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> cargarUsuariosSala() async {
    final id = _salaId;
    if (id == null) return;

    _loadingUsuarios = true;
    _loadingError = null;
    notifyListeners();

    try {
      final usuarios = await ApiService.getUsuariosSala(id);
      _salaUsuarios = usuarios
          .where((u) => u.id != _userId)
          .toList();
    } catch (e) {
      _loadingError = e.toString();
    } finally {
      _loadingUsuarios = false;
      notifyListeners();
    }
  }

  Future<void> banearUsuario(String usuarioId) async {
    await ApiService.banearUsuario(usuarioId);
    await cargarUsuariosSala();
  }

  Future<void> salirDeSala() async {
    final id = _userId;
    if (id != null) await ApiService.salirDeSala(id);

    await borrarSesionLocal();
    clear();
  }

  Future<void> cerrarSala() async {
    final id = _salaId;
    if (id != null) await ApiService.cerrarSala(id);

    await borrarSesionLocal();
    clear();
  }

  List<String> get premios => [];

  int get matchCount =>
      _dynamicChats.where((c) => c.previewState == ChatPreviewState.normal).length;

  int get baneadosCount => _salaUsuarios.where((u) => u.baneado).length;

  String? get nivelId => _estado != null ? calcularNivel() : null;

  String calcularNivel() {
    return 'Ninguno';
  }

  Future<void> iniciarSignalR() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    final currentUserId = _userId;
    final currentSalaId = _salaId;

    if (currentUserId == null || currentUserId.isEmpty) return;
    if (currentSalaId == null || currentSalaId.isEmpty) return;

    final hubUrl = '${ApiService.baseUrl}/hubs/sala';

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('SolicitudRecibida', (arguments) {
      debugPrint('SOLICITUD RECIBIDA SIGNALR: $arguments');
      if (arguments == null || arguments.isEmpty) return;

      final data = arguments.first as Map<Object?, Object?>;

      final solicitudId = data['solicitudId']?.toString() ?? '';
      final fromUserId = data['fromUserId']?.toString() ?? '';
      final fromUserName = data['fromUserName']?.toString() ?? '';
      final typeText = data['type']?.toString() ?? '';
      final content = data['content']?.toString() ?? '';

      final type = _requestTypeFromString(typeText);

      if (solicitudId.isEmpty || fromUserId.isEmpty || fromUserName.isEmpty || content.isEmpty) return;

      addIncomingRequest(
        solicitudId: solicitudId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        type: type,
        content: content,
      );
    });

    _hubConnection!.on('UsuarioEntrado', (arguments) {
      cargarUsuariosSala();
    });

    _hubConnection!.on('MensajeChatRecibido', (arguments) {
      if (arguments == null || arguments.isEmpty) return;

      final data = arguments.first as Map<Object?, Object?>;

      final chatId = data['chatId']?.toString() ?? '';
      final fromUserId = data['fromUserId']?.toString() ?? '';
      final content = data['content']?.toString() ?? '';
      final time = data['time']?.toString() ?? _formatNow();

      if (chatId.isEmpty || fromUserId.isEmpty || content.isEmpty) return;

      // Evita duplicar tus propios mensajes
      if (fromUserId == _userId) return;

      final message = MessageModel(
        id: '${chatId}_${DateTime.now().microsecondsSinceEpoch}',
        chatId: chatId,
        text: content,
        isMine: false,
        time: time,
      );

      _messages.add(message);

      final chatIndex = _dynamicChats.indexWhere((chat) => chat.id == chatId);

      if (chatIndex != -1) {
        final oldChat = _dynamicChats[chatIndex];

        _dynamicChats.removeAt(chatIndex);
        _dynamicChats.insert(
          0,
          oldChat.copyWith(
            lastMessage: content,
            time: time,
            unreadCount: _activeChatId == chatId ? 0 : oldChat.unreadCount + 1,
            previewState: ChatPreviewState.normal,
          ),
        );
      } else {
        cargarChats();
      }

      notifyListeners();
    });

    _hubConnection!.on('SolicitudAceptada', (arguments) async {
      debugPrint('SOLICITUD ACEPTADA SIGNALR: $arguments');

      if (arguments == null || arguments.isEmpty) return;

      final data = arguments.first as Map<Object?, Object?>;

      final solicitudId = data['solicitudId']?.toString() ?? '';

      _sentRequests.removeWhere((request) => request.id == solicitudId);

      await cargarChats();

      notifyListeners();
    });

    _hubConnection!.on('SolicitudRechazada', (arguments) {
      debugPrint('SOLICITUD RECHAZADA SIGNALR: $arguments');

      if (arguments == null || arguments.isEmpty) return;

      final data = arguments.first as Map<Object?, Object?>;

      final solicitudId = data['solicitudId']?.toString() ?? '';
      final receptorId = data['receptorId']?.toString() ?? '';
      final mensaje = data['mensaje']?.toString() ??
          'Está en otra misión ahora mismo ¡intenta con otro!';

      if (solicitudId.isEmpty || receptorId.isEmpty) return;

      final sentIndex = _sentRequests.indexWhere((r) => r.id == solicitudId);

      if (sentIndex != -1) {
        _sentRequests[sentIndex] = _sentRequests[sentIndex].copyWith(
          status: RequestStatus.rejected,
        );
      }

      final chatIndex = _dynamicChats.indexWhere(
        (chat) => chat.otherUserId == receptorId || chat.id == receptorId,
      );

      if (chatIndex != -1) {
        final oldChat = _dynamicChats[chatIndex];

        _dynamicChats[chatIndex] = oldChat.copyWith(
          lastMessage: mensaje,
          previewState: ChatPreviewState.missionBusy,
          unreadCount: 0,
          time: _formatNow(),
        );
      }

      notifyListeners();
    });

    _hubConnection!.on('RetosActualizados', (arguments) {
      debugPrint('RETOS ACTUALIZADOS SIGNALR');
      _retosVersion++;
      notifyListeners();
    });

    _hubConnection!.on('SalaCerrada', (arguments) async {
      debugPrint('SALA CERRADA SIGNALR');
      await cerrarSesionPorSalaCerrada();
    });

    _hubConnection!.on('UsuarioBaneado', (arguments) async {
      debugPrint('USUARIO BANEADO SIGNALR');

      if (arguments == null || arguments.isEmpty) return;

      final data = arguments.first as Map<Object?, Object?>;
      final bannedUserId = data['usuarioId']?.toString() ?? '';

      if (bannedUserId == _userId) {
        await borrarSesionLocal();
        clear();

        appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (_) => false,
        );
      }
    });

    _hubConnection!.on('UsuarioSalio', (arguments) {
      cargarUsuariosSala();
      cargarChats();
    });

    await _hubConnection!.start();

    await _hubConnection!.invoke(
      'JoinSala',
      args: [currentSalaId],
    );

    await _hubConnection!.invoke(
      'JoinUsuario',
      args: [currentUserId],
    );
    
  }

  void setGuestJoinData({
    required String roomCode,
    required double latitud,
    required double longitud,
    required double accuracy,
  }) {
    _roomCode = roomCode;
    _latitudGuest = latitud;
    _longitudGuest = longitud;
    notifyListeners();
  }

  Future<void> registrarInvitadoEnBackend() async {
    
    try {
      final deviceId = await _getOrCreateDeviceId();
      final response = await ApiService.registrarInvitado(
        nombre: _userName ?? '',
        sexo: _sexo ?? true,
        fechaNacimiento: _birthDate ?? DateTime.now(),
        foto: _profilePhoto ?? '',
        instagram: _instagram,
        estado: _estado ?? 'verde',
        respuestas: _respuestas,
        codigoSala: _roomCode ?? '',
        latitud: _latitudGuest ?? 0.0,
        longitud: _longitudGuest ?? 0.0,
        accuracy: 0.0,

        // ✅ Enviamos al backend lo que exige el RegistroService
        aceptaTerminos: _aceptaTerminos,
        aceptaPrivacidad: _aceptaTerminos,
        aceptaBiometria: _aceptaTerminos,
        deviceId: deviceId,
      );

      _userId = response.usuarioId;
      _salaId = response.salaId;
      _userName = response.nombreUsuario;
      notifyListeners();
      await guardarSesionLocal();

    } catch (e) {
      rethrow;
    }
  }
}