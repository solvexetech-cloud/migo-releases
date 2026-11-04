// admin/src/pages/DemandMatchingPage.jsx
// ------------------------------------------------------------
// Admin Review Queue for Community Demands
// ------------------------------------------------------------

import { useEffect, useState } from 'react';
import {
  collection, onSnapshot, query, orderBy, doc, updateDoc,
  addDoc, Timestamp
} from 'firebase/firestore';
import { db } from '../firebase';
import { findMatches, REVIEW_MIN_CONFIDENCE } from '../utils/demandMatcher';

export default function DemandMatchingPage() {
  const [demands, setDemands] = useState([]);
  const [pairs, setPairs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [scanning, setScanning] = useState(false);
  const [selected, setSelected] = useState(null); // { a, b, score }
  const [filter, setFilter] = useState('pending'); // pending | merged | rejected | all
  const [isAr, setIsAr] = useState(false);

  // Live demands
  useEffect(() => {
    const q = query(collection(db, 'demands'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setDemands(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  // Saved demand_matches
  useEffect(() => {
    const q = query(collection(db, 'demand_matches'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setPairs(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  const runScan = async () => {
    if (demands.length < 2) {
      alert('Need at least 2 demands to scan.');
      return;
    }
    setScanning(true);
    try {
      const existingKeys = new Set(pairs.map(p => pairKey(p.demandAId, p.demandBId)));
      const newPairs = [];

      for (let i = 0; i < demands.length; i++) {
        const a = demands[i];
        const matches = findMatches(a, demands, { minConfidence: REVIEW_MIN_CONFIDENCE, limit: 10 });
        for (const m of matches) {
          const key = pairKey(a.id, m.otherId);
          if (existingKeys.has(key)) continue;
          existingKeys.add(key);
          newPairs.push({
            demandAId: a.id,
            demandBId: m.otherId,
            confidence: m.confidence,
            signals: m.signals,
            status: 'pending',
            createdAt: Timestamp.now(),
          });
        }
      }

      for (const p of newPairs) {
        await addDoc(collection(db, 'demand_matches'), p);
      }
      alert(`${newPairs.length} potential match(es) saved to review queue.`);
    } catch (err) {
      alert('Scan failed: ' + err.message);
    } finally {
      setScanning(false);
    }
  };

  // Merge: ഡിമാൻഡ് B-യിലെ യൂസറെ A-യിലേക്ക് ചേർക്കും (Join)
  const handleMerge = async () => {
    if (!selected) return;
    const { a, b } = selected;
    const confirmMsg = isAr
      ? `دمج "${a.title?.en}" و "${b.title?.en}"؟ سيتم إضافة المستخدم الثاني إلى الأول.`
      : `Merge "${a.title?.en}" into "${b.title?.en}"? User B will be added to Demand A.`;
    if (!window.confirm(confirmMsg)) return;
    try {
      // b-യിലെ currentCount A-യിലേക്ക് കൂട്ടുന്നു
      const newCountA = (a.currentCount || 0) + (b.currentCount || 1);
      await updateDoc(doc(db, 'demands', a.id), {
        currentCount: newCountA,
      });
      
      // b-യെ അവസാനിപ്പിക്കുന്നു
      await updateDoc(doc(db, 'demands', b.id), {
        status: 'merged',
        mergedInto: a.id,
      });

      await addDoc(collection(db, 'demand_matches'), {
        demandAId: a.id,
        demandBId: b.id,
        confidence: selected.score.confidence,
        signals: selected.score.signals,
        decision: 'merged',
        status: 'merged',
        mergedInto: a.id,
        reviewedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
      });
      setSelected(null);
      alert(isAr ? 'تم الدمج' : 'Merged successfully.');
    } catch (err) {
      alert('Merge failed: ' + err.message);
    }
  };

  const handleReject = async () => {
    if (!selected) return;
    const { a, b } = selected;
    try {
      await addDoc(collection(db, 'demand_matches'), {
        demandAId: a.id,
        demandBId: b.id,
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

  const demandById = (id) => demands.find(d => d.id === id);

  const visiblePairs = pairs.filter(p => {
    if (filter === 'all') return true;
    return p.status === filter;
  });

  const t = {
    title: isAr ? 'مطابقة الطلبات' : 'Demand Matching',
    scan: isAr ? 'فحص الطلبات' : 'Scan Demands',
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
    padding: '8px 16px', border: 'none', borderRadius: 6,
    cursor: 'pointer', fontWeight: 600, fontSize: 13,
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
            onClick={runScan} disabled={scanning}
            style={{ ...btnStyle, background: '#22c55e', color: 'white', opacity: scanning ? 0.6 : 1 }}
          >
            {scanning ? t.scanning : t.scan}
          </button>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {['pending', 'merged', 'rejected', 'all'].map(f => (
          <button
            key={f} onClick={() => setFilter(f)}
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

      {visiblePairs.length === 0 ? (
        <div style={{ padding: 24, background: 'white', borderRadius: 8, color: '#6b7280' }}>
          No pairs in this category. Click "{t.scan}" to find potential matches.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 12 }}>
          {visiblePairs.map(p => {
            const a = demandById(p.demandAId);
            const b = demandById(p.demandBId);
            if (!a || !b) return null;
            return (
              <div key={p.id} style={{
                background: 'white', borderRadius: 8, padding: 16,
                boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16,
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, marginBottom: 4 }}>
                    {a.title?.en} <span style={{ color: '#9ca3af' }}>vs</span> {b.title?.en}
                  </div>
                  <div style={{ fontSize: 12, color: '#6b7280' }}>
                    {a.userName} · QAR {a.targetPrice} &nbsp; vs &nbsp; {b.userName} · QAR {b.targetPrice}
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
              Review Demand Match
            </h2>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <DemandCard demand={selected.a} side="A" />
              <DemandCard demand={selected.b} side="B" />
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

function DemandCard({ demand, side }) {
  return (
    <div style={{ border: '1px solid #e5e7eb', borderRadius: 6, padding: 12 }}>
      <div style={{ fontSize: 11, color: '#6b7280', marginBottom: 4 }}>Demand {side}</div>
      <div style={{ fontWeight: 600, marginBottom: 6 }}>{demand.title?.en || demand.title?.ar}</div>
      <div style={{ fontSize: 13, color: '#374151', marginBottom: 4 }}>
        <strong>{demand.userName}</strong>
      </div>
      <div style={{ fontSize: 13, color: '#374151', marginBottom: 4 }}>
        Target Price: QAR {demand.targetPrice}
      </div>
      <div style={{ fontSize: 12, color: '#6b7280', marginTop: 6 }}>
        Count: {demand.currentCount} / {demand.requiredCount} · Status: {demand.status}
      </div>
      {demand.description?.en && (
        <div style={{ fontSize: 12, color: '#6b7280', marginTop: 6 }}>
          {demand.description.en.slice(0, 120)}
          {demand.description.en.length > 120 ? '…' : ''}
        </div>
      )}
    </div>
  );
}

function pairKey(a, b) {
  return [a, b].sort().join('__');
}