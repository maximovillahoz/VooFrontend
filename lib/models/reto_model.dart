class RetoModel {
  final String id;
  final String tipo;
  final String concepto;
  final int puntos;
  final DateTime? horaActivacion;
  final Duration duracion;

  const RetoModel({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.puntos,
    required this.horaActivacion,
    required this.duracion,
  });

  factory RetoModel.fromJson(Map<String, dynamic> json) {
    return RetoModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      concepto: json['concepto']?.toString() ?? '',
      puntos: json['puntos'] as int? ?? 0,
      horaActivacion: json['horaActivacion'] == null
          ? null
          : DateTime.tryParse(json['horaActivacion'].toString())?.toLocal(),
      duracion: _parseDuration(json['duracion']),
    );
  }

  static Duration _parseDuration(dynamic value) {
    if (value == null) return const Duration(minutes: 30);

    final text = value.toString();

    final parts = text.split(':');
    if (parts.length >= 3) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2].split('.').first) ?? 0,
      );
    }

    return const Duration(minutes: 30);
  }
}