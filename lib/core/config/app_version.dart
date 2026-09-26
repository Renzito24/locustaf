/// Identificador de build visible en la app.
///
/// Permite confirmar en el dispositivo físico qué versión del APK está
/// instalada (Ronda 3A — UX Empleado). El prefijo "v" está incluido en la
/// constante a propósito; quien la muestre no debe anteponer otra "v".
/// Debe mantenerse sincronizado con la versión declarada en `pubspec.yaml`
/// (2.1.0+3).
const String appVersion = 'v2.1';
const String appBuildLabel = 'Ronda 3A — UX Empleado';