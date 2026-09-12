import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';

const __dirname = dirname(fileURLToPath(import.meta.url));
const firestoreRules = readFileSync(
  join(__dirname, '..', '..', 'firestore.rules'),
  'utf8',
);
const storageRules = readFileSync(
  join(__dirname, '..', '..', 'storage.rules'),
  'utf8',
);

const PROJECT_ID = 'locustaf-test';
const FIRESTORE_PORT = 8081;
const STORAGE_PORT = 9199;

const MAX_BYTES = 10 * 1024 * 1024;

let testEnv;

// ─── Helpers ────────────────────────────────────────────────────────────────

async function seedUser(uid, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`users/${uid}`).set({ ...data, id: uid });
  });
}

function docPath(companyId, userId, fileName) {
  return `companies/${companyId}/medical_documents/${userId}/${fileName}`;
}

function makeBlob(sizeBytes, contentType) {
  return new Blob([new Uint8Array(sizeBytes)], { type: contentType });
}

// ─── Setup / Teardown ───────────────────────────────────────────────────────

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: FIRESTORE_PORT,
      rules: firestoreRules,
    },
    storage: {
      host: '127.0.0.1',
      port: STORAGE_PORT,
      rules: storageRules,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

// ─── Tests: subida y lectura de justificativos ──────────────────────────────

describe('Storage: subida de justificativos (M1)', () => {
  it('un empleado SÍ puede subir su propio PDF como justificativo', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    const blob = makeBlob(1024, 'application/pdf');
    await assertSucceeds(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf')),
        blob,
        { contentType: 'application/pdf' },
      ),
    );
  });

  it('un empleado NO puede subir un archivo de más de 10 MB', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    const blob = makeBlob(MAX_BYTES + 1, 'application/pdf');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-1', 'doc-gigante.pdf')),
        blob,
        { contentType: 'application/pdf' },
      ),
    );
  });

  it('un empleado NO puede subir un ejecutable (.exe)', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    const blob = makeBlob(1024, 'application/x-msdownload');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-1', 'malware.exe')),
        blob,
        { contentType: 'application/x-msdownload' },
      ),
    );
  });

  it('un empleado NO puede subir al path de otro empleado', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('emp-2', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    const blob = makeBlob(1024, 'application/pdf');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-2', 'doc-ajeno.pdf')),
        blob,
        { contentType: 'application/pdf' },
      ),
    );
  });

  it('un empleado NO puede subir a la carpeta de otra empresa', async () => {
    await seedUser('emp-a1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('emp-b1', {
      rol: 'employee',
      companyId: 'emp-b',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-a1');
    const blob = makeBlob(1024, 'application/pdf');
    await assertFails(
      uploadBytes(
        ref(
          ctx.storage(),
          docPath('emp-b', 'emp-a1', 'filtrado-a-empresa-b.pdf'),
        ),
        blob,
        { contentType: 'application/pdf' },
      ),
    );
  });

  it('un usuario NO autenticado no puede subir justificativos', async () => {
    const ctx = testEnv.unauthenticatedContext();
    const blob = makeBlob(1024, 'application/pdf');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'anon', 'doc-anon.pdf')),
        blob,
        { contentType: 'application/pdf' },
      ),
    );
  });

  it('un supervisor NO puede subir justificativo a la carpeta de un empleado (rol sin escritura ajena)', async () => {
    await seedUser('sup-1', {
      rol: 'supervisor',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('sup-1');
    const blob = makeBlob(1024, 'application/pdf');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-1', 'doc-victima.pdf')),
        blob,
        { contentType: 'application/pdf' },
      ),
    );
  });

  it('un empleado NO puede subir un HTML (content type no permitido)', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    const blob = makeBlob(1024, 'text/html');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-1', 'phishing.html')),
        blob,
        { contentType: 'text/html' },
      ),
    );
  });

  it('un empleado NO puede subir un JavaScript (content type no permitido)', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    const blob = makeBlob(1024, 'text/javascript');
    await assertFails(
      uploadBytes(
        ref(ctx.storage(), docPath('emp-a', 'emp-1', 'script.js')),
        blob,
        { contentType: 'text/javascript' },
      ),
    );
  });
});

