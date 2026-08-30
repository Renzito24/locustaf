/**
 * Lógica pura del sincronizador de estado de usuario (A2).
 *
 * Decide si la cuenta de Firebase Auth debe habilitarse/deshabilitarse ante un
 * cambio en el documento `users/{userId}`:
 *  - `isDeleted: true` o `isActive: false`  -> deshabilitar
 *  - `isDeleted: false` y `isActive: true`   -> habilitar
 *  - Sin cambio en el estado -> no hacer nada
 *
 * Se extrae en un módulo sin efectos para poder unit-testear el contrato sin
 * depender del emulador de Cloud Functions.
 */

/**
 * Devuelve `{ update: false }` si el estado no cambió, o
 * `{ update: true, disabled }` con el valor objetivo de `disabled` en Auth.
 */
function computeUserAuthUpdate(before, after) {
  if (!before || !after) {
    return { update: false };
  }

  const wasDisabled = !before.isActive || before.isDeleted;
  const isDisabled = !after.isActive || after.isDeleted;

  if (wasDisabled === isDisabled) {
    return { update: false };
  }

  return { update: true, disabled: isDisabled };
}

module.exports = { computeUserAuthUpdate };