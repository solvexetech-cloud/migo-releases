// admin/src/utils/demandNormalizer.js
// ------------------------------------------------------------
// MIGO Demand Normalizer
// കസ്റ്റമർ ടൈപ്പ് ചെയ്യുന്ന ഡിമാൻഡ് ടെക്സ്റ്റിൽ നിന്ന് 
// matching-ന് ഉപയോഗിക്കാവുന്ന canonical attributes extract ചെയ്യുന്നു.
// ------------------------------------------------------------

// Storage extract: "256GB", "1 TB" → 256 / 1024 (in GB)
function extractStorage(text) {
  if (!text) return null;
  const lower = text.toLowerCase();
  const re = /(\d+(?:\.\d+)?)\s*(tb|gb|mb)\b/gi;
  let match;
  let best = null;
  while ((match = re.exec(lower)) !== null) {
    const num = parseFloat(match[1]);
    const unit = match[2];
    let gb = num;
    if (unit === 'tb') gb = num * 1024;
    else if (unit === 'mb') gb = num / 1024;
    if (best === null || gb > best) best = gb;
  }
  return best; 
}

// Known color keywords
const COLOR_KEYWORDS = [
  'black', 'white', 'silver', 'gold', 'blue', 'red', 'green', 'grey', 'gray',
  'pink', 'purple', 'yellow', 'orange', 'brown', 'beige', 'navy', 'titanium',
  'natural titanium', 'space gray', 'space grey', 'midnight', 'starlight',
  'graphite', 'rose gold', 'deep purple', 'sierra blue', 'alpine green',
];

function extractColor(text) {
  if (!text) return null;
  const lower = text.toLowerCase();
  const sorted = [...COLOR_KEYWORDS].sort((a, b) => b.length - a.length);
  for (const c of sorted) {
    if (lower.includes(c)) return c.replace(/\s+/g, '_');
  }
  return null;
}

// Basic brand list
const BRAND_KEYWORDS = [
  'apple', 'iphone', 'ipad', 'macbook', 'samsung', 'galaxy', 'huawei',
  'xiaomi', 'redmi', 'oppo', 'vivo', 'oneplus', 'realme', 'nokia',
  'sony', 'playstation', 'xbox', 'nintendo', 'dell', 'hp', 'lenovo',
  'asus', 'acer', 'microsoft', 'surface', 'google', 'pixel', 'amazon',
  'nike', 'adidas', 'puma', 'reebok', 'zara', 'h&m', 'gucci', 'prada',
  'chanel', 'louis vuitton', 'rolex', 'casio', 'tissot',
];

function extractBrand(text) {
  if (!text) return null;
  const lower = text.toLowerCase();
  for (const b of BRAND_KEYWORDS) {
    if (lower.includes(b)) return b;
  }
  return null;
}

// Model extract
function extractModel(text, brand) {
  if (!text) return null;
  const lower = text.toLowerCase();
  let start = 0;
  if (brand && lower.includes(brand)) {
    start = lower.indexOf(brand) + brand.length;
  }
  const rest = lower.slice(start).trim();
  const tokens = rest.split(/\s+/).slice(0, 6);
  const kept = [];
  for (const tk of tokens) {
    if (!tk) continue;
    kept.push(tk);
    if (kept.length >= 4) break;
  }
  return kept.length ? kept.join('_').replace(/[^a-z0-9_]/g, '') : null;
}

// Lowercase, strip punctuation, collapse whitespace
function normalizeText(s) {
  if (!s) return '';
  return s
    .toString()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ') 
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Normalize a demand object.
 * @param {object} demand — Firestore demand document
 */
export function normalizeDemand(demand) {
  // Firestore-ൽ title എന്നത് {'en': '...', 'ar': '...'} എന്ന മാപ്പ് ആണ്
  const rawTitle = demand?.title?.en || demand?.title?.ar || '';
  const rawDesc = demand?.description?.en || demand?.description?.ar || '';
  const blob = `${rawTitle} ${rawDesc}`;

  const brand = extractBrand(blob);
  const model = extractModel(rawTitle, brand);
  const storage = extractStorage(blob);
  const color = extractColor(blob);
  const normalizedTitle = normalizeText(rawTitle);

  return {
    normalizedTitle,
    brand,
    model,
    storage,
    color,
  };
}

export { extractStorage, extractColor, extractBrand, extractModel, normalizeText };