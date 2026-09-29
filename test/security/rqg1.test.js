import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'locustaf-test',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    
    await db.collection('companies').doc('companyA').set({ createdBy: 'superA' });
    await db.collection('companies').doc('companyB').set({ createdBy: 'superB' });
    
    await db.collection('users').doc('empA').set({ id: 'empA', rol: 'employee', companyId: 'companyA' });
    await db.collection('users').doc('empB').set({ id: 'empB', rol: 'employee', companyId: 'companyB' });
    await db.collection('users').doc('adminA').set({ id: 'adminA', rol: 'admin', companyId: 'companyA' });

    await db.collection('attendances').doc('attA').set({ userId: 'empA', companyId: 'companyA', status: 'active' });
    await db.collection('attendances').doc('attB').set({ userId: 'empB', companyId: 'companyB', status: 'active' });
  });
});

describe('R-QG-1: Attendance isolation', () => {
  it('empleado A -> leer asistencia propia de empresa A (DEBE PASAR)', async () => {
    const empA = testEnv.authenticatedContext('empA');
    await assertSucceeds(empA.firestore().collection('attendances').doc('attA').get());
  });

  it('empleado A -> leer asistencia de otro empleado de empresa A (DEBE FALLAR)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('attendances').doc('attA_other').set({
          userId: 'empA_other',
          companyId: 'companyA',
          status: 'active'
        });
    });
    const empA = testEnv.authenticatedContext('empA');
    await assertFails(empA.firestore().collection('attendances').doc('attA_other').get());
  });

  it('empleado A -> leer asistencia de empresa B (DEBE FALLAR)', async () => {
    const empA = testEnv.authenticatedContext('empA');
    await assertFails(empA.firestore().collection('attendances').doc('attB').get());
  });

  it('admin de empresa A -> acceder a informacion de empresa B (DEBE FALLAR)', async () => {
    const adminA = testEnv.authenticatedContext('adminA');
    await assertFails(adminA.firestore().collection('attendances').doc('attB').get());
  });

  it('usuario sin autenticacion -> acceder a attendance (DEBE FALLAR)', async () => {
    const unauth = testEnv.unauthenticatedContext();
    await assertFails(unauth.firestore().collection('attendances').doc('attA').get());
  });
});
