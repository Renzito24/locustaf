import 'dart:io';

/// Verifica en plataformas con sistema de archivos (móvil/desktop) que el
/// archivo realmente exista en el path devuelto por el guardado.
bool fileExistsOnDisk(String path) => File(path).existsSync();