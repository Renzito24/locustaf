import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(join(__dirname, '..', '..', 'firestore.rules'), 'utf8');

const PROJECT_ID = 'locustaf-test';
const PORT = 8081;

let testEnv;

// ─── Helpers ────────────────────────────────────────────────────────────────

async function seedUser(uid, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`users/${uid}`).set({ ...data, id: uid });
  });
}

async function seedCompany(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`companies/${id}`).set({ ...data, id });
  });
}

async function seedAttendance(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`attendances/${id}`).set({ ...data, id });
  });
}

async function seedWorkplace(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`workplaces/${id}`).set({ ...data, id });
  });
}

async function seedIncidence(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`incidences/${id}`).set(data);
  });
}

async function seedMedicalDoc(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`medical_documents/${id}`).set(data);
  });
}

async function seedLock(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`_attendance_locks/${id}`).set(data);
  });
}

// ─── Setup / Teardown ───────────────────────────────────────────────────────

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: PORT,
      rules,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

// ─── Tests ──────────────────────────────────────────────────────────────────

describe('VUL-1: auto-alta con rol arbitrario', () => {
  it('un usuario en onboarding NO puede crearse con rol superadmin', async () => {
    const ctx = testEnv.authenticatedContext('new-user');
    await assertFails(
      ctx.firestore().doc('users/new-user').set({
        id: 'new-user',
        rol: 'superadmin',
        companyId: null,
        isActive: true,
        isDeleted: false,
      }),
    );
  });

  it('un usuario en onboarding NO puede reclamar una empresa existente', async () => {
    await seedCompany('emp-1', { nombreComercial: 'Empresa A', createdBy: 'otro-user' });
    const ctx = testEnv.authenticatedContext('new-user');
    await assertFails(
      ctx.firestore().doc('users/new-user').set({
        id: 'new-user',
        rol: 'admin',
        companyId: 'emp-1',
        isActive: true,
        isDeleted: false,
      }),
    );
  });

  it('un usuario en onboarding SÍ puede crearse como admin de una empresa que él creó', async () => {
    await seedCompany('emp-2', { nombreComercial: 'Empresa B', createdBy: 'new-user' });
    const ctx = testEnv.authenticatedContext('new-user');
    await assertSucceeds(
      ctx.firestore().doc('users/new-user').set({
        id: 'new-user',
        rol: 'admin',
        companyId: 'emp-2',
        isActive: true,
        isDeleted: false,
      }),
    );
  });
});

describe('VUL-3: campos server-only en asistencias', () => {
  it('un empleado NO puede modificar checkInTime', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: '2026-08-26T08:00:00.000',
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'active',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').update({
        checkInTime: '2026-08-26T07:00:00.000',
      }),
    );
  });

  it('un empleado SÍ puede hacer un check-out válido (active -> completed)', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: new Date('2026-08-26T08:00:00.000Z'),
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'active',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      ctx.firestore().doc('attendances/att-1').update({
        checkOutTime: new Date('2026-08-26T16:00:00.000Z'),
        status: 'completed',
        durationMinutes: 480,
      }),
    );
  });

  it('A1: un empleado NO puede completar una jornada sin fijar checkOutTime', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: new Date('2026-08-26T08:00:00.000Z'),
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'active',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').update({
        status: 'completed',
      }),
    );
  });

  it('A1: un empleado NO puede reabrir una jornada completada (completed -> active)', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: new Date('2026-08-26T08:00:00.000Z'),
      checkOutTime: new Date('2026-08-26T16:00:00.000Z'),
      durationMinutes: 480,
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'completed',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').update({
        status: 'active',
      }),
    );
  });

  it('A1: un empleado NO puede fijar durationMinutes arbitrarios', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: new Date('2026-08-26T08:00:00.000Z'),
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'active',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').update({
        checkOutTime: new Date('2026-08-26T16:00:00.000Z'),
        status: 'completed',
        durationMinutes: 999,
      }),
    );
  });

  it('A1: un empleado NO puede modificar un checkOutTime ya registrado', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: new Date('2026-08-26T08:00:00.000Z'),
      checkOutTime: new Date('2026-08-26T16:00:00.000Z'),
      durationMinutes: 480,
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'completed',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').update({
        checkOutTime: new Date('2026-08-26T09:00:00.000Z'),
      }),
    );
  });

  it('un empleado NO puede modificar workplaceId', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: '2026-08-26T08:00:00.000',
      date: '2026-08-26',
      isLate: false,
      workplaceId: 'wp-1',
      checkInLatitud: -34.6,
      checkInLongitud: -58.4,
      status: 'active',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').update({ workplaceId: 'wp-2' }),
    );
  });
});

