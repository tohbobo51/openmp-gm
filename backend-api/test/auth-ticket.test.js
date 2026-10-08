'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {
  createGameTicket,
  sha256Hex,
  isGoogleNonce,
  isGameTicket,
  TICKET_LENGTH,
  TICKET_ALPHABET,
} = require('../auth-ticket');

test('creates a 16-character game-compatible ticket from 80 random bits', () => {
  const ticket = createGameTicket((length) => Buffer.alloc(length, 0));
  assert.equal(ticket, 'A'.repeat(TICKET_LENGTH));
  assert.match(ticket, /^[A-HJ-NP-Z2-9]{16}$/);
  assert.equal(TICKET_ALPHABET.length, 32);
});

test('ticket generator has no modulo bias and produces allowed symbols', () => {
  const bytes = Buffer.from(Array.from({ length: TICKET_LENGTH }, (_, index) => index));
  const ticket = createGameTicket(() => bytes);
  assert.equal(ticket, TICKET_ALPHABET.slice(0, TICKET_LENGTH));
  assert.ok(isGameTicket(ticket));
  assert.ok(!isGameTicket('AUTH' + ticket));
  assert.ok(!isGameTicket('O'.repeat(TICKET_LENGTH)));
});

test('hashes secrets as lowercase SHA-256 hex and accepts only URL-safe nonce strings', () => {
  const actual = sha256Hex('temporary-test-value');
  const expected = crypto.createHash('sha256').update('temporary-test-value', 'utf8').digest('hex');
  assert.equal(actual, expected);
  assert.match(actual, /^[0-9a-f]{64}$/);
  assert.ok(isGoogleNonce('a'.repeat(43)));
  assert.ok(!isGoogleNonce('short'));
  assert.ok(!isGoogleNonce('a'.repeat(42) + '='));
});
