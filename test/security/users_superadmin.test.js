import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'locustaf-test',
    firestore: {
      rules: readFileSync('../../firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    // Create base data
    await db.collection('companies').doc('c1').set({ id: 'c1', createdBy: 'admin1' });
    await db.collection('companies').doc('c2').set({ id: 'c2', createdBy: 'admin2' });

    await db.collection('users').doc('user1').set({
      id: 'user1',
      rol: 'employee',
      companyId: 'c1',
      isActive: true,
      isDeleted: false,
      email: 'user@test.com',
      dni: '11111111',
      lugarDeTrabajoId: 'w1',
      createdAt: '2026-09-28T00:00:00.000Z'
    });

    await db.collection('users').doc('admin1').set({
      id: 'admin1',
      rol: 'admin',
      companyId: 'c1',
      isActive: true,
      isDeleted: false,
      email: 'admin@test.com',
      dni: '22222222',
      lugarDeTrabajoId: 'w1',
      createdAt: '2026-09-28T00:00:00.000Z'
    });

    await db.collection('users').doc('super1').set({
      id: 'super1',
      rol: 'superadmin',
      companyId: 'c1',
      isActive: true,
      isDeleted: false,
      email: 'super@test.com',
      dni: '33333333',
      lugarDeTrabajoId: 'w1',
      createdAt: '2026-09-28T00:00:00.000Z'
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('Users Security Rules for Superadmin and Roles', () => {
  
  it('(1) Un usuario NO puede cambiar su propio rol ni su companyId', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    const userRef = db.collection('users').doc('user1');
    
    // Change role
    await assertFails(userRef.update({ rol: 'admin' }));
    // Change companyId
    await assertFails(userRef.update({ companyId: 'c2' }));
    
    // Changing un-restricted fields should succeed
    await assertSucceeds(userRef.update({ nombre: 'Nuevo Nombre' }));
  });

  it('(2) Un admin NO puede asignar rol superadmin a nadie', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    const employeeRef = db.collection('users').doc('user1');
    
    // Admin trying to upgrade employee to superadmin
    await assertFails(employeeRef.update({ rol: 'superadmin' }));
    // Admin trying to upgrade employee to admin
    await assertFails(employeeRef.update({ rol: 'admin' }));
    // Admin upgrading employee to supervisor should succeed
    await assertSucceeds(employeeRef.update({ rol: 'supervisor' }));
  });

  it('(3) Un admin NO puede mover un usuario a otra empresa', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    const employeeRef = db.collection('users').doc('user1');
    
    await assertFails(employeeRef.update({ companyId: 'c2' }));
  });

  it('(4) Un usuario en onboarding (sin empresa) NO puede crearse con el companyId de una empresa existente si no la creó él', async () => {
    const db = testEnv.authenticatedContext('new_user').firestore();
    const userRef = db.collection('users').doc('new_user');
    
    // Trying to create himself inside c1
    await assertFails(userRef.set({
      id: 'new_user',
      rol: 'admin',
      companyId: 'c1', // existing company created by admin1
    }));
  });

  it('(5a) Un superadmin puede asignar rol superadmin', async () => {
    const db = testEnv.authenticatedContext('super1').firestore();
    const employeeRef = db.collection('users').doc('user1');

    await assertSucceeds(employeeRef.update({ rol: 'superadmin' }));
  });

  it('(5b) Un superadmin NO puede cambiar el companyId de un usuario existente (regla estricta identity)', async () => {
    const db = testEnv.authenticatedContext('super1').firestore();
    const employeeRef = db.collection('users').doc('user1');

    await assertFails(employeeRef.update({ companyId: 'c2' }));
  });

  it('(5c) Un superadmin puede crear un usuario con cualquier empresa', async () => {
    const db = testEnv.authenticatedContext('super1').firestore();
    const newUserRef = db.collection('users').doc('new_user');

    await assertSucceeds(newUserRef.set({
      id: 'new_user',
      rol: 'admin',
      companyId: 'c1'
    }));
  });
});