describe('VUL-4: lectura de usuarios por rol', () => {
  it('un empleado SÍ puede leer su propio documento', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(ctx.firestore().doc('users/emp-1').get());
  });

  it('un empleado NO puede leer el documento de otro usuario', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-2', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(ctx.firestore().doc('users/emp-2').get());
  });

  it('un admin SÍ puede leer usuarios de su empresa', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(ctx.firestore().doc('users/emp-1').get());
  });

  it('un admin NO puede leer usuarios de otra empresa', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-2', { rol: 'employee', companyId: 'emp-2', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertFails(ctx.firestore().doc('users/emp-2').get());
  });
});

describe('VUL-4b: incidencias por rol', () => {
  it('un empleado SÍ puede leer su propia incidencia', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedIncidence('inc-1', { userId: 'emp-1', companyId: 'emp-1', estado: 'pendiente' });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(ctx.firestore().doc('incidences/inc-1').get());
  });

  it('un empleado NO puede leer la incidencia de otro', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedIncidence('inc-1', { userId: 'emp-2', companyId: 'emp-1', estado: 'pendiente' });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(ctx.firestore().doc('incidences/inc-1').get());
  });

  it('un empleado NO puede crear una incidencia auto-aprobada', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('incidences/inc-1').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        estado: 'aprobado',
      }),
    );
  });

  it('un empleado SÍ puede crear una incidencia en estado pendiente', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      ctx.firestore().doc('incidences/inc-1').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        estado: 'pendiente',
      }),
    );
  });
});

describe('M1: documentos médicos', () => {
  it('un empleado NO puede crear un documento médico auto-aprobado', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('medical_documents/doc-1').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        estado: 'aprobado',
      }),
    );
  });

  it('un empleado SÍ puede crear un documento médico en estado pendiente', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      ctx.firestore().doc('medical_documents/doc-1').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        estado: 'pendiente',
      }),
    );
  });

  it('un empleado NO puede leer el documento médico de otro', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedMedicalDoc('doc-1', { userId: 'emp-2', companyId: 'emp-1', estado: 'pendiente' });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(ctx.firestore().doc('medical_documents/doc-1').get());
  });
});

describe('VUL-2: locks con ownership', () => {
  it('un empleado NO puede tocar el lock de otro usuario', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedLock('emp-2', { attendanceId: 'att-1', status: 'active' });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(ctx.firestore().doc('_attendance_locks/emp-2').get());
  });

  it('un empleado SÍ puede tocar su propio lock', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedLock('emp-1', { attendanceId: 'att-1', status: 'active' });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(ctx.firestore().doc('_attendance_locks/emp-1').get());
  });
});

describe('VUL-3: create de asistencias con tolerancia', () => {
  it('un empleado SÍ puede crear su asistencia con checkInTime cerca de request.time', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedCompany('emp-1', { nombreComercial: 'Empresa A', toleranciaCheckIn: 60 });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      ctx.firestore().doc('attendances/att-ok').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        date: '2026-08-27',
        status: 'active',
        isLate: false,
        workplaceId: 'wp-1',
        checkInLatitud: -34.6,
        checkInLongitud: -58.4,
        checkInTime: new Date(Date.now() - 1000),
      }),
    );
  });

  it('un empleado NO puede crear una asistencia con checkInTime muy pasado (fuerza tolerancia)', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedCompany('emp-1', { nombreComercial: 'Empresa A', toleranciaCheckIn: 15 });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-rig').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        date: '2026-08-27',
        status: 'active',
        checkInTime: new Date(Date.now() - 60 * 60 * 1000),
      }),
    );
  });

  it('un empleado NO puede crear una asistencia con checkInTime en el futuro', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedCompany('emp-1', { nombreComercial: 'Empresa A', toleranciaCheckIn: 15 });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-future').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        date: '2026-08-27',
        status: 'active',
        checkInTime: new Date(Date.now() + 60 * 60 * 1000),
      }),
    );
  });

  it('un empleado NO puede crear una asistencia ya completada', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-completed').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        date: '2026-08-27',
        status: 'completed',
        checkInTime: new Date(Date.now() - 1000),
      }),
    );
  });

  it('un empleado NO puede crear una asistencia con durationMinutes predefinido', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedCompany('emp-1', { nombreComercial: 'Empresa A', toleranciaCheckIn: 60 });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-dur').set({
        userId: 'emp-1',
        companyId: 'emp-1',
        date: '2026-08-27',
        status: 'active',
        durationMinutes: 480,
        checkInTime: new Date(Date.now() - 1000),
      }),
    );
  });
});

