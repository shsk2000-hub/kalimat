import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const projectId = 'kalimat-shsk2000';

async function getAccessToken() {
  const configPath = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  const refreshToken = config.tokens?.refresh_token;
  if (!refreshToken) {
    throw new Error('Firebase CLI is not logged in. Run: firebase login');
  }

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
      client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  });

  if (!response.ok) {
    throw new Error(`Token refresh failed: ${await response.text()}`);
  }

  const data = await response.json();
  return data.access_token;
}

async function enableApi(accessToken, service) {
  const response = await fetch(
    `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/${service}:enable`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${accessToken}` },
    },
  );

  if (!response.ok) {
    const body = await response.text();
    if (!body.includes('ALREADY_ENABLED')) {
      console.warn(`Enable ${service}:`, body);
    }
  } else {
    console.log(`Enabled ${service}`);
  }
}

async function ensureFirestore(accessToken) {
  await enableApi(accessToken, 'firestore.googleapis.com');
  await new Promise((resolve) => setTimeout(resolve, 8000));

  const createResponse = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases?databaseId=(default)`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ locationId: 'eur3', type: 'FIRESTORE_NATIVE' }),
    },
  );

  const body = await createResponse.text();
  console.log('Firestore create:', createResponse.status, body);
  if (createResponse.ok) {
    return 'firestore';
  }
  if (body.includes('ALREADY_EXISTS')) {
    return 'firestore';
  }
  return null;
}

async function ensureRealtimeDatabase(accessToken) {
  await enableApi(accessToken, 'firebasedatabase.googleapis.com');

  const listResponse = await fetch(
    `https://firebasedatabase.googleapis.com/v1beta/projects/${projectId}/locations/-/instances`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );

  const list = await listResponse.json();
  console.log('Instances:', JSON.stringify(list, null, 2));

  const existing = (list.instances ?? [])[0];
  if (existing?.databaseUrl) {
    console.log('Using existing database:', existing.databaseUrl);
    return existing.databaseUrl;
  }

  for (const location of ['us-central1', 'europe-west1']) {
    for (const databaseId of ['default', `${projectId}-default-rtdb`]) {
      const createResponse = await fetch(
        `https://firebasedatabase.googleapis.com/v1beta/projects/${projectId}/locations/${location}/instances?databaseId=${databaseId}`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ type: 'USER_DATABASE' }),
        },
      );

      const body = await createResponse.text();
      console.log(`Try ${location}/${databaseId}:`, createResponse.status, body);
      if (createResponse.ok) {
        const created = JSON.parse(body);
        return created.databaseUrl;
      }
    }
  }

  throw new Error('Could not create Realtime Database automatically');
}

const accessToken = await getAccessToken();
const firestore = await ensureFirestore(accessToken);
if (firestore) {
  console.log('READY firestore');
} else {
  const databaseUrl = await ensureRealtimeDatabase(accessToken);
  console.log('READY', databaseUrl);
}
