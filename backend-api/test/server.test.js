'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

process.env.GOOGLE_CLIENT_ID = '';
process.env.GOOGLE_WEB_CLIENT_ID = '';
process.env.DB_HOST = '';
process.env.DB_USER = '';
process.env.DB_PASS = '';
process.env.DB_NAME = '';

const app = require('../server');

test('health endpoint reports service without exposing configuration', async (t) => {
  const server = app.listen(0, '127.0.0.1');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const address = server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}/`);
  const body = await response.json();
  assert.equal(response.status, 200);
  assert.equal(body.status, 'online');
  assert.equal(body.nativeAuthReady, false);
  assert.ok(!JSON.stringify(body).includes('YOUR_'));
});

test('legacy CEF OAuth endpoints are permanently disabled', async (t) => {
  const server = app.listen(0, '127.0.0.1');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const address = server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}/auth/google`);
  const body = await response.json();
  assert.equal(response.status, 410);
  assert.equal(body.code, 'LEGACY_CEF_AUTH_DISABLED');
});

test('native login fails closed if its server client ID is missing', async (t) => {
  const server = app.listen(0, '127.0.0.1');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const address = server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}/auth/google/mobile`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ idToken: 'x'.repeat(200), nonce: 'n'.repeat(43) }),
  });
  const body = await response.json();
  assert.equal(response.status, 503);
  assert.equal(body.code, 'GOOGLE_CLIENT_NOT_CONFIGURED');
});
