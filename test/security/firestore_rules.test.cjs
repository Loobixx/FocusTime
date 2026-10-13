const assert = require('node:assert/strict');
const { test } = require('node:test');

const projectId = 'demo-focustime';
const authUrl =
  'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key';
const documentUrl = (path) =>
  `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents/${path}`;

async function createTestUser(email) {
  const response = await fetch(authUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password: 'test-password-123',
      returnSecureToken: true,
    }),
  });
  const payload = await response.json();
  assert.equal(response.status, 200, JSON.stringify(payload));
  return payload;
}

async function verifyEmail(email, idToken) {
  const sendCode = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=fake-api-key',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requestType: 'VERIFY_EMAIL', idToken }),
    },
  );
  assert.equal(sendCode.status, 200, await sendCode.text());

  const codesResponse = await fetch(
    `http://127.0.0.1:9099/emulator/v1/projects/${projectId}/oobCodes`,
  );
  const { oobCodes } = await codesResponse.json();
  const code = oobCodes.find(
    (candidate) =>
      candidate.email === email && candidate.requestType === 'VERIFY_EMAIL',
  );
  assert.ok(code, `No verification code for ${email}`);

  const response = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:update?key=fake-api-key',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ oobCode: code.oobCode, returnSecureToken: true }),
    },
  );
  const payload = await response.json();
  assert.equal(response.status, 200, JSON.stringify(payload));
  assert.equal(payload.emailVerified, true);
  assert.equal(payload.email, email, JSON.stringify(payload));

  const signIn = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password: 'test-password-123',
        returnSecureToken: true,
      }),
    },
  );
  const signedInUser = await signIn.json();
  assert.equal(signIn.status, 200, JSON.stringify(signedInUser));
  const tokenClaims = JSON.parse(
    Buffer.from(signedInUser.idToken.split('.')[1], 'base64url').toString(),
  );
  assert.equal(tokenClaims.email_verified, true);
  return signedInUser.idToken;
}

async function writeDocument(path, idToken) {
  return fetch(documentUrl(path), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}),
    },
    body: JSON.stringify({
      fields: { value: { stringValue: 'security-test' } },
    }),
  });
}

async function writeAdminStatus(path, enabled, idToken) {
  return fetch(documentUrl(path), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({
      fields: { enabled: { booleanValue: enabled } },
    }),
  });
}

