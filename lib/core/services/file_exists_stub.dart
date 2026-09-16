/// Stub para web: no hay sistema de archivos accesible con dart:io, y en web
/// el guardado (descarga del navegador / share) lo confirma la propia
/// operación sin necesitar chequear el disco.
bool fileExistsOnDisk(String path) => true;