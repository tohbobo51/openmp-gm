'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { validateRegistration, validBirthdate } = require('../registration');

const valid = {
  ucpName: 'Budi_Online',
  characterName: 'Budi_Santoso',
  birthplace: 'Jakarta',
  birthdate: '1998-05-14',
  gender: 'Male',
};

test('accepts valid first-account registration and applies character defaults', () => {
  const result = validateRegistration(valid);
  assert.equal(result.ok, true);
  assert.equal(result.value.ucpName, 'Budi_Online');
  assert.equal(result.value.gender, 'Male');
  assert.equal(result.value.height, 175);
  assert.equal(result.value.weight, 70);
});

test('accepts character-only registration for an existing UCP account', () => {
  const result = validateRegistration({ ...valid, ucpName: '' }, { requireUcpName: false });
  assert.equal(result.ok, true);
  assert.equal(result.value.ucpName, null);
});

test('rejects unsafe or incompatible names and missing profile fields', () => {
  assert.equal(validateRegistration({ ...valid, ucpName: 'x' }).code, 'INVALID_REGISTRATION');
  assert.equal(validateRegistration({ ...valid, characterName: 'not a valid name' }).code, 'INVALID_REGISTRATION');
  assert.equal(validateRegistration({ ...valid, birthplace: '   ' }).code, 'INVALID_REGISTRATION');
  assert.equal(validateRegistration({ ...valid, gender: 'Other' }).code, 'INVALID_REGISTRATION');
});

test('rejects impossible and future birthdates', () => {
  assert.equal(validBirthdate('2001-02-29'), false);
  assert.equal(validBirthdate('2999-01-01'), false);
  assert.equal(validBirthdate('2000-02-29'), true);
});