test('Firestore data is private to the authenticated owner', async () => {
  const owner = await createTestUser('unprivileged@example.com');
  const ownerDocumentPath = `users/${owner.localId}`;
  const ownerPath = `users/${owner.localId}/stopped_cities/test-city`;

  const ownProfileWrite = await writeDocument(ownerDocumentPath, owner.idToken);
  assert.equal(ownProfileWrite.status, 200, await ownProfileWrite.text());

  const ownProfileRead = await fetch(documentUrl(ownerDocumentPath), {
    headers: { Authorization: `Bearer ${owner.idToken}` },
  });
  assert.equal(ownProfileRead.status, 200, await ownProfileRead.text());

  const ownWrite = await writeDocument(ownerPath, owner.idToken);
  assert.equal(ownWrite.status, 200, await ownWrite.text());

  const ownRead = await fetch(documentUrl(ownerPath), {
    headers: { Authorization: `Bearer ${owner.idToken}` },
  });
  assert.equal(ownRead.status, 200, await ownRead.text());

  const otherUserRead = await fetch(
    documentUrl('users/different-user/stopped_cities/test-city'),
    { headers: { Authorization: `Bearer ${owner.idToken}` } },
  );
  assert.equal(otherUserRead.status, 403, await otherUserRead.text());

  const otherProfileRead = await fetch(
    documentUrl('users/different-user'),
    { headers: { Authorization: `Bearer ${owner.idToken}` } },
  );
  assert.equal(otherProfileRead.status, 403, await otherProfileRead.text());

  const otherUserWrite = await writeDocument(
    'users/different-user/stopped_cities/test-city',
    owner.idToken,
  );
  assert.equal(otherUserWrite.status, 403, await otherUserWrite.text());

  const anonymousWrite = await writeDocument(ownerPath);
  assert.equal(anonymousWrite.status, 403, await anonymousWrite.text());

  const unlistedCollectionWrite = await writeDocument(
    'private-data/security-test',
    owner.idToken,
  );
  assert.equal(unlistedCollectionWrite.status, 403, await unlistedCollectionWrite.text());

  const selfAdminGrant = await writeDocument(
    `admin_emails/${owner.email}`,
    owner.idToken,
  );
  assert.equal(selfAdminGrant.status, 403, await selfAdminGrant.text());

  const adminList = await fetch(documentUrl('admin_emails'), {
    headers: { Authorization: `Bearer ${owner.idToken}` },
  });
  assert.equal(adminList.status, 403, await adminList.text());

  const cleanup = await fetch(documentUrl(ownerPath), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${owner.idToken}` },
  });
  assert.equal(cleanup.status, 200, await cleanup.text());
});

test('only verified emails on the server-managed allowlist get admin access', async () => {
  const adminEmail = 'yoprudhomme59@gmail.com';
  const admin = await createTestUser(adminEmail);
  const otherUser = await createTestUser('another-user@example.com');
  const otherProfilePath = `users/${otherUser.localId}`;

  const profile = await writeDocument(otherProfilePath, otherUser.idToken);
  assert.equal(profile.status, 200, await profile.text());

  const adminDocumentPath = `admin_emails/${encodeURIComponent(adminEmail)}`;
  const allowlistSetup = await fetch(documentUrl(adminDocumentPath), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer owner',
    },
    body: JSON.stringify({ fields: { enabled: { booleanValue: true } } }),
  });
  assert.equal(allowlistSetup.status, 200, await allowlistSetup.text());

  const beforeVerification = await fetch(documentUrl(otherProfilePath), {
    headers: { Authorization: `Bearer ${admin.idToken}` },
  });
  assert.equal(beforeVerification.status, 403, await beforeVerification.text());

  const verifiedAdminToken = await verifyEmail(adminEmail, admin.idToken);
  const adminProfileRead = await fetch(documentUrl(otherProfilePath), {
    headers: { Authorization: `Bearer ${verifiedAdminToken}` },
  });
  assert.equal(adminProfileRead.status, 200, await adminProfileRead.text());

  const adminProfileWrite = await writeDocument(
    otherProfilePath,
    verifiedAdminToken,
  );
  assert.equal(adminProfileWrite.status, 200, await adminProfileWrite.text());

  const adminAllowlistRead = await fetch(
    documentUrl(adminDocumentPath),
    { headers: { Authorization: `Bearer ${verifiedAdminToken}` } },
  );
  assert.equal(adminAllowlistRead.status, 200, await adminAllowlistRead.text());

  const adminList = await fetch(documentUrl('admin_emails'), {
    headers: { Authorization: `Bearer ${verifiedAdminToken}` },
  });
  assert.equal(adminList.status, 200, await adminList.text());

  const selfStatusChange = await writeAdminStatus(
    adminDocumentPath,
    false,
    verifiedAdminToken,
  );
  assert.equal(selfStatusChange.status, 403, await selfStatusChange.text());

  const selfGrantAttempt = await writeAdminStatus(
    `admin_emails/${encodeURIComponent(adminEmail)}`,
    true,
    verifiedAdminToken,
  );
  assert.equal(selfGrantAttempt.status, 403, await selfGrantAttempt.text());

  const newAdminPath = 'admin_emails/new-admin@example.com';
  const grantAnotherAdmin = await writeAdminStatus(
    newAdminPath,
    true,
    verifiedAdminToken,
  );
  assert.equal(grantAnotherAdmin.status, 200, await grantAnotherAdmin.text());

  const revokeAnotherAdmin = await writeAdminStatus(
    newAdminPath,
    false,
    verifiedAdminToken,
  );
  assert.equal(revokeAnotherAdmin.status, 200, await revokeAnotherAdmin.text());

  const clientGrantAttempt = await writeDocument(
    'admin_emails/new-admin@example.com',
    verifiedAdminToken,
  );
  assert.equal(clientGrantAttempt.status, 403, await clientGrantAttempt.text());
});
