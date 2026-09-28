const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const readline = require('readline');

const args = process.argv.slice(2);
const isApply = args.includes('--apply');
const includeAuth = args.includes('--include-auth');
const includeStorage = args.includes('--include-storage');

console.log('=== LOCUSTAF Wipe Test Data ===\n');

if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log('⚠️  ATENCIÓN: FIRESTORE_EMULATOR_HOST detectado. El script está operando contra el EMULADOR local.');
} else {
  console.log('⚠️  ATENCIÓN: Corriendo contra un PROYECTO REAL de Firebase.');
}
console.log('');

if (!isApply) {
  console.log('MODO DRY-RUN ACTIVADO (por defecto). Usa --apply para ejecutar el borrado real.');
}
if (includeAuth) {
  console.log('Opción --include-auth detectada: también se borrarán los usuarios de Firebase Auth.');
}
if (includeStorage) {
  console.log('Opción --include-storage detectada: se borrarán los archivos de Firebase Storage.');
}
console.log('');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'locustaf-31ed2';

let app;
try {
  app = initializeApp({ 
    projectId: PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET || `${PROJECT_ID}.firebasestorage.app`
  });
} catch (error) {
  console.error('ERROR: No se pudo inicializar Firebase Admin SDK.');
  console.error('Asegúrate de estar autenticado: gcloud auth application-default login');
  console.error(error.message);
  process.exit(1);
}

const db = getFirestore(app);
const projectId = PROJECT_ID;

async function promptConfirmation(text) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(text, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

async function wipeData() {
  console.log(`Proyecto detectado: ${projectId}`);
  
  const superadminsIds = new Set();
  const usersSnapshot = await db.collection('users').where('rol', '==', 'superadmin').get();
  usersSnapshot.forEach(doc => {
    superadminsIds.add(doc.id);
  });
  
  console.log(`Superadmins protegidos encontrados: ${superadminsIds.size}`);

  if (isApply && superadminsIds.size === 0) {
    console.log('❌ ERROR: No se encontró ningún superadmin protegido.');
    console.log('Por seguridad, --apply se niega a ejecutar el borrado si no hay al menos un superadmin.');
    process.exit(1);
  }

  if (isApply) {
    console.log('\n¡ADVERTENCIA! Estás a punto de borrar los datos del proyecto.');
    const answer = await promptConfirmation(`Para continuar, escribe el nombre del proyecto (${projectId}): `);
    
    if (answer !== projectId) {
      console.log('Confirmación fallida. Cancelando operación.');
      process.exit(1);
    }
    console.log('\nConfirmación aceptada. Iniciando borrado...\n');
  }

  const collections = [
    'companies',
    'workplaces',
    'users',
    'medical_documents',
    'incidences',
    'attendances',
    'payments'
  ];

  // Identificar colecciones no estándar
  const allRootCollections = await db.listCollections();
  const unknownCollections = [];
  for (const collRef of allRootCollections) {
    if (!collections.includes(collRef.id)) {
      unknownCollections.push(collRef.id);
    }
  }

  if (unknownCollections.length > 0) {
    console.log(`\nColecciones extrañas detectadas (NO serán borradas): ${unknownCollections.join(', ')}`);
  }

  let totalDocsDeleted = 0;
  let totalAuthDeleted = 0;
  let totalStorageDeleted = 0;

  // Delete Firestore documents
  console.log('\nProcesando colecciones de Firestore...');
  for (const collName of collections) {
    const snapshot = await db.collection(collName).get();
    let deletedInCollection = 0;
    
    const batchArray = [];
    let currentBatch = db.batch();
    let currentBatchSize = 0;
    
    for (const doc of snapshot.docs) {
      if (collName === 'users' && superadminsIds.has(doc.id)) {
        continue;
      }
      
      deletedInCollection++;
      totalDocsDeleted++;
      
      if (isApply) {
        currentBatch.delete(doc.ref);
        currentBatchSize++;
        if (currentBatchSize === 500) {
          batchArray.push(currentBatch.commit());
          currentBatch = db.batch();
          currentBatchSize = 0;
        }
      }
    }
    
    if (isApply && currentBatchSize > 0) {
      batchArray.push(currentBatch.commit());
    }
    
    if (isApply) {
      await Promise.all(batchArray);
      console.log(`  - Colección '${collName}': ${deletedInCollection} documentos borrados.`);
    } else {
      console.log(`  [Dry-Run] Colección '${collName}': se borrarían ${deletedInCollection} documentos.`);
    }
  }

  // Delete Storage files
  console.log('\nProcesando Storage...');
  try {
    const bucket = getStorage(app).bucket(); // Use default bucket configured in initializeApp
    const [files] = await bucket.getFiles();
    
    if (isApply && includeStorage) {
      for (const file of files) {
        await file.delete();
        totalStorageDeleted++;
      }
      console.log(`  - Borrados ${totalStorageDeleted} archivos de Storage.`);
    } else {
      console.log(`  [Dry-Run] Se encontraron ${files.length} archivos en Storage.${!includeStorage ? ' (Omite --include-storage para borrar)' : ''}`);
      if (includeStorage) totalStorageDeleted = files.length;
    }
  } catch (err) {
    console.log(`  No se pudo acceder al bucket de Storage. ${err.message}`);
  }

  // Delete Auth users if requested
  if (includeAuth) {
    console.log('\nProcesando usuarios de Auth...');
    
    let pageToken;
    do {
      const listUsersResult = await getAuth(app).listUsers(1000, pageToken);
      const uidsToDelete = [];
      
      for (const userRecord of listUsersResult.users) {
        if (!superadminsIds.has(userRecord.uid)) {
          uidsToDelete.push(userRecord.uid);
          totalAuthDeleted++;
        }
      }
      
      if (isApply && uidsToDelete.length > 0) {
        await getAuth(app).deleteUsers(uidsToDelete);
        console.log(`  - Borrados ${uidsToDelete.length} usuarios de Auth en este lote.`);
      } else if (!isApply && uidsToDelete.length > 0) {
        console.log(`  [Dry-Run] Se borrarían ${uidsToDelete.length} usuarios de Auth en este lote.`);
      }
      
      pageToken = listUsersResult.pageToken;
    } while (pageToken);
  }

  console.log('\n=== RESUMEN ===');
  if (isApply) {
    console.log(`Documentos de Firestore borrados: ${totalDocsDeleted}`);
    if (includeStorage) console.log(`Archivos de Storage borrados: ${totalStorageDeleted}`);
    if (includeAuth) console.log(`Usuarios de Auth borrados: ${totalAuthDeleted}`);
    console.log('Operación completada con éxito.');
  } else {
    console.log(`Documentos de Firestore que se borrarían: ${totalDocsDeleted}`);
    if (includeStorage) console.log(`Archivos de Storage que se borrarían: ${totalStorageDeleted}`);
    if (includeAuth) console.log(`Usuarios de Auth que se borrarían: ${totalAuthDeleted}`);
    console.log('Operación Dry-Run completada.');
  }
}

wipeData().catch(console.error);
