const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const readline = require('readline');

const args = process.argv.slice(2);
const isApply = args.includes('--apply');
const includeAuth = args.includes('--include-auth');

console.log('=== LOCUSTAF Wipe Test Data ===\n');

if (!isApply) {
  console.log('MODO DRY-RUN ACTIVADO (por defecto). Usa --apply para ejecutar el borrado real.');
}
if (includeAuth) {
  console.log('Opcion --include-auth detectada: también se borrarán los usuarios de Firebase Auth.');
}
console.log('');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'locustaf-31ed2';

let app;
try {
  app = initializeApp({ projectId: PROJECT_ID });
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
  
  if (isApply) {
    console.log('\n¡ADVERTENCIA! Estás a punto de borrar TODOS los datos del proyecto.');
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

  let totalDocsDeleted = 0;
  let totalAuthDeleted = 0;
  const superadminsIds = new Set();

  // First, find all superadmins so we don't delete them or their auth accounts
  const usersSnapshot = await db.collection('users').where('rol', '==', 'superadmin').get();
  usersSnapshot.forEach(doc => {
    superadminsIds.add(doc.id);
  });
  
  console.log(`Superadmins protegidos encontrados: ${superadminsIds.size}`);

  // Delete Firestore documents
  for (const collName of collections) {
    const snapshot = await db.collection(collName).get();
    let deletedInCollection = 0;
    
    const batchArray = [];
    let currentBatch = db.batch();
    let currentBatchSize = 0;
    
    for (const doc of snapshot.docs) {
      // Prevent deleting superadmin user documents
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
    if (includeAuth) console.log(`Usuarios de Auth borrados: ${totalAuthDeleted}`);
    console.log('Operación completada con éxito.');
  } else {
    console.log(`Documentos de Firestore que se borrarían: ${totalDocsDeleted}`);
    if (includeAuth) console.log(`Usuarios de Auth que se borrarían: ${totalAuthDeleted}`);
    console.log('Operación Dry-Run completada.');
  }
}

wipeData().catch(console.error);
