// admin/src/utils/offerNormalizer.js
// ------------------------------------------------------------
// MIGO Offer Normalizer
// Offer title/description-ൽ നിന്ന് matching-ന് ഉപയോഗിക്കാവുന്ന
// canonical attributes extract ചെയ്യുന്നു. Pure JS — no Firebase.
// ------------------------------------------------------------

const STORAGE_UNITS = ['tb', 'gb', 'mb'];

// Storage extract: "256GB", "256 GB", "1 TB" → 256 / 1024 (in GB)
function extractStorage(text) {
  if (!text) return null;
  const lower = text.toLowerCase();
  // 1 TB / 512 GB / 256GB etc.
  const re = /(\d+(?:\.\d+)?)\s*(tb|gb|mb)\b/gi;
  let match;
  let best = null;
  while ((match = re.exec(lower)) !== null) {
    const num = parseFloat(match[1]);
    const unit = match[2];
    let gb = num;
    if (unit === 'tb') gb = num * 1024;
    else if (unit === 'mb') gb = num / 1024;
    // Prefer the largest storage found (256GB + 1TB → prefer 1TB)
    if (best === null || gb > best) best = gb;
  }
  return best; // GB as number, or null
}

// Known color keywords (extendable)
const COLOR_KEYWORDS = [
  'black', 'white', 'silver', 'gold', 'blue', 'red', 'green', 'grey', 'gray',
  'pink', 'purple', 'yellow', 'orange', 'brown', 'beige', 'navy', 'titanium',
  'natural titanium', 'space gray', 'space grey', 'midnight', 'starlight',
  'graphite', 'rose gold', 'deep purple', 'sierra blue', 'alpine green',
];

function extractColor(text) {
  if (!text) return null;
  const lower = text.toLowerCase();
  // Longest-first to catch "natural titanium" before "titanium"
  const sorted = [...COLOR_KEYWORDS].sort((a, b) => b.length - a.length);
  for (const c of sorted) {
    if (lower.includes(c)) return c.replace(/\s+/g, '_');
  }
  return null;
}

// Basic brand list — can be extended any time
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

// Model extract — a light heuristic:
// After brand keyword, take the next 2–4 meaningful tokens
function extractModel(text, brand) {
  if (!text) return null;
  const lower = text.toLowerCase();
  let start = 0;
  if (brand && lower.includes(brand)) {
    start = lower.indexOf(brand) + brand.length;
  }
  const rest = lower.slice(start).trim();
  // Take first 4 tokens, drop pure numbers < 100 (unless followed by unit)
  const tokens = rest.split(/\s+/).slice(0, 6);
  const kept = [];
  for (const tk of tokens) {
    if (!tk) continue;
    if (/^\d+$/.test(tk) && parseInt(tk, 10) < 100) {
      // Small number — keep (e.g., "15" for iPhone 15)
      kept.push(tk);
    } else {
      kept.push(tk);
    }
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
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')   // keep letters & numbers
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Normalize an offer object.
 * @param {object} offer — Firestore offer document (title, description, etc.)
 * @returns {{ normalizedTitle:string, brand:string|null,
 *             model:string|null, storage:number|null,
 *             color:string|null, category:string, type:string }}
 */
export function normalizeOffer(offer) {
  const rawTitle = offer?.title || offer?.titleEn || '';
  const rawDesc = offer?.description || offer?.descriptionEn || '';
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
    category: (offer?.category || 'general').toString().toLowerCase(),
    type: (offer?.type || 'standard').toString().toLowerCase(),
  };
}

// Exported helpers (for testing / reuse)
export { extractStorage, extractColor, extractBrand, extractModel, normalizeText };