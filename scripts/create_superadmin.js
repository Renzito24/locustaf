const admin = require('firebase-admin');

// Parse CLI arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const emailArg = args.find(a => a.startsWith('--email='));

if (!emailArg) {
  console.error('ERROR: Debes proveer un email con --email=tucorreo@ejemplo.com');
  process.exit(1);
}

const email = emailArg.split('=')[1].toLowerCase();

console.log('=== LOCUSTAF Superadmin Script ===\n');
console.log(`Ejecutando para email: ${email}`);

if (isDryRun) {
  console.log('MODO DRY-RUN ACTIVADO. No se realizarán cambios reales en el proyecto.');
  console.log(`\n  [Dry-Run] 1. Inicializaría Firebase Admin SDK usando Application Default Credentials (ADC) o entorno.`);
  console.log(`  [Dry-Run] 2. Verificando en Firebase Auth si el usuario ${email} existe...`);
  console.log(`  [Dry-Run] 3. Creando el usuario ${email} en Auth si no existe...`);
  console.log(`  [Dry-Run] 4. Generando un link de restablecimiento de contraseña...`);
  console.log(`  [Dry-Run] 5. Creando/Actualizando documento users/{uid} en Firestore con:`);
  console.log(`      - email: ${email}`);
  console.log(`      - rol: superadmin`);
  console.log(`      - isActive: true`);
  console.log(`      - isDeleted: false`);
  console.log(`      - createdAt / updatedAt actualizados`);
  console.log('\n[Dry-Run] Finalizado con éxito.');
  process.exit(0);
}

// Ensure Google Application Default Credentials are set for Admin SDK
// You must have run `gcloud auth application-default login` or set GOOGLE_APPLICATION_CREDENTIALS
try {
  admin.initializeApp();
} catch (error) {
  console.error('\nERROR: No se pudo inicializar Firebase Admin SDK.');
  console.error('Asegúrate de estar autenticado: gcloud auth application-default login');
  console.error(error.message);
  process.exit(1);
}

async function run() {
  try {
    let uid;
    try {
      console.log(`Buscando usuario en Auth: ${email}...`);
      const userRecord = await admin.auth().getUserByEmail(email);
      uid = userRecord.uid;
      console.log(`  - Usuario encontrado (uid: ${uid}).`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log(`  - Usuario no encontrado. Creando nuevo usuario en Auth sin contraseña inicial...`);
        const userRecord = await admin.auth().createUser({
          email: email,
        });
        uid = userRecord.uid;
        console.log(`  - Creado con uid: ${uid}`);
      } else {
        throw error;
      }
    }

    console.log(`Generando enlace para establecer/restablecer la contraseña...`);
    const resetLink = await admin.auth().generatePasswordResetLink(email);

    const db = admin.firestore();
    const userRef = db.collection('users').doc(uid);
    
    console.log(`Creando/Actualizando documento en Firestore para users/${uid}...`);
    
    const now = new Date().toISOString();
    
    // Idempotent upsert
    await userRef.set({
      id: uid,
      email: email,
      rol: 'superadmin',
      isActive: true,
      isDeleted: false,
      updatedAt: now,
    }, { merge: true });
    
    // Set createdAt only if it doesn't exist
    const doc = await userRef.get();
    if (!doc.data().createdAt) {
      await userRef.update({ createdAt: now });
    }

    console.log('\n=== ÉXITO ===');
    console.log(`Usuario superadmin configurado correctamente para ${email}.`);
    console.log(`\nIMPORTANTE: Ingresa a este enlace para establecer tu contraseña:`);
    console.log(`👉 ${resetLink}\n`);
    
  } catch (error) {
    console.error('\nERROR inesperado:', error);
    process.exit(1);
  }
}

run();
