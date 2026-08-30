/// Utilidades para la manipulación segura de strings.
class StringUtils {
  StringUtils._();

  /// Devuelve el prefijo de los primeros [length] caracteres de [value].
  /// Si [value] es más corto (o vacío) devuelve el string completo, evitando
  /// un [RangeError] por longitud insuficiente.
  static String safePrefix(String value, int length) {
    if (value.length <= length) return value;
    return value.substring(0, length);
  }
}