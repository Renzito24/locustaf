/// No-op para plataformas sin DOM (VM, Android, iOS, desktop).
///
/// [downloadViaAnchor] solo se invoca con `kIsWeb == true`: en la compilación
/// de web se resuelve a la implementación real de `web_download_web.dart`.
void downloadViaAnchor(String url, String fileName) {}
