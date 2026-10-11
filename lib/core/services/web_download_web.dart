import 'package:web/web.dart' as web;

/// Descarga directa en web con la URL firmada, sin pasar por CORS: crea un
/// ancla invisible con atributo `download` y la clicca. Es una navegación
/// del navegador a la URL firmada (GET autenticado), no un fetch XHR, por lo
/// que las políticas CORS del bucket no aplican.
void downloadViaAnchor(String url, String fileName) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
