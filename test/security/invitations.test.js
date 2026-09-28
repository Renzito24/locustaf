import { readFileSync } from 'fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { before, after, beforeEach, afterEach, describe, it } from 'node:test';

const PROJECT_ID = 'locustaf-test';
const RULES_PATH = '../../firestore.rules';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('Invitations & Onboarding Security Rules', () => {

  it('(1) nadie puede reclamar una invitación con un email que no es el suyo o que no está verificado', async () => {
    // Preparar una invitación existente
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('invitations').doc('empleado@test.com').set({
        companyId: 'comp1',
        rol: 'employee'
      });
      await db.collection('companies').doc('comp1').set({ createdBy: 'admin123' });
    });

    // Intento 1: Email correcto pero NO verificado
    const unverifiedContext = testEnv.authenticatedContext('uid1', { email: 'empleado@test.com', email_verified: false });
    const unverifiedDb = unverifiedContext.firestore();
    await assertFails(unverifiedDb.collection('invitations').doc('empleado@test.com').get()); // No puede leerla
    await assertFails(
      unverifiedDb.collection('users').doc('uid1').set({
        id: 'uid1',
        email: 'empleado@test.com',
        dni: '',
        rol: 'employee',
        isActive: true,
        isDeleted: false,
        companyId: 'comp1',
        lugarDeTrabajoId: null,
        createdAt: new Date()
      })
    ); // No puede usarla para crearse

    // Intento 2: Email verificado pero NO es el suyo
    const hackerContext = testEnv.authenticatedContext('hacker', { email: 'hacker@test.com', email_verified: true });
    const hackerDb = hackerContext.firestore();
    await assertFails(hackerDb.collection('invitations').doc('empleado@test.com').get()); // No puede leerla
    await assertFails(
      hackerDb.collection('users').doc('hacker').set({
        id: 'hacker',
        email: 'hacker@test.com',
        dni: '',
        rol: 'employee',
        isActive: true,
        isDeleted: false,
        companyId: 'comp1',
        lugarDeTrabajoId: null,
        createdAt: new Date()
      })
    ); // No puede usarla
  });

  it('(2) una invitación se puede usar por el dueño (y borrar)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('invitations').doc('empleado@test.com').set({
        companyId: 'comp1',
        rol: 'employee'
      });
      await db.collection('companies').doc('comp1').set({ createdBy: 'admin123' });
    });

    // Email correcto y verificado
    const context = testEnv.authenticatedContext('uid1', { email: 'empleado@test.com', email_verified: true });
    const db = context.firestore();
    
    // Puede leer la invitación
    await assertSucceeds(db.collection('invitations').doc('empleado@test.com').get());
    
    // Puede crear su propio perfil usando los datos de la invitación
    await assertSucceeds(
      db.collection('users').doc('uid1').set({
        id: 'uid1',
        email: 'empleado@test.com',
        dni: '',
        rol: 'employee',
        isActive: true,
        isDeleted: false,
        companyId: 'comp1',
        lugarDeTrabajoId: null,
        createdAt: new Date()
      })
    );

    // Puede borrar la invitación (como si fuera un batch o tras crear el usuario)
    await assertSucceeds(db.collection('invitations').doc('empleado@test.com').delete());
  });

  it('(3) un usuario no puede unirse a una empresa sin invitación', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('companies').doc('comp1').set({ createdBy: 'admin123' });
    });

    // Intenta crearse un perfil como employee en comp1 sin tener invitación
    const context = testEnv.authenticatedContext('uid2', { email: 'otro@test.com', email_verified: true });
    const db = context.firestore();

    await assertFails(
      db.collection('users').doc('uid2').set({
        id: 'uid2',
        email: 'otro@test.com',
        dni: '',
        rol: 'employee',
        isActive: true,
        isDeleted: false,
        companyId: 'comp1',
        lugarDeTrabajoId: null,
        createdAt: new Date()
      })
    );
  });

  it('(4) un dueño solo puede crear su propia empresa', async () => {
    const context = testEnv.authenticatedContext('owner1');
    const db = context.firestore();

    // Puede crear su empresa con createdBy apuntando a su uid
    await assertSucceeds(
      db.collection('companies').doc('comp2').set({
        createdBy: 'owner1',
        name: 'My Company'
      })
    );

    // Luego puede crearse a sí mismo como admin en ESA empresa
    await assertSucceeds(
      db.collection('users').doc('owner1').set({
        id: 'owner1',
        email: 'owner@test.com',
        dni: '',
        rol: 'admin',
        isActive: true,
        isDeleted: false,
        companyId: 'comp2',
        lugarDeTrabajoId: null,
        createdAt: new Date()
      })
    );
    
    const hackerContext = testEnv.authenticatedContext('hacker');
    const hackerDb = hackerContext.firestore();

    // No puede crearse una empresa a nombre de otro
    await assertFails(
      hackerDb.collection('companies').doc('comp3').set({
        createdBy: 'owner1',
        name: 'Hacker Company'
      })
    );
    
    // No puede crearse como admin de comp2 (que no creó él)
    await assertFails(
      hackerDb.collection('users').doc('hacker').set({
        id: 'hacker',
        email: 'hacker@test.com',
        dni: '',
        rol: 'admin',
        isActive: true,
        isDeleted: false,
        companyId: 'comp2',
        lugarDeTrabajoId: null,
        createdAt: new Date()
      })
    );
  });
});
