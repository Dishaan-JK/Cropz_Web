import path from 'node:path';

const PB_BASE_URL = process.env.PB_BASE_URL || 'https://cropzcard.pockethost.io';
const PB_CARDS_COLLECTION = process.env.PB_CARDS_COLLECTION || 'cards';
const PB_AUTH_TOKEN = process.env.PB_AUTH_TOKEN?.trim() || '';

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}

function getObject(root, key) {
  const value = root?.[key];
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function getArray(root, key) {
  const value = root?.[key];
  return Array.isArray(value) ? value : [];
}

function toStringValue(value) {
  if (value === null || value === undefined) {
    return '';
  }
  return String(value).trim();
}

function mapToStringObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(value).map(([key, raw]) => [key, toStringValue(raw)]),
  );
}

function mimeTypeForFileName(fileName) {
  switch (path.extname(fileName).toLowerCase()) {
    case '.pdf':
      return 'application/pdf';
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}

function normalizePayload(cardId, payload) {
  const profile = getObject(payload, 'profile');
  const banks = getArray(payload, 'bank_infos');
  const addresses = getArray(payload, 'addresses');
  const documents = getArray(payload, 'documents');

  const bankAccounts = banks
    .map(mapToStringObject)
    .filter((bank) => Object.keys(bank).length > 0)
    .map((bank) => ({
      bankName: bank.bank_name || '',
      accountNumber: bank.account_no || '',
      ifsc: bank.ifsc_code || '',
      branch: bank.branch || '',
      holderName: bank.account_holder_name || '',
      accountType: bank.account_type || '',
    }));

  const address = addresses.length > 0
    ? (() => {
        const first = mapToStringObject(addresses[0]);
        return {
          type: first.address_type || '',
          line1: first.address1 || '',
          line2: first.address2 || '',
          line3: first.address3 || '',
          city: first.city || '',
          district: first.district || '',
          state: first.state || '',
          pincode: first.pincode || '',
        };
      })()
    : {
        type: '',
        line1: '',
        line2: '',
        line3: '',
        city: '',
        district: '',
        state: '',
        pincode: '',
      };

  const documentItems = documents
    .map(mapToStringObject)
    .filter((doc) => Object.keys(doc).length > 0)
    .map((doc) => {
      const label = toStringValue(doc.label);
      const fileName = toStringValue(doc.file_name);
      const base64Data = toStringValue(doc.base64_data);
      if (!label || !fileName || !base64Data) {
        return null;
      }
      const mimeType = toStringValue(doc.mime_type) || mimeTypeForFileName(fileName);
      return {
        label,
        fileName,
        mimeType,
        downloadUrl: `data:${mimeType};base64,${base64Data}`,
      };
    })
    .filter(Boolean);

  return {
    cardId,
    profile: {
      name: toStringValue(profile.firm_name),
      role: 'Cropz User',
      phone: toStringValue(profile.mobile),
      email: toStringValue(profile.email),
      avatarUrl: toStringValue(profile.profile_picture),
    },
    digitalBusinessCard: {
      firmName: toStringValue(profile.firm_name),
      ownerName: toStringValue(profile.owner_name),
      whatsapp: toStringValue(profile.whatsapp),
      upiId: toStringValue(profile.upi_id),
      transport: toStringValue(profile.transport),
      companies: toStringValue(profile.companies),
      recordId: cardId,
    },
    business: {
      businessName: toStringValue(profile.firm_name),
      ownerName: toStringValue(profile.owner_name),
      mobile: toStringValue(profile.mobile),
      gst: toStringValue(profile.gst_no),
    },
    licenseInfo: {
      slNo: toStringValue(profile.sl_no),
      slExpiryDate: toStringValue(profile.sl_expiry_date),
      plNo: toStringValue(profile.pl_no),
      retailFlNo: toStringValue(profile.retail_fl_no),
      retailFlExpiryDate: toStringValue(profile.retail_fl_expiry_date),
      wsFlNo: toStringValue(profile.ws_fl_no),
      wsFlExpiryDate: toStringValue(profile.ws_fl_expiry_date),
      fmsRetailId: toStringValue(profile.fms_retail_id),
      fmsWsId: toStringValue(profile.fms_ws_id),
    },
    bankAccounts,
    address,
    documents: documentItems,
  };
}

async function fetchPocketBaseRecord(cardId) {
  const collection = encodeURIComponent(PB_CARDS_COLLECTION);
  const recordId = encodeURIComponent(cardId);
  const endpoint = `${PB_BASE_URL.replace(/\/+$/, '')}/api/collections/${collection}/records/${recordId}`;

  const response = await fetch(endpoint, {
    headers: {
      Accept: 'application/json',
      ...(PB_AUTH_TOKEN ? { Authorization: `Bearer ${PB_AUTH_TOKEN}` } : {}),
    },
  });

  const body = await response.text();

  if (!response.ok) {
    throw new Error(`pocketbase returned ${response.status}: ${body.trim()}`);
  }

  try {
    return JSON.parse(body);
  } catch (error) {
    throw new Error(`invalid pocketbase JSON: ${error instanceof Error ? error.message : String(error)}`);
  }
}

function extractPayload(record) {
  const payloadJson = record?.payload_json;

  if (payloadJson == null) {
    throw new Error('cards record missing payload_json');
  }

  if (typeof payloadJson === 'object' && !Array.isArray(payloadJson)) {
    return payloadJson;
  }

  if (typeof payloadJson === 'string') {
    try {
      return JSON.parse(payloadJson);
    } catch (error) {
      throw new Error(
        `payload_json string is not valid JSON: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  throw new Error('unsupported payload_json type');
}

export default async function handler(req, context) {
  if (req.method === 'OPTIONS') {
    return jsonResponse(204, {});
  }

  if (req.method !== 'GET') {
    return jsonResponse(405, { error: 'method not allowed' });
  }

  const cardId = context?.params?.cardId || '';
  if (!cardId || cardId.includes('/')) {
    return jsonResponse(400, { error: 'invalid cardId' });
  }

  try {
    const record = await fetchPocketBaseRecord(cardId);
    const payload = extractPayload(record);
    return jsonResponse(200, normalizePayload(cardId, payload));
  } catch (error) {
    return jsonResponse(502, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export const config = {
  path: '/api/cards/:cardId',
};
