const test = require('node:test');
const assert = require('node:assert');

const { computeUserAuthUpdate } = require('../userStatus');

test('computa sin cambios cuando el estado de deshabilitación no cambia', () => {
  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: true, isDeleted: false },
      { isActive: true, isDeleted: false },
    ),
    { update: false },
  );

  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: false, isDeleted: false },
      { isActive: false, isDeleted: false },
    ),
    { update: false },
  );

  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: true, isDeleted: true },
      { isActive: true, isDeleted: true },
    ),
    { update: false },
  );
});

test('deshabilita la cuenta cuando el usuario se marca como eliminado', () => {
  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: true, isDeleted: false },
      { isActive: true, isDeleted: true },
    ),
    { update: true, disabled: true },
  );
});

test('deshabilita la cuenta cuando el usuario se desactiva', () => {
  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: true, isDeleted: false },
      { isActive: false, isDeleted: false },
    ),
    { update: true, disabled: true },
  );
});

test('habilita la cuenta cuando el usuario se reactiva o des-elimina', () => {
  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: false, isDeleted: false },
      { isActive: true, isDeleted: false },
    ),
    { update: true, disabled: false },
  );

  assert.deepStrictEqual(
    computeUserAuthUpdate(
      { isActive: true, isDeleted: true },
      { isActive: true, isDeleted: false },
    ),
    { update: true, disabled: false },
  );
});

test('no hace nada sin datos previos o posteriores', () => {
  assert.deepStrictEqual(computeUserAuthUpdate(null, { isActive: true }), {
    update: false,
  });
  assert.deepStrictEqual(computeUserAuthUpdate({ isActive: true }, null), {
    update: false,
  });
  assert.deepStrictEqual(computeUserAuthUpdate(null, null), { update: false });
});