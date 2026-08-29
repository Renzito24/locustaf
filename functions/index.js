/**
 * Cloud Functions de LOCUSTAF.
 *
 * Sincroniza el estado de la cuenta de Firebase Auth con el documento del
 * usuario en Firestore:
 *  - Si un usuario se marca como eliminado (isDeleted) o desactivado
 *    (isActive = false), se deshabilita su cuenta de Auth para que no pueda
 *    iniciar sesión.
 *  - Si se reactiva (isActive = true y isDeleted = false), se habilita.
 *
 * Esto cierra la brecha de seguridad donde un empleado "eliminado" conservaba
 * su sesión/credencial activa en el servidor.
 */
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

initializeApp();

exports.syncUserAuthStatus = onDocumentUpdated(
  {
    document: 'users/{userId}',
    region: 'southamerica-east1',
  },
  async (event) => {
    const userId = event.params.userId;
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) {
      console.log(`Sin datos para el usuario ${userId}`);
      return;
    }

    const wasDisabled = !before.isActive || before.isDeleted;
    const isDisabled = !after.isActive || after.isDeleted;

    // Si el estado no cambió, no hacemos nada.
    if (wasDisabled === isDisabled) {
      return;
    }

    try {
      await getAuth().updateUser(userId, { disabled: isDisabled });
      console.log(
        `Usuario ${userId} ${isDisabled ? 'deshabilitado' : 'habilitado'} en Auth.`
      );
    } catch (err) {
      console.error(`Error al actualizar Auth del usuario ${userId}:`, err);
    }
  }
);
