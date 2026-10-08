'use strict';

const crypto = require('node:crypto');

// Exactly 32 symbols, so masking each random byte with 0x1f has no modulo bias.
const TICKET_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const TICKET_LENGTH = 16;

function createGameTicket(randomBytes = crypto.randomBytes) {
  const bytes = randomBytes(TICKET_LENGTH);
  if (!bytes || bytes.length !== TICKET_LENGTH) {
    throw new TypeError('randomBytes must return exactly 16 bytes');
  }
  let ticket = '';
  for (let i = 0; i < bytes.length; i += 1) {
    ticket += TICKET_ALPHABET[bytes[i] & 0x1f];
  }
  return ticket;
}

function sha256Hex(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function isGoogleNonce(value) {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{32,128}$/.test(value);
}

function isGameTicket(value) {
  return typeof value === 'string'
    && new RegExp(`^[${TICKET_ALPHABET}]{${TICKET_LENGTH}}$`).test(value);
}

module.exports = {
  createGameTicket,
  sha256Hex,
  isGoogleNonce,
  isGameTicket,
  TICKET_LENGTH,
  TICKET_ALPHABET,
};
