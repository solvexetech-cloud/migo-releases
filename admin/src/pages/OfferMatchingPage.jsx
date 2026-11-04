// admin/src/pages/OfferMatchingPage.jsx
// ------------------------------------------------------------
// Admin Review Queue — similar offers കണ്ടെത്തി Merge/Reject ചെയ്യാൻ
// ------------------------------------------------------------

import { useEffect, useState } from 'react';
import {
  collection, onSnapshot, query, orderBy, doc, updateDoc,
  addDoc, Timestamp, getDocs
} from 'firebase/firestore';
import { db } from '../firebase';
import { findMatches, REVIEW_MIN_CONFIDENCE } from '../utils/offerMatcher';

export default function OfferMatchingPage() {
  const [offers, setOffers] = useState([]);
  const [pairs, setPairs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [scanning, setScanning] = useState(false);
  const [selected, setSelected] = useState(null); // { a, b, score }
  const [filter, setFilter] = useState('pending'); // pending | merged | rejected | all
  const [isAr, setIsAr] = useState(false);

  // Live offers (order by createdAt desc — same as AllOffersPage)
  useEffect(() => {
    const q = query(collection(db, 'offers'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setOffers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  // Saved matches (offer_matches collection)
  useEffect(() => {
    const q = query(collection(db, 'offer_matches'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setPairs(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  // Run a scan over all offers and store new pairs
  const runScan = async () => {
    if (offers.length < 2) {
      alert('Need at least 2 offers to scan.');
      return;
    }
    setScanning(true);
    try {
      const existingKeys = new Set(pairs.map(p => pairKey(p.productAId, p.productBId)));
      const newPairs = [];

      for (let i = 0; i < offers.length; i++) {
        const a = offers[i];
        const matches = findMatches(a, offers, { minConfidence: REVIEW_MIN_CONFIDENCE, limit: 10 });
        for (const m of matches) {
          const key = pairKey(a.id, m.otherId);
          if (existingKeys.has(key)) continue;
          existingKeys.add(key);
          newPairs.push({
            productAId: a.id,
            productBId: m.otherId,
            confidence: m.confidence,
            signals: m.signals,
            decision: m.decision,
            status: 'pending',
            createdAt: Timestamp.now(),
          });
        }
      }

      // Write all new pairs
      for (const p of newPairs) {
        await addDoc(collection(db, 'offer_matches'), p);
      }
      alert(`${newPairs.length} potential match(es) saved to review queue.`);
    } catch (err) {
      alert('Scan failed: ' + err.message);
    } finally {
      setScanning(false);
    }
  };

  // Merge action — mark one as primary, hide the other
  const handleMerge = async () => {
    if (!selected) return;
    const { a, b } = selected;
    const confirmMsg = isAr
      ? `دمج "${a.title}" و "${b.title}"؟ سيتم إخفاء الثاني.`
      : `Merge "${a.title}" with "${b.title}"? The second will be hidden.`;
    if (!window.confirm(confirmMsg)) return;
    try {
      // Mark the duplicate (b) as merged into (a)
      await updateDoc(doc(db, 'offers', b.id), {
        status: 'merged',
        mergedInto: a.id,
        updatedAt: Timestamp.now(),
      });
      // Save audit log
      await addDoc(collection(db, 'offer_matches'), {
        productAId: a.id,
        productBId: b.id,
        confidence: selected.score.confidence,
        signals: selected.score.signals,
        decision: 'merged',
        status: 'merged',
        mergedInto: a.id,
        reviewedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
      });
      setSelected(null);
      alert(isAr ? 'تم الدمج' : 'Merged.');
    } catch (err) {
      alert('Merge failed: ' + err.message);
    }
  };

  // Reject — keep both separate
  const handleReject = async () => {
    if (!selected) return;
    const { a, b } = selected;
    try {
      await addDoc(collection(db, 'offer_matches'), {
        productAId: a.id,
        productBId: b.id,
        confidence: selected.score.confidence,
        signals: selected.score.signals,
        decision: 'rejected',
        status: 'rejected',
        reviewedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
      });
      setSelected(null);
      alert(isAr ? 'تم الرفض' : 'Rejected.');
    } catch (err) {
      alert('Reject failed: ' + err.message);
    }
  };

  // Get offer object by id
  const offerById = (id) => offers.find(o => o.id === id);

  // Filtered list for display
  const visiblePairs = pairs.filter(p => {
    if (filter === 'all') return true;
    return p.status === filter;
  });

  const t = {
    title: isAr ? 'مطابقة العروض' : 'Offer Matching',
    scan: isAr ? 'فحص العروض' : 'Scan Offers',
    scanning: isAr ? 'جاري الفحص...' : 'Scanning...',
    pending: isAr ? 'قيد المراجعة' : 'Pending',
    merged: isAr ? 'مدمج' : 'Merged',
    rejected: isAr ? 'مرفوض' : 'Rejected',
    all: isAr ? 'الكل' : 'All',
    confidence: isAr ? 'درجة التطابق' : 'Confidence',
    merge: isAr ? 'دمج' : 'Merge',
    reject: isAr ? 'رفض' : 'Reject',
    close: isAr ? 'إغلاق' : 'Close',
    details: isAr ? 'تفاصيل' : 'Details',
  };

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;

  const btnStyle = {
    padding: '8px 16px',
    border: 'none',
    borderRadius: 6,
    cursor: 'pointer',
    fontWeight: 600,
    fontSize: 13,
  };

  return (
    <div dir={isAr ? 'rtl' : 'ltr'} style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>{t.title}</h1>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={() => setIsAr(!isAr)} style={{ ...btnStyle, background: '#1e3a8a', color: 'white' }}>
            {isAr ? 'English' : 'العربية'}
          </button>
          <button
            onClick={runScan}
            disabled={scanning}
            style={{ ...btnStyle, background: '#22c55e', color: 'white', opacity: scanning ? 0.6 : 1 }}
          >
            {scanning ? t.scanning : t.scan}
          </button>
        </div>
      </div>

      {/* Filter tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {['pending', 'merged', 'rejected', 'all'].map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            style={{
              ...btnStyle,
              background: filter === f ? '#1e3a8a' : '#e5e7eb',
              color: filter === f ? 'white' : '#374151',
            }}
          >
            {t[f]}
          </button>
        ))}
      </div>

      {/* Pairs list */}
      {visiblePairs.length === 0 ? (
        <div style={{ padding: 24, background: 'white', borderRadius: 8, color: '#6b7280' }}>
          No pairs in this category. Click "{t.scan}" to find potential matches.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 12 }}>
          {visiblePairs.map(p => {
            const a = offerById(p.productAId);
            const b = offerById(p.productBId);
            if (!a || !b) return null;
            return (
              <div key={p.id} style={{
                background: 'white', borderRadius: 8, padding: 16,
                boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16,
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, marginBottom: 4 }}>
                    {a.title} <span style={{ color: '#9ca3af' }}>vs</span> {b.title}
                  </div>
                  <div style={{ fontSize: 12, color: '#6b7280' }}>
                    {a.businessName} · QAR {a.offerPrice} &nbsp; vs &nbsp; {b.businessName} · QAR {b.offerPrice}
                  </div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 11, color: '#6b7280' }}>{t.confidence}</div>
                  <div style={{
                    fontSize: 18, fontWeight: 700,
                    color: p.confidence >= 0.85 ? '#16a34a' : p.confidence >= 0.7 ? '#ca8a04' : '#dc2626',
                  }}>{Math.round((p.confidence || 0) * 100)}%</div>
                </div>
                {p.status === 'pending' && (
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button
                      onClick={() => setSelected({ a, b, score: p })}
                      style={{ ...btnStyle, background: '#3b82f6', color: 'white' }}
                    >{t.details}</button>
                  </div>
                )}
                {p.status !== 'pending' && (
                  <div style={{ fontSize: 12, color: '#6b7280', textTransform: 'uppercase' }}>{p.status}</div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Detail modal */}
      {selected && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000,
        }}>
          <div style={{
            background: 'white', borderRadius: 8, padding: 24, width: 720, maxWidth: '95%',
            maxHeight: '90vh', overflow: 'auto', direction: 'ltr',
          }}>
            <h2 style={{ fontSize: 20, fontWeight: 700, marginTop: 0, marginBottom: 16 }}>
              Review Match
            </h2>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <OfferCard offer={selected.a} side="A" />
              <OfferCard offer={selected.b} side="B" />
            </div>

            <div style={{ marginTop: 16, padding: 12, background: '#f9fafb', borderRadius: 6 }}>
              <div style={{ fontSize: 12, color: '#6b7280', marginBottom: 6 }}>Signals</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 8 }}>
                {Object.entries(selected.score.signals || {}).map(([k, v]) => (
                  <div key={k} style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 11, color: '#6b7280', textTransform: 'capitalize' }}>{k}</div>
                    <div style={{ fontSize: 16, fontWeight: 700 }}>{Math.round((v || 0) * 100)}%</div>
                  </div>
                ))}
              </div>
              <div style={{ marginTop: 10, textAlign: 'center', fontSize: 14 }}>
                Overall: <strong>{Math.round((selected.score.confidence || 0) * 100)}%</strong>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 20 }}>
              <button onClick={() => setSelected(null)} style={{ ...btnStyle, background: '#e5e7eb', color: '#374151' }}>
                {t.close}
              </button>
              <button onClick={handleReject} style={{ ...btnStyle, background: '#ef4444', color: 'white' }}>
                {t.reject}
              </button>
              <button onClick={handleMerge} style={{ ...btnStyle, background: '#22c55e', color: 'white' }}>
                {t.merge}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ---------- Helper components ----------

function OfferCard({ offer, side }) {
  return (
    <div style={{ border: '1px solid #e5e7eb', borderRadius: 6, padding: 12 }}>
      <div style={{ fontSize: 11, color: '#6b7280', marginBottom: 4 }}>Offer {side}</div>
      <div style={{ fontWeight: 600, marginBottom: 6 }}>{offer.title}</div>
      {offer.imageUrl && (
        <img
          src={offer.imageUrl}
          alt=""
          style={{ width: '100%', height: 120, objectFit: 'cover', borderRadius: 4, marginBottom: 8 }}
        />
      )}
      <div style={{ fontSize: 13, color: '#374151', marginBottom: 4 }}>
        <strong>{offer.businessName}</strong>
      </div>
      <div style={{ fontSize: 13, color: '#374151', marginBottom: 4 }}>
        QAR {offer.offerPrice}{' '}
        {offer.originalPrice > offer.offerPrice && (
          <span style={{ textDecoration: 'line-through', color: '#9ca3af', marginLeft: 6 }}>
            {offer.originalPrice}
          </span>
        )}
      </div>
      <div style={{ fontSize: 12, color: '#6b7280', marginTop: 6 }}>
        {offer.category} · {offer.type} · {offer.status}
      </div>
      {offer.description && (
        <div style={{ fontSize: 12, color: '#6b7280', marginTop: 6 }}>
          {offer.description.slice(0, 120)}
          {offer.description.length > 120 ? '…' : ''}
        </div>
      )}
    </div>
  );
}

// Pair key (order independent)
function pairKey(a, b) {
  return [a, b].sort().join('__');
}