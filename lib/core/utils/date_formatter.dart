/// Utilidades de formato de fechas usadas en la UI (Fase B — C3).
library;

/// Convierte una fecha ISO (`yyyy-MM-dd`) a [DateTime] de forma segura.
///
/// Devuelve `null` si el valor es nulo, vacío o no parseable, protegiendo
/// el flujo contra errores de `DateTime.parse` con valores inválidos.
///
/// La validación es estricta: rechaza componentes fuera de rango (p. ej.
/// `2026-13-45` o `2026-02-30`) que `DateTime.parse` normalizaría por
/// desbordamiento en lugar de rechazar.
DateTime? tryParseIsoDate(String? value) {
  if (value == null) return null;
  final v = value.trim();
  if (v.isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final candidate = DateTime(year, month, day);
  // Rechaza fechas normalizadas por overflow (p. ej. 2026-02-30 → 2026-03-02).
  if (candidate.year != year ||
      candidate.month != month ||
      candidate.day != day) {
    return null;
  }
  return candidate;
}

/// Formato interno del sistema: `yyyy-MM-dd`.
String formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Formato amigable para el usuario: `dd/MM/yyyy`.
String formatUserDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}