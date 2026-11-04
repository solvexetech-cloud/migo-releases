// admin/src/utils/offerMatcher.js
// ------------------------------------------------------------
// MIGO Offer Matcher — scoring & decision
// 1. Normalize (offerNormalizer.js വഴി)
// 2. Brand/Model/Storage/Color/Price similarity കണക്കാക്കുന്നു
// 3. 0..1 confidence + decision (auto_merge / review / new)
// ------------------------------------------------------------

import { normalizeOffer } from './offerNormalizer.js';

// ---------- Similarity helpers ----------

// Jaro-Winkler (light-weight, pure JS)
function jaroWinkler(a, b) {
  if (!a || !b) return 0;
  if (a === b) return 1;

  const aLen = a.length;
  const bLen = b.length;
  const matchDist = Math.max(0, Math.floor(Math.max(aLen, bLen) / 2) - 1);
  const aMatch = new Array(aLen).fill(false);
  const bMatch = new Array(bLen).fill(false);

  let matches = 0;
  for (let i = 0; i < aLen; i++) {
    const start = Math.max(0, i - matchDist);
    const end = Math.min(i + matchDist + 1, bLen);
    for (let j = start; j < end; j++) {
      if (!bMatch[j] && a[i] === b[j]) {
        aMatch[i] = true;
        bMatch[j] = true;
        matches++;
        break;
      }
    }
  }
  if (matches === 0) return 0;

  let t = 0;
  let k = 0;
  for (let i = 0; i < aLen; i++) {
    if (aMatch[i]) {
      while (!bMatch[k]) k++;
      if (a[i] !== b[k]) t++;
      k++;
    }
  }
  t = t / 2;

  const jaro =
    (matches / aLen + matches / bLen + (matches - t) / matches) / 3;

  // Winkler boost for common prefix
  let prefix = 0;
  for (let i = 0; i < Math.min(4, aLen, bLen); i++) {
    if (a[i] === b[i]) prefix++;
    else break;
  }
  return jaro + prefix * 0.1 * (1 - jaro);
}

// Token-based Dice coefficient on normalized words
function diceCoefficient(a, b) {
  if (!a || !b) return 0;
  const A = new Set(a.split(' ').filter(Boolean));
  const B = new Set(b.split(' ').filter(Boolean));
  if (!A.size || !B.size) return 0;
  let inter = 0;
  A.forEach(w => { if (B.has(w)) inter++; });
  return (2 * inter) / (A.size + B.size);
}

// Price similarity: 1 if equal, drops as diff grows
function priceSimilarity(p1, p2) {
  if (!p1 || !p2 || p1 <= 0 || p2 <= 0) return 0.5; // unknown → neutral
  const diff = Math.abs(p1 - p2);
  const max = Math.max(p1, p2);
  const ratio = diff / max;      // 0 (same) .. 1 (100% diff)
  if (ratio <= 0.05) return 1.0; // within 5%
  if (ratio <= 0.15) return 0.85;
  if (ratio <= 0.30) return 0.60;
  if (ratio <= 0.50) return 0.35;
  return 0.1;
}

// ---------- Main scoring ----------

/**
 * Score how similar two offers are.
 * Returns { confidence, signals, decision, hardReject }
 */
export function scoreOffers(offerA, offerB) {
  const a = normalizeOffer(offerA);
  const b = normalizeOffer(offerB);

  // Hard-reject gates — these mean "definitely not same product"
  // Different category or different offer type → no match
  if (a.category !== b.category) {
    return hardReject('different_category', { a: a.category, b: b.category });
  }
  if (a.type !== b.type) {
    return hardReject('different_type', { a: a.type, b: b.type });
  }
  if (a.brand && b.brand && a.brand !== b.brand) {
    return hardReject('different_brand', { a: a.brand, b: b.brand });
  }
  // Storage mismatch is a strong signal, but not always hard (one side may be missing)
  if (a.storage != null && b.storage != null && a.storage !== b.storage) {
    return hardReject('different_storage', { a: a.storage, b: b.storage });
  }

  // ---------- Signals (each 0..1) ----------
  const brandScore = (a.brand && b.brand && a.brand === b.brand) ? 1.0
    : (a.brand || b.brand) ? 0.4
    : 0.6; // both unknown → assume could match

  const modelScore = (a.model && b.model)
    ? jaroWinkler(a.model, b.model)
    : 0.5;

  const nameScore = Math.max(
    jaroWinkler(a.normalizedTitle, b.normalizedTitle),
    diceCoefficient(a.normalizedTitle, b.normalizedTitle)
  );

  const storageScore = (a.storage != null && b.storage != null)
    ? (a.storage === b.storage ? 1.0 : 0.0) // already hard-rejected mismatch, so 1
    : 0.5;                                    // one side missing → neutral

  const colorScore = (a.color && b.color)
    ? (a.color === b.color ? 1.0 : 0.3)       // wrong colour → strong penalty
    : 0.6;                                     // unknown → mild neutral

  const priceScore = priceSimilarity(offerA?.offerPrice, offerB?.offerPrice);

  // ---------- Weighted confidence ----------
  const confidence =
    brandScore   * 0.20 +
    modelScore   * 0.25 +
    nameScore    * 0.25 +
    storageScore * 0.10 +
    colorScore   * 0.05 +
    priceScore   * 0.15;

  const signals = {
    brand: +brandScore.toFixed(2),
    model: +modelScore.toFixed(2),
    name: +nameScore.toFixed(2),
    storage: +storageScore.toFixed(2),
    color: +colorScore.toFixed(2),
    price: +priceScore.toFixed(2),
  };

  const decision = decide(confidence);

  return {
    confidence: +confidence.toFixed(3),
    signals,
    decision,
    hardReject: null,
    normalizedA: a,
    normalizedB: b,
  };
}

// ---------- Decision ----------

// 🚨 AUTO_MERGE_CONFIDENCE — പിന്നീട് ഉയർത്താം. ഇപ്പോൾ 1.1 (അതായത് auto-merge ഓഫ്).
//    Admin data കണ്ട് തൃപ്തിപ്പെട്ടാൽ 0.92 ആക്കാം — auto-merge ഓൺ ആകും.
export const AUTO_MERGE_CONFIDENCE = 1.1;

// Review-ലേക്ക് പോകേണ്ട minimum confidence
export const REVIEW_MIN_CONFIDENCE = 0.55;

function decide(confidence) {
  if (confidence >= AUTO_MERGE_CONFIDENCE) return 'auto_merge';
  if (confidence >= REVIEW_MIN_CONFIDENCE) return 'review';
  return 'new';
}

function hardReject(reason, detail) {
  return {
    confidence: 0,
    signals: null,
    decision: 'new',
    hardReject: { reason, detail },
    normalizedA: null,
    normalizedB: null,
  };
}

// ---------- Batch matcher ----------
// Given one new offer and a list of existing offers,
// return candidates sorted by confidence (desc).
export function findMatches(newOffer, existingOffers, { minConfidence = REVIEW_MIN_CONFIDENCE, limit = 20 } = {}) {
  const results = [];
  for (const other of existingOffers) {
    if (!other || other.id === newOffer?.id) continue;
    if (other.businessId === newOffer?.businessId) continue; // same business → skip (not duplicate)
    const r = scoreOffers(newOffer, other);
    if (r.hardReject) continue;
    if (r.confidence < minConfidence) continue;
    results.push({
      otherId: other.id,
      otherTitle: other.title,
      otherBusiness: other.businessName,
      otherPrice: other.offerPrice,
      ...r,
    });
  }
  results.sort((x, y) => y.confidence - x.confidence);
  return results.slice(0, limit);
}