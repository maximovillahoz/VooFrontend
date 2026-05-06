import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/chat_preview_state.dart';
import '../models/request_model.dart';
import '../models/reto_model.dart';


class ApiService {
  static String get baseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');

  if (envUrl.isNotEmpty) return envUrl;

  return 'https://voobackend-production.up.railway.app';
}

  

  static Uri _uri(String path) {
    return Uri.parse('$baseUrl$path');
  }

  static Future<List<RequestModel>> getSolicitudesEnviadas(String userId) async {
    final response = await http.get(_uri('/Solicitud/enviadas/$userId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener solicitudes enviadas');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) {
      final map = json as Map<String, dynamic>;

      return RequestModel(
        id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
        targetUserId: map['receptorId']?.toString() ?? '',
        targetUserName: map['receptorNombre']?.toString() ?? 'Usuario',
        type: _requestTypeFromApi(map['tipo']?.toString()),
        content: map['contenido']?.toString() ?? '',
        status: _requestStatusFromApi(map['estado']?.toString()),
        createdAt: DateTime.tryParse(map['fechaCreacion']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  static Future<List<RequestModel>> getSolicitudesRecibidas(String userId) async {
    final response = await http.get(_uri('/Solicitud/recibidas/$userId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener solicitudes recibidas');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) {
      final map = json as Map<String, dynamic>;

      return RequestModel(
        id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
        targetUserId: map['emisorId']?.toString() ?? '',
        targetUserName: map['emisorNombre']?.toString() ?? 'Usuario',
        type: _requestTypeFromApi(map['tipo']?.toString()),
        content: map['contenido']?.toString() ?? '',
        status: _requestStatusFromApi(map['estado']?.toString()),
        createdAt: DateTime.tryParse(map['fechaCreacion']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  static RequestType _requestTypeFromApi(String? value) {
    switch (value) {
      case 'truth':
        return RequestType.truth;
      case 'dare':
        return RequestType.dare;
      default:
        return RequestType.messageRequest;
    }
  }

  static RequestStatus _requestStatusFromApi(String? value) {
    switch (value) {
      case 'aceptada':
      case 'accepted':
        return RequestStatus.accepted;
      case 'rechazada':
      case 'rejected':
        return RequestStatus.rejected;
      case 'answered':
      case 'respondida':
        return RequestStatus.answered;
      default:
        return RequestStatus.pending;
    }
  }

  static Future<VerdadRetoRandom> getVerdadRetoRandom() async {
    final response = await http.get(_uri('/VerdadReto/obtener'));

    debugPrint('GET: ${_uri('/VerdadReto/obtener')}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener verdad o reto');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return VerdadRetoRandom.fromJson(data);
  }


  static Future<String> crearSolicitud({
    required String emisorId,
    required String receptorId,
    required RequestType type,
    required String content,
  }) async {
    final response = await http.post(
      _uri('/Solicitud'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emisorId': emisorId,
        'receptorId': receptorId,
        'tipo': type == RequestType.truth
            ? 'truth'
            : type == RequestType.dare
                ? 'dare'
                : 'messageRequest',
        'contenido': content,
        'estado': 'pendiente',
        'aceptado': null,
      }),
    );

    debugPrint('POST: ${_uri('/Solicitud')}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al crear solicitud');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final solicitud = data['solicitud'] as Map<String, dynamic>?;
    final id = data['solicitudId']?.toString() ??
      data['SolicitudId']?.toString() ??
      data['id']?.toString() ??
      data['Id']?.toString() ??
      data['_id']?.toString() ??
      solicitud?['solicitudId']?.toString() ??
      solicitud?['SolicitudId']?.toString() ??
      solicitud?['id']?.toString() ??
      solicitud?['Id']?.toString() ??
      solicitud?['_id']?.toString() ??
      '';

    if (id.isEmpty) {
      throw Exception('La solicitud se creó, pero el backend no devolvió el ID');
    }

    return id;
  }



  static Future<Map<String, dynamic>> aceptarVerdadReto(String solicitudId) async {
    final response = await http.post(
      _uri('/VerdadReto/aceptar/$solicitudId'),
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('POST: ${_uri('/VerdadReto/aceptar/$solicitudId')}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    final data = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['mensaje'] ?? 'Error al aceptar verdad/reto');
    }

    return data;
  }

  static Future<void> rechazarVerdadReto(String solicitudId) async {
    final response = await http.post(
      _uri('/VerdadReto/rechazar/$solicitudId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al rechazar verdad/reto');
    }
  }

  static Future<RegistroHostResponse> registrarHost({
    required String nombre,
    required bool sexo,
    required DateTime fechaNacimiento,
    required String foto,
    required String? instagram,
    required String estado,
    required List<String> respuestas,
    required String nombreSala,
    required String contexto,
    required int aforo,
    required String direccion,
    required int codigoPostal,
    required double latitudSala,
    required double longitudSala,
    required String premioMayor,
    required List<String> premiosFlash,
    required bool aceptaTerminos,
    required bool aceptaPrivacidad,
    required bool aceptaBiometria,
  }) async {
    final uri = _uri('/Registro/host');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'sexo': sexo,
        'fechaNacimiento': fechaNacimiento.toUtc().toIso8601String(),
        'foto': foto,
        'ig': instagram,
        'estado': estado,
        'respuestas': respuestas,
        'nombreSala': nombreSala,
        'contexto': contexto,
        'aforo': aforo,
        'direccion': direccion,
        'codigoPostal': codigoPostal,
        'latitudSala': latitudSala,
        'longitudSala': longitudSala,
        'premioMayor': premioMayor,
        'premiosFlash': premiosFlash,
        'aceptaTerminos': aceptaTerminos,
        'aceptaPrivacidad': aceptaPrivacidad,
        'aceptaBiometria': aceptaBiometria,
      }),
    );

    debugPrint('POST: $uri');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['mensaje'] ?? 'Error al registrar host');
    }

    return RegistroHostResponse.fromJson(data);
  }

  static Future<RegistroInvitadoResponse> registrarInvitado({
  required String nombre,
  required bool sexo,
  required DateTime fechaNacimiento,
  required String foto,
  required String? instagram,
  required String estado,
  required List<String> respuestas,
  required String codigoSala,
  required double latitud,
  required double longitud,
  required double accuracy,
  bool verificado = true,
  required bool aceptaTerminos,
  required bool aceptaPrivacidad,
  required bool aceptaBiometria,
  required String deviceId,
}) async {
  final uri = _uri('/Registro/invitado');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'nombre': nombre,
      'sexo': sexo,
      'fechaNacimiento': fechaNacimiento.toUtc().toIso8601String(),
      'foto': foto,
      'ig': instagram,
      'estado': estado,
      'respuestas': respuestas,
      'verificado': verificado,
      'codigoSala': codigoSala,
      'latitud': latitud,
      'longitud': longitud,
      'accuracy': accuracy,
      'aceptaTerminos': aceptaTerminos,
      'aceptaPrivacidad': aceptaPrivacidad,
      'aceptaBiometria': aceptaBiometria,
      'deviceId': deviceId,
    }),
  );

  debugPrint('POST: $uri');
  debugPrint('STATUS: ${response.statusCode}');
  debugPrint('BODY LENGTH: ${response.body.length}');

  final Map<String, dynamic> data =
      response.body.isNotEmpty ? jsonDecode(response.body) : {};

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(data['mensaje'] ?? 'Error al registrar invitado');
  }

  return RegistroInvitadoResponse.fromJson(data);
}

  static Future<List<SalaUsuarioModel>> getUsuariosSala(String salaId) async {
    final response = await http.get(_uri('/Usuario/sala/$salaId'));

    print('GET: ${_uri('/Usuario/sala/$salaId')}');
    print('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener usuarios de la sala');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => SalaUsuarioModel.fromJson(json)).toList();
  }

  static Future<SalaUsuarioModel> getUsuarioPorId(String usuarioId) async {
    final response = await http.get(_uri('/Usuario/$usuarioId'));

    debugPrint('GET: ${_uri('/Usuario/$usuarioId')}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener usuario');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return SalaUsuarioModel.fromJson(data);
  }

  static Future<void> banearUsuario(String usuarioId) async {
    final response = await http.patch(
      _uri('/Usuario/$usuarioId/banear'),
      headers: {'Content-Type': 'application/json'},
    );

    print('PATCH: ${_uri('/Usuario/$usuarioId/banear')}');
    print('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al banear usuario');
    }
  }

  static Future<void> salirDeSala(String usuarioId) async {
    final response = await http.patch(
      _uri('/Usuario/$usuarioId/salir'),
      headers: {'Content-Type': 'application/json'},
    );

    print('PATCH: ${_uri('/Usuario/$usuarioId/salir')}');
    print('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al salir de sala');
    }
  }

  static Future<void> cerrarSala(String salaId) async {
    final response = await http.patch(
      _uri('/Sala/$salaId/cerrar'),
      headers: {'Content-Type': 'application/json'},
    );

    print('PATCH: ${_uri('/Sala/$salaId/cerrar')}');
    print('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al cerrar sala');
    }
  }

  

  static Future<String> crearOObtenerChat({
    required String usuarioAId,
    required String usuarioBId,
  }) async {
    final response = await http.post(
      _uri('/Chat/crear-o-obtener'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioAId': usuarioAId,
        'usuarioBId': usuarioBId,
      }),
    );

    debugPrint('POST: ${_uri('/Chat/crear-o-obtener')}');
    debugPrint('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al crear u obtener chat');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['id']?.toString() ?? data['Id']?.toString() ?? '';
  }

  static Future<List<ChatModel>> getChatsUsuario(String usuarioId) async {
    final response = await http.get(_uri('/Chat/usuario/$usuarioId'));

    debugPrint('GET: ${_uri('/Chat/usuario/$usuarioId')}');
    debugPrint('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener chats');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) {
      final map = json as Map<String, dynamic>;

      final ultimoMensaje = map['ultimoMensaje']?.toString().trim() ?? '';

      final estado = map['otroUsuarioEstado']?.toString() ?? 'soltero';

      return ChatModel(
        id: map['chatId']?.toString() ?? '',
        otherUserId: map['otroUsuarioId']?.toString() ?? '',
        userName: map['otroUsuarioNombre']?.toString() ?? 'Usuario',
        foto: map['otroUsuarioFoto']?.toString(),
        lastMessage: ultimoMensaje.isEmpty
          ? '${map['otroUsuarioNombre']?.toString() ?? 'Usuario'} está en una misión ahora mismo ¡intenta con otro!'
          : ultimoMensaje,
        time: _formatApiDate(map['ultimoMensajeFecha']?.toString()),
        unreadCount: map['mensajesNoLeidos'] as int? ?? 0,
        statusColor: _statusColorFromEstado(estado),
        previewState: ChatPreviewState.normal,
      );
    }).whereType<ChatModel>().toList();
  }

  static Future<List<MessageModel>> getMensajesChat({
    required String chatId,
    required String usuarioId,
  }) async {
    final response = await http.get(_uri('/Chat/$chatId/mensajes/$usuarioId'));

    debugPrint('GET: ${_uri('/Chat/$chatId/mensajes/$usuarioId')}');
    debugPrint('STATUS: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener mensajes');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) {
      final map = json as Map<String, dynamic>;
      final emisorId = map['emisorId']?.toString() ?? '';

      return MessageModel(
        id: map['id']?.toString() ?? '',
        chatId: map['chatId']?.toString() ?? chatId,
        text: map['contenido']?.toString() ?? '',
        isMine: emisorId == usuarioId,
        time: _formatApiDate(map['fechaHora']?.toString()),
      );
    }).toList();
  }

  static Future<MessageModel> enviarMensajeChat({
    required String chatId,
    required String emisorId,
    required String receptorId,
    required String contenido,
  }) async {
    final response = await http.post(
      _uri('/Chat/mensaje'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chatId': chatId,
        'emisorId': emisorId,
        'receptorId': receptorId,
        'contenido': contenido,
      }),
    );

    debugPrint('POST: ${_uri('/Chat/mensaje')}');
    debugPrint('STATUS: ${response.statusCode}');

    final Map<String, dynamic> data =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['mensaje'] ?? 'Error al enviar mensaje');
    }

    final mensaje = data['mensajeEnviado'] as Map<String, dynamic>? ?? {};

    return MessageModel(
      id: mensaje['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      chatId: mensaje['chatId']?.toString() ?? chatId,
      text: mensaje['contenido']?.toString() ?? contenido,
      isMine: true,
      time: _formatApiDate(mensaje['fechaHora']?.toString()),
    );
  }

  static String _formatApiDate(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      final date = DateTime.parse(value).toLocal();
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  static Color _statusColorFromEstado(String estado) {
    final value = estado.toLowerCase().trim();

    if (value.contains('amigos') || value.contains('amigo')) {
      return const Color(0xFFEAB308);
    }

    if (value.contains('pareja')) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF22C55E);
  }

  static Future<Map<String, dynamic>> completarRetoActual({
    required String usuarioId,
    required String usuarioEscaneadoId,
  }) async {
    final response = await http.post(
      _uri('/Reto/completar-actual'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioId': usuarioId,
        'usuarioEscaneadoId': usuarioEscaneadoId,
      }),
    );

    debugPrint('POST: ${_uri('/Reto/completar-actual')}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al completar reto');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, RetoModel?>> getRetosTimeline(String usuarioId) async {
    final response = await http.get(_uri('/Reto/timeline/$usuarioId'));

    debugPrint('GET: ${_uri('/Reto/timeline/$usuarioId')}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener retos');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    RetoModel? parseReto(dynamic value) {
      if (value == null) return null;
      return RetoModel.fromJson(value as Map<String, dynamic>);
    }

    return {
      'anterior': parseReto(data['anterior']),
      'activo': parseReto(data['activo']),
      'proximo': parseReto(data['proximo']),
    };
  }

  static Future<List<String>> obtenerPreguntasPorEstado(String estado) async {
    final estadoApi = _normalizarEstadoPreguntas(estado);

    final uri = _uri('/Preguntas/$estadoApi');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('GET: $uri');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al cargar preguntas: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('El backend no ha devuelto una lista de preguntas');
    }

    return decoded
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();
  }

  static String _normalizarEstadoPreguntas(String estado) {
    final value = estado.toLowerCase().trim();

    if (value.contains('verde') || value.contains('soltero')) {
      return 'verde';
    }

    if (value.contains('amarillo') ||
        value.contains('amigos') ||
        value.contains('amigo') ||
        value.contains('complicado')) {
      return 'amarillo';
    }

    if (value.contains('rojo') || value.contains('pareja')) {
      return 'rojo';
    }

    return 'verde';
  }

  static Future<List<PoderModel>> getTodosLosPoderes() async {
    final uri = _uri('/Poder');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('GET: $uri');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener poderes');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => PoderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PoderModel>> getPoderesUsuario(String usuarioId) async {
    final uri = _uri('/Poder/usuario/$usuarioId');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('GET: $uri');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener poderes del usuario');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => PoderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

class RegistroHostResponse {
  final String mensaje;
  final String usuarioId;
  final String salaId;
  final String codigoSala;
  final String nombreUsuario;

  RegistroHostResponse({
    required this.mensaje,
    required this.usuarioId,
    required this.salaId,
    required this.codigoSala,
    required this.nombreUsuario,
  });

  factory RegistroHostResponse.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>? ?? {};
    final sala = json['sala'] as Map<String, dynamic>? ?? {};

    return RegistroHostResponse(
      mensaje: json['mensaje']?.toString() ?? '',
      usuarioId: usuario['id']?.toString() ?? '',
      salaId: sala['id']?.toString() ?? '',
      codigoSala:
          json['codigoSala']?.toString() ?? sala['codigoSala']?.toString() ?? '',
      nombreUsuario: usuario['nombre']?.toString() ?? 'Host',
    );
  }
}