describe('A1: asistencias - falsificar userId', () => {
  it('un empleado NO puede crear una asistencia para otro usuario', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedCompany('emp-1', { nombreComercial: 'Empresa A', toleranciaCheckIn: 60 });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').set({
        userId: 'emp-2',
        companyId: 'emp-1',
        checkInTime: new Date(Date.now() - 1000),
        status: 'active',
      }),
    );
  });

  it('un empleado NO puede crear una asistencia con companyId de otra empresa', async () => {
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('attendances/att-1').set({
        userId: 'emp-1',
        companyId: 'emp-2',
        checkInTime: new Date(Date.now() - 1000),
        status: 'active',
      }),
    );
  });
});

describe('E1: companyId null (IDOR)', () => {
  it('un usuario sin empresa NO puede leer asistencias ajenas', async () => {
    await seedUser('no-company', { rol: 'employee', companyId: null, isActive: true, isDeleted: false });
    await seedAttendance('att-1', {
      userId: 'emp-1',
      companyId: 'emp-1',
      checkInTime: '2026-08-26T08:00:00.000',
      status: 'active',
    });
    const ctx = testEnv.authenticatedContext('no-company');
    await assertFails(ctx.firestore().doc('attendances/att-1').get());
  });
});

describe('C2: updates de users (campo de identidad id)', () => {
  it('un admin SÍ puede editar los datos de un empleado (update parcial)', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(
      ctx.firestore().doc('users/emp-1').update({
        nombre: 'Nuevo',
        apellido: 'Nombre',
        updatedAt: '2026-08-30T12:00:00.000Z',
      }),
    );
  });

  it('un admin SÍ puede desactivar un empleado (isActive)', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(
      ctx.firestore().doc('users/emp-1').update({
        isActive: false,
        updatedAt: '2026-08-30T12:00:00.000Z',
      }),
    );
  });

  it('un admin SÍ puede hacer soft-delete de un empleado', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(
      ctx.firestore().doc('users/emp-1').update({
        isDeleted: true,
        updatedAt: '2026-08-30T12:00:00.000Z',
      }),
    );
  });

  it('un admin SÍ puede cambiar el rol de un empleado a supervisor', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(
      ctx.firestore().doc('users/emp-1').update({
        rol: 'supervisor',
      }),
    );
  });

  it('un empleado SÍ puede actualizar su propio perfil', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-1',
      email: 'emp1@locustaf.com',
      dni: '22222222',
      isActive: true,
      isDeleted: false,
      lugarDeTrabajoId: null,
      createdAt: '2026-08-01T00:00:00.000Z',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertSucceeds(
      ctx.firestore().doc('users/emp-1').update({
        nombre: 'Empleado',
        apellido: 'Actualizado',
        telefono: '+54 11 5555-0003',
      }),
    );
  });

  it('un empleado NO puede cambiar su propio rol', async () => {
    await seedUser('emp-1', {
      rol: 'employee',
      companyId: 'emp-1',
      email: 'emp1@locustaf.com',
      dni: '22222222',
      isActive: true,
      isDeleted: false,
      lugarDeTrabajoId: null,
      createdAt: '2026-08-01T00:00:00.000Z',
    });
    const ctx = testEnv.authenticatedContext('emp-1');
    await assertFails(
      ctx.firestore().doc('users/emp-1').update({
        rol: 'supervisor',
      }),
    );
  });
});

