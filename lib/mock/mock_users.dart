import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final int age;
  final Color statusColor;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.statusColor,
  });
}

class SalaUsuarioModel {
  final String id;
  final String nombre;
  final int edad;
  final String estado;
  final String? foto;
  final bool baneado;
  final Color statusColor;

  SalaUsuarioModel({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.estado,
    required this.statusColor,
    this.foto,
    this.baneado = false,
  });

  factory SalaUsuarioModel.fromJson(Map<String, dynamic> json) {
    final String estado = (json['estado'] ?? '').toString();

    return SalaUsuarioModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? 'Usuario').toString(),
      edad: _calcularEdadDesdeJson(json),
      estado: estado,
      foto: json['foto']?.toString(),
      baneado: json['baneado'] == true,
      statusColor: _getColorFromEstado(estado),
    );
  }

  static int _calcularEdadDesdeJson(Map<String, dynamic> json) {
    if (json['edad'] != null) {
      if (json['edad'] is int) return json['edad'];
      return int.tryParse(json['edad'].toString()) ?? 0;
    }

    final fechaRaw = json['fechaNacimiento'];
    if (fechaRaw == null) return 0;

    try {
      final fecha = DateTime.parse(fechaRaw.toString());
      final hoy = DateTime.now();

      int edad = hoy.year - fecha.year;

      final bool noHaCumplidoEsteAnio =
          hoy.month < fecha.month ||
          (hoy.month == fecha.month && hoy.day < fecha.day);

      if (noHaCumplidoEsteAnio) {
        edad--;
      }

      return edad;
    } catch (_) {
      return 0;
    }
  }

  static Color _getColorFromEstado(String estado) {
    final value = estado.toLowerCase().trim();

    switch (value) {
      case 'soltero':
      case 'single':
        return const Color(0xFF22C55E);

      case 'complicado':
      case 'complicated':
        return const Color(0xFFEAB308);

      case 'pareja':
      case 'relationship':
        return const Color(0xFFEF4444);

      default:
        return const Color(0xFF9C4DFF);
    }
  }
}