class RegistroInvitadoResponse {
  final String usuarioId;
  final String salaId;
  final String nombreUsuario;

  RegistroInvitadoResponse({
    required this.usuarioId,
    required this.salaId,
    required this.nombreUsuario,
  });

  factory RegistroInvitadoResponse.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>;
    final sala = json['sala'] as Map<String, dynamic>;
    return RegistroInvitadoResponse(
      usuarioId: usuario['id']?.toString() ?? '',
      salaId: sala['id']?.toString() ?? '',
      nombreUsuario: usuario['nombre']?.toString() ?? 'Invitado',
    );
  }
}

class SalaUsuarioModel {
  final String id;
  final String nombre;
  final DateTime fechaNacimiento;
  final String estado;
  final String? foto;
  final bool esHost;
  final bool baneado;
  final int puntos;

  SalaUsuarioModel({
    required this.id,
    required this.nombre,
    required this.fechaNacimiento,
    required this.estado,
    required this.esHost,
    required this.baneado,
    required this.puntos,
    this.foto,
  });

  int get edad {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;

    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }

    return edad;
  }

  Color get statusColor {
    switch (estado.toLowerCase()) {
      case 'verde':
      case 'soltero':
        return const Color(0xFF22C55E);

      case 'amarillo':
      case 'complicado':
        return const Color(0xFFEAB308);

      case 'rojo':
      case 'pareja':
        return const Color(0xFFEF4444);

      default:
        return const Color(0xFF22C55E);
    }
  }

  factory SalaUsuarioModel.fromJson(Map<String, dynamic> json) {
    return SalaUsuarioModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      fechaNacimiento: DateTime.parse(
        json['fechaNacimiento']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      estado: json['estado']?.toString() ?? 'verde',
      foto: json['foto']?.toString(),
      esHost: json['tipo']?.toString() == 'host',
      baneado: json['baneado'] as bool? ?? false,
      puntos: json['puntos'] as int? ?? 0,
    );
  }
}

