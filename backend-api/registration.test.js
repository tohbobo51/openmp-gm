'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { validateRegistration } = require('./registration');

const validInput = {
  ucpName: 'Player_UCP1',
  characterName: 'Alex_Rivera',
  birthplace: 'United States of America',
  birthdate: '1995-06-15',
  gender: 'Male',
  height: 178,
  weight: 74,
};

test('accepts a complete registration and preserves entered height and weight', () => {
  const result = validateRegistration(validInput);
  assert.equal(result.ok, true);
  assert.equal(result.value.height, 178);
  assert.equal(result.value.weight, 74);
  assert.equal(result.value.birthplace, 'United States of America');
});

test('requires height and weight', () => {
  const { height: _height, weight: _weight, ...missingMeasurements } = validInput;
  assert.deepEqual(validateRegistration(missingMeasurements), {
    ok: false,
    code: 'INVALID_REGISTRATION',
  });
});

test('rejects non-integer and out-of-range measurements', () => {
  for (const override of [
    { height: 175.5 },
    { height: 79 },
    { height: 251 },
    { weight: 19 },
    { weight: 301 },
    { weight: 'unknown' },
  ]) {
    assert.equal(validateRegistration({ ...validInput, ...override }).ok, false);
  }
});

test('allows character registration without a UCP field while requiring all profile data', () => {
  const { ucpName: _ucpName, ...characterRegistration } = validInput;
  assert.equal(validateRegistration(characterRegistration, { requireUcpName: false }).ok, true);
  assert.equal(validateRegistration(characterRegistration, { requireUcpName: true }).ok, false);
});
