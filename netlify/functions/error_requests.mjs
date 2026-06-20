const PB_BASE_URL = process.env.PB_BASE_URL || 'https://cropzcard.pockethost.io';
const PB_ERROR_REQUESTS_COLLECTION = process.env.PB_ERROR_REQUESTS_COLLECTION || 'Error Requests';
const PB_AUTH_TOKEN = process.env.PB_AUTH_TOKEN?.trim() || '';

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}

function toStringValue(value) {
  if (value === null || value === undefined) {
    return '';
  }
  return String(value).trim();
}

function normalizePayload(payload) {
  return {
    requester_name: toStringValue(payload?.requester_name),
    requester_email: toStringValue(payload?.requester_email),
    issue_type: toStringValue(payload?.issue_type),
    date_noticed: toStringValue(payload?.date_noticed),
    page_or_screen: toStringValue(payload?.page_or_screen),
    device_browser: toStringValue(payload?.device_browser),
    what_happened: toStringValue(payload?.what_happened),
    expected_result: toStringValue(payload?.expected_result),
    steps_tried: toStringValue(payload?.steps_tried),
    additional_details: toStringValue(payload?.additional_details),
    source_url: toStringValue(payload?.source_url),
    source_path: toStringValue(payload?.source_path),
    status: toStringValue(payload?.status) || 'open',
    source: toStringValue(payload?.source) || 'web',
  };
}

function missingRequiredFields(record) {
  const required = [
    'requester_name',
    'requester_email',
    'issue_type',
    'date_noticed',
    'page_or_screen',
    'device_browser',
    'what_happened',
  ];
  return required.filter((key) => !record[key]);
}

function normalizeCollectionName(value) {
  return String(value).trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

function collectionCandidates() {
  return [...new Set([
    PB_ERROR_REQUESTS_COLLECTION.trim(),
    normalizeCollectionName(PB_ERROR_REQUESTS_COLLECTION),
    'Error Requests',
    'error_requests',
  ].filter(Boolean))];
}

async function createPocketBaseRecordInCollection(record, collectionName) {
  const endpoint = `${PB_BASE_URL.replace(/\/+$/, '')}/api/collections/${encodeURIComponent(collectionName)}/records`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(PB_AUTH_TOKEN ? { Authorization: `Bearer ${PB_AUTH_TOKEN}` } : {}),
    },
    body: JSON.stringify(record),
  });

  const body = await response.text();

  if (!response.ok) {
    throw new Error(`pocketbase returned ${response.status} for collection "${collectionName}": ${body.trim()}`);
  }

  try {
    return JSON.parse(body);
  } catch (error) {
    throw new Error(`invalid pocketbase JSON: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function createPocketBaseRecord(record) {
  let lastError;
  for (const collectionName of collectionCandidates()) {
    try {
      return await createPocketBaseRecordInCollection(record, collectionName);
    } catch (error) {
      lastError = error;
      if (!String(error).includes('pocketbase returned 404')) {
        throw error;
      }
    }
  }
  throw lastError;
}

export default async function handler(req) {
  if (req.method === 'OPTIONS') {
    return jsonResponse(204, {});
  }

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'method not allowed' });
  }

  let payload;
  try {
    payload = await req.json();
  } catch (error) {
    return jsonResponse(400, { error: 'invalid JSON body' });
  }

  const record = normalizePayload(payload);
  const missing = missingRequiredFields(record);
  if (missing.length > 0) {
    return jsonResponse(400, {
      error: 'missing required fields',
      missing,
    });
  }

  try {
    const saved = await createPocketBaseRecord(record);
    return jsonResponse(201, saved);
  } catch (error) {
    return jsonResponse(202, {
      id: '',
      warning: 'Support draft will open, but automatic request saving is unavailable right now.',
    });
  }
}