class PoderModel {
  final String id;
  final String nivelId;
  final int puntosNecesarios;
  final String conceptoPoder;

  PoderModel({
    required this.id,
    required this.nivelId,
    required this.puntosNecesarios,
    required this.conceptoPoder,
  });

  factory PoderModel.fromJson(Map<String, dynamic> json) {
    return PoderModel(
      id: json['id']?.toString() ??
          json['Id']?.toString() ??
          json['_id']?.toString() ??
          '',
      nivelId: json['nivelId']?.toString() ??
          json['NivelId']?.toString() ??
          json['nivel']?.toString() ??
          '',
      puntosNecesarios: json['puntosNecesarios'] is int
          ? json['puntosNecesarios'] as int
          : int.tryParse(
                json['puntosNecesarios']?.toString() ??
                    json['PuntosNecesarios']?.toString() ??
                    '0',
              ) ??
              0,
      conceptoPoder: json['conceptoPoder']?.toString() ??
          json['ConceptoPoder']?.toString() ??
          json['descripcion']?.toString() ??
          '',
    );
  }
}

class VerdadRetoRandom {
    final String verdad;
    final String reto;

    VerdadRetoRandom({
      required this.verdad,
      required this.reto,
    });

    factory VerdadRetoRandom.fromJson(Map<String, dynamic> json) {
      return VerdadRetoRandom(
        verdad: json['verdad']?.toString() ?? '',
        reto: json['reto']?.toString() ?? '',
      );
    }
  }