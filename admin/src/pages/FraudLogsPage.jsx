import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  doc,
  updateDoc,
} from 'firebase/firestore';
import { db } from '../firebase';

const REASON_COLORS = {
  duplicate_claim: { bg: '#FEF3C7', text: '#92400E' },
  rapid_claiming: { bg: '#FEE2E2', text: '#991B1B' },
  self_referral: { bg: '#E0E7FF', text: '#3730A3' },
  rapid_referring: { bg: '#FCE7F3', text: '#9D174D' },
  coin_farming: { bg: '#FED7AA', text: '#9A3412' },
  default: { bg: '#E5E7EB', text: '#374151' },
};

export default function FraudLogsPage() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const q = query(
      collection(db, 'fraud_logs'),
      orderBy('createdAt', 'desc')
    );
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setLogs(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const markReviewed = async (logId) => {
    try {
      await updateDoc(doc(db, 'fraud_logs', logId), {
        reviewed: true,
        reviewedAt: new Date().toISOString(),
      });
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const filtered = logs.filter((l) => {
    if (filter === 'unreviewed') return !l.reviewed;
    if (filter === 'reviewed') return l.reviewed;
    return true;
  });

  const stats = {
    total: logs.length,
    unreviewed: logs.filter((l) => !l.reviewed).length,
    today: logs.filter((l) => {
      if (!l.createdAt) return false;
      const d = l.createdAt.toDate
        ? l.createdAt.toDate()
        : new Date(l.createdAt);
      const today = new Date();
      return d.toDateString() === today.toDateString();
    }).length,
  };

  if (loading) {
    return <div style={{ padding: 40 }}>Loading fraud logs...</div>;
  }

  return (
    <div style={{ padding: 24 }}>
      <h1 style={{ fontSize: 24, fontWeight: 800, marginBottom: 4 }}>
        Fraud Logs
      </h1>
      <p style={{ color: '#666', marginBottom: 24 }}>
        Suspicious activity detection (E10 — Anti-fraud)
      </p>

      {/* Stats */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
          gap: 12,
          marginBottom: 24,
        }}
      >
        <StatCard label="Total" value={stats.total} color="#3B82F6" />
        <StatCard
          label="Unreviewed"
          value={stats.unreviewed}
          color="#EF4444"
        />
        <StatCard label="Today" value={stats.today} color="#F59E0B" />
      </div>

      {/* Filters */}
      <div
        style={{
          display: 'flex',
          gap: 12,
          marginBottom: 20,
          flexWrap: 'wrap',
        }}
      >
        {['all', 'unreviewed', 'reviewed'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            style={{
              padding: '8px 16px',
              borderRadius: 8,
              border: '1px solid #ddd',
              background: filter === f ? '#3B82F6' : '#fff',
              color: filter === f ? '#fff' : '#333',
              cursor: 'pointer',
              fontWeight: 600,
              textTransform: 'capitalize',
            }}
          >
            {f}
          </button>
        ))}
      </div>

      {/* List */}
      {filtered.length === 0 ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#999' }}>
          No fraud logs found ✅
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {filtered.map((log) => {
            const sc = REASON_COLORS[log.reason] || REASON_COLORS.default;
            return (
              <div
                key={log.id}
                style={{
                  background: '#fff',
                  padding: 16,
                  borderRadius: 12,
                  border: '1px solid #eee',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  gap: 16,
                }}
              >
                <div style={{ flex: 1 }}>
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 8,
                      marginBottom: 6,
                    }}
                  >
                    <span
                      style={{
                        background: sc.bg,
                        color: sc.text,
                        padding: '4px 10px',
                        borderRadius: 12,
                        fontSize: 11,
                        fontWeight: 700,
                        textTransform: 'uppercase',
                      }}
                    >
                      {log.reason?.replace(/_/g, ' ') || 'unknown'}
                    </span>
                    {log.reviewed && (
                      <span
                        style={{
                          background: '#D1FAE5',
                          color: '#065F46',
                          padding: '4px 10px',
                          borderRadius: 12,
                          fontSize: 11,
                          fontWeight: 700,
                        }}
                      >
                        ✓ REVIEWED
                      </span>
                    )}
                  </div>
                  <div
                    style={{
                      fontSize: 13,
                      fontWeight: 600,
                      marginBottom: 4,
                    }}
                  >
                    User: {log.userUid?.slice(0, 12)}...
                  </div>
                  {log.metadata &&
                    Object.keys(log.metadata).length > 0 && (
                      <div
                        style={{
                          fontSize: 12,
                          color: '#666',
                          fontFamily: 'monospace',
                        }}
                      >
                        {JSON.stringify(log.metadata)}
                      </div>
                    )}
                  <div
                    style={{
                      fontSize: 11,
                      color: '#888',
                      marginTop: 6,
                    }}
                  >
                    {log.createdAt?.toDate
                      ? log.createdAt.toDate().toLocaleString()
                      : '—'}
                  </div>
                </div>
                {!log.reviewed && (
                  <button
                    onClick={() => markReviewed(log.id)}
                    style={{
                      padding: '8px 14px',
                      background: '#10B981',
                      color: '#fff',
                      border: 'none',
                      borderRadius: 8,
                      cursor: 'pointer',
                      fontWeight: 600,
                      fontSize: 13,
                    }}
                  >
                    Mark Reviewed
                  </button>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function StatCard({ label, value, color }) {
  return (
    <div
      style={{
        background: '#fff',
        padding: 16,
        borderRadius: 12,
        border: '1px solid #eee',
        borderLeft: `4px solid ${color}`,
      }}
    >
      <div style={{ fontSize: 12, color: '#888', fontWeight: 600 }}>
        {label}
      </div>
      <div style={{ fontSize: 24, fontWeight: 800, color, marginTop: 4 }}>
        {value}
      </div>
    </div>
  );
}