'use strict';

const UCP_NAME_RE = /^[A-Za-z][A-Za-z0-9_]{1,29}[A-Za-z0-9]$/;
const CHARACTER_NAME_RE = /^[A-Za-z]{2,12}_[A-Za-z]{2,12}$/;
const BIRTHPLACE_RE = /^[A-Za-z][A-Za-z .,'-]{1,62}$/;
const DEFAULT_FIRST_SPAWN = Object.freeze({ x: 1687.3070, y: -2243.3049, z: 13.5469, angle: 90.0, interior: 0, virtualWorld: 0 });

function text(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function validBirthdate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    return false;
  }
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  return date <= today;
}

function validateRegistration(input, { requireUcpName = true } = {}) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return { ok: false, code: 'INVALID_REGISTRATION' };
  }

  const ucpName = text(input.ucpName);
  const characterName = text(input.characterName);
  const birthplace = text(input.birthplace);
  const birthdate = text(input.birthdate);
  const genderValue = text(input.gender).toLowerCase();
  const gender = genderValue === 'male' ? 'Male'
    : genderValue === 'female' ? 'Female' : '';

  if (requireUcpName && !UCP_NAME_RE.test(ucpName)) {
    return { ok: false, code: 'INVALID_REGISTRATION' };
  }
  if (!CHARACTER_NAME_RE.test(characterName) || characterName.length > 23
      || !BIRTHPLACE_RE.test(birthplace) || birthplace.length > 63
      || !validBirthdate(birthdate) || !gender) {
    return { ok: false, code: 'INVALID_REGISTRATION' };
  }

  return {
    ok: true,
    value: {
      ucpName: requireUcpName ? ucpName : null,
      characterName,
      birthplace,
      birthdate,
      gender,
      // Match the existing character schema defaults until gameplay supports editing them.
      height: 175,
      weight: 70,
    },
  };
}

module.exports = { validateRegistration, validBirthdate, DEFAULT_FIRST_SPAWN };