describe('Storage: lectura de justificativos (M1)', () => {
  it('un empleado SÍ puede leer su propio justificativo', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const uploadCtx = testEnv.authenticatedContext('emp-1');
    await uploadBytes(
      ref(uploadCtx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf')),
      makeBlob(1024, 'application/pdf'),
      { contentType: 'application/pdf' },
    );
    const readCtx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      getDownloadURL(
        ref(readCtx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf')),
      ),
    );
  });

  it('un admin SÍ puede leer el justificativo de un empleado de su empresa', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('adm-1', {
      rol: 'admin',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const uploadCtx = testEnv.authenticatedContext('emp-1');
    await uploadBytes(
      ref(uploadCtx.storage(), docPath('emp-a', 'emp-1', 'documento.pdf')),
      makeBlob(1024, 'application/pdf'),
      { contentType: 'application/pdf' },
    );
    const readCtx = testEnv.authenticatedContext('adm-1');
    await assertSucceeds(
      getDownloadURL(
        ref(readCtx.storage(), docPath('emp-a', 'emp-1', 'documento.pdf')),
      ),
    );
  });

  it('un supervisor NO puede leer el justificativo de un empleado (privacidad)', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('sup-1', {
      rol: 'supervisor',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const uploadCtx = testEnv.authenticatedContext('emp-1');
    await uploadBytes(
      ref(uploadCtx.storage(), docPath('emp-a', 'emp-1', 'documento.pdf')),
      makeBlob(1024, 'application/pdf'),
      { contentType: 'application/pdf' },
    );
    const readCtx = testEnv.authenticatedContext('sup-1');
    await assertFails(
      getDownloadURL(
        ref(readCtx.storage(), docPath('emp-a', 'emp-1', 'documento.pdf')),
      ),
    );
  });

  it('un empleado de otra empresa NO puede leer el justificativo', async () => {
    await seedUser('emp-a1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('emp-b1', {
      rol: 'employee',
      companyId: 'emp-b',
      isActive: true,
      isDeleted: false,
    });
    const uploadCtx = testEnv.authenticatedContext('emp-a1');
    await uploadBytes(
      ref(uploadCtx.storage(), docPath('emp-a', 'emp-a1', 'confidencial.pdf')),
      makeBlob(1024, 'application/pdf'),
      { contentType: 'application/pdf' },
    );
    const readCtx = testEnv.authenticatedContext('emp-b1');
    await assertFails(
      getDownloadURL(
        ref(readCtx.storage(), docPath('emp-a', 'emp-a1', 'confidencial.pdf')),
      ),
    );
  });

  it('un admin de OTRA empresa NO puede leer el justificativo', async () => {
    await seedUser('adm-a1', {
      rol: 'admin',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('adm-b1', {
      rol: 'admin',
      companyId: 'emp-b',
      isActive: true,
      isDeleted: false,
    });
    const uploadCtx = testEnv.authenticatedContext('adm-a1');
    await uploadBytes(
      ref(uploadCtx.storage(), docPath('emp-a', 'adm-b1', 'confidencial.pdf')),
      makeBlob(1024, 'application/pdf'),
      { contentType: 'application/pdf' },
    );
    const readCtx = testEnv.authenticatedContext('adm-b1');
    await assertFails(
      getDownloadURL(
        ref(readCtx.storage(), docPath('emp-a', 'adm-b1', 'confidencial.pdf')),
      ),
    );
  });

  it('un usuario NO autenticado NO puede leer justificativos', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    const uploadCtx = testEnv.authenticatedContext('emp-1');
    await uploadBytes(
      ref(uploadCtx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf')),
      makeBlob(1024, 'application/pdf'),
      { contentType: 'application/pdf' },
    );
    const readCtx = testEnv.unauthenticatedContext();
    await assertFails(
      getDownloadURL(
        ref(readCtx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf')),
      ),
    );
  });
});

describe('Storage: eliminación de justificativos (M1)', () => {
  async function uploadAs(uid, pathRef) {
    const ctx = testEnv.authenticatedContext(uid);
    await uploadBytes(ref(ctx.storage(), pathRef), makeBlob(1024, 'application/pdf'), {
      contentType: 'application/pdf',
    });
  }

  it('un empleado SÍ puede eliminar su propio justificativo', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await uploadAs('emp-1', docPath('emp-a', 'emp-1', 'doc1.pdf'));
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      deleteObject(ref(ctx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf'))),
    );
  });

  it('un empleado NO puede eliminar el justificativo de otro empleado', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('emp-2', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await uploadAs('emp-1', docPath('emp-a', 'emp-1', 'doc1.pdf'));
    const ctx = testEnv.authenticatedContext('emp-2');
    await assertFails(
      deleteObject(ref(ctx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf'))),
    );
  });

  it('un empleado NO puede eliminar justificativos de OTRA empresa', async () => {
    await seedUser('emp-a1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await seedUser('emp-b1', {
      rol: 'employee',
      companyId: 'emp-b',
      isActive: true,
      isDeleted: false,
    });
    await uploadAs('emp-b1', docPath('emp-b', 'emp-b1', 'doc-b.pdf'));
    const ctx = testEnv.authenticatedContext('emp-a1');
    await assertFails(
      deleteObject(ref(ctx.storage(), docPath('emp-b', 'emp-b1', 'doc-b.pdf'))),
    );
  });

  it('un usuario NO autenticado NO puede eliminar justificativos', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-a',
      isActive: true,
      isDeleted: false,
    });
    await uploadAs('emp-1', docPath('emp-a', 'emp-1', 'doc1.pdf'));
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(
      deleteObject(ref(ctx.storage(), docPath('emp-a', 'emp-1', 'doc1.pdf'))),
    );
  });
});