describe('C1: escalada de rol (admin -> superadmin)', () => {
  it('un admin NO puede escalar su propio rol a superadmin', async () => {
    await seedUser('admin-1', {
      rol: 'admin',
      companyId: 'emp-1',
      email: 'admin@locustaf.com',
      dni: '00000000',
      isActive: true,
      isDeleted: false,
      lugarDeTrabajoId: null,
      createdAt: '2026-08-01T00:00:00.000Z',
    });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertFails(
      ctx.firestore().doc('users/admin-1').update({
        rol: 'superadmin',
      }),
    );
  });

  it('un admin NO puede asignar rol superadmin a un empleado', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertFails(
      ctx.firestore().doc('users/emp-1').update({
        rol: 'superadmin',
      }),
    );
  });

  it('un admin NO puede asignar rol admin a un empleado', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertFails(
      ctx.firestore().doc('users/emp-1').update({
        rol: 'admin',
      }),
    );
  });

  it('un admin NO puede modificar el documento de otro admin', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedUser('admin-2', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertFails(
      ctx.firestore().doc('users/admin-2').update({
        nombre: 'Intruso',
      }),
    );
  });

  it('un superadmin SÍ puede cambiar el rol de un usuario', async () => {
    await seedUser('superadmin-1', { rol: 'superadmin', companyId: null, isActive: true, isDeleted: false });
    await seedUser('emp-1', { rol: 'employee', companyId: 'emp-1', isActive: true, isDeleted: false });
    const ctx = testEnv.authenticatedContext('superadmin-1');
    await assertSucceeds(
      ctx.firestore().doc('users/emp-1').update({
        rol: 'supervisor',
      }),
    );
  });
});

describe('C2: updates de workplaces (campo de identidad id)', () => {
  it('un admin SÍ puede editar un lugar de trabajo (update parcial)', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedWorkplace('wp-1', { nombre: 'Sucursal Central', companyId: 'emp-1', isActive: true });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(
      ctx.firestore().doc('workplaces/wp-1').update({
        nombre: 'Sucursal Norte',
      }),
    );
  });

  it('un admin SÍ puede desactivar un lugar de trabajo', async () => {
    await seedUser('admin-1', { rol: 'admin', companyId: 'emp-1', isActive: true, isDeleted: false });
    await seedWorkplace('wp-1', { nombre: 'Sucursal Central', companyId: 'emp-1', isActive: true });
    const ctx = testEnv.authenticatedContext('admin-1');
    await assertSucceeds(
      ctx.firestore().doc('workplaces/wp-1').update({
        isActive: false,
        updatedAt: '2026-08-30T12:00:00.000Z',
      }),
    );
  });
});

describe('C3: onboarding - alta secuencial de empresa y admin', () => {
  it('un usuario en onboarding SÍ puede crear su empresa y luego su documento admin', async () => {
    // Nota: se usa un contexto autenticado por escritura para evitar el error
    // del SDK "Firestore has already been started" al reutilizar la instancia.
    const ctx1 = testEnv.authenticatedContext('new-user');
    await assertSucceeds(
      ctx1.firestore().doc('companies/emp-9').set({
        id: 'emp-9',
        nombreComercial: 'Empresa Nueva',
        createdBy: 'new-user',
      }),
    );
    const ctx2 = testEnv.authenticatedContext('new-user');
    await assertSucceeds(
      ctx2.firestore().doc('users/new-user').set({
        id: 'new-user',
        rol: 'admin',
        companyId: 'emp-9',
        isActive: true,
        isDeleted: false,
        createdAt: '2026-08-30T00:00:00.000Z',
      }),
    );
  });

  it('un usuario en onboarding SÍ puede eliminar una empresa huérfana que creó', async () => {
    await seedCompany('emp-9', { nombreComercial: 'Empresa Nueva', createdBy: 'new-user' });
    const ctx = testEnv.authenticatedContext('new-user');
    await assertSucceeds(ctx.firestore().doc('companies/emp-9').delete());
  });

  it('un usuario en onboarding NO puede eliminar una empresa que no creó', async () => {
    await seedCompany('emp-9', { nombreComercial: 'Empresa A', createdBy: 'otro-user' });
    const ctx = testEnv.authenticatedContext('new-user');
    await assertFails(ctx.firestore().doc('companies/emp-9').delete());
  });
});
