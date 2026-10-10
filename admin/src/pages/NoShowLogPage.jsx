// ═══════════════════════════════════════════════════════
// MIGO Admin — No-Show Log Page (PHASE H)
// ═══════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import {
  collection, getDocs, query, orderBy, limit, doc,
  deleteDoc, getDoc, setDoc, serverTimestamp, where,
} from 'firebase/firestore';
import { db } from '../firebase';

export default function NoShowLogPage() {
  const [loading, setLoading] = useState(true);
  const [logs, setLogs] = useState([]);
  const [bans, setBans] = useState({});
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      // Load no-show logs
      const q = query(
        collection(db, 'no_show_log'),
        orderBy('timestamp', 'desc'),
        limit(200)
      );
      const snap = await getDocs(q);
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setLogs(list);

      // Load bans
      const banSnap = await getDocs(collection(db, 'reservation_bans'));
      const banMap = {};
      banSnap.docs.forEach((d) => {
        banMap[d.id] = { id: d.id, ...d.data() };
      });
      setBans(banMap);
    } catch (e) {
      console.error('Load error:', e);
    } finally {
      setLoading(false);
    }
  }

  async function banUser(userUid, userName, days) {
    if (!confirm(`Ban ${userName || userUid} for ${days} days?`)) return;

    try {
      const bannedUntil = new Date();
      bannedUntil.setDate(bannedUntil.getDate() + days);

      await setDoc(doc(db, 'reservation_bans', userUid), {
        userUid,
        bannedUntil,
        reason: `Manual ban by admin (${days} days)`,
        noShowCount: 0,
        createdBy: 'admin',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      alert('✅ User banned');
      loadData();
    } catch (e) {
      alert('❌ Error: ' + e.message);
    }
  }

  async function unbanUser(userUid) {
    if (!confirm('Remove ban for this user?')) return;

    try {
      await deleteDoc(doc(db, 'reservation_bans', userUid));
      alert('✅ Ban removed');
      loadData();
    } catch (e) {
      alert('❌ Error: ' + e.message);
    }
  }

  function exportCSV() {
    const headers = ['Date', 'User', 'Business', 'Offer', 'Reason'];
    const rows = logs.map((l) => [
      l.timestamp?.toDate?.()?.toISOString() || '',
      l.userName || l.userUid || '',
      l.businessName || '',
      l.offerId || '',
      l.reason || '',
    ]);

    const csv = [headers, ...rows]
      .map((r) => r.map((c) => `"${c}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `no-shows-${Date.now()}.csv`;
    a.click();
  }

  // Filter logs
  const filtered = logs.filter((l) => {
    if (filter === 'all') return true;
    if (filter === 'last7') {
      const d = l.timestamp?.toDate?.();
      if (!d) return false;
      return Date.now() - d.getTime() < 7 * 24 * 60 * 60 * 1000;
    }
    if (filter === 'last30') {
      const d = l.timestamp?.toDate?.();
      if (!d) return false;
      return Date.now() - d.getTime() < 30 * 24 * 60 * 60 * 1000;
    }
    return true;
  });

  if (loading) {
    return <div style={{ padding: 40 }}>Loading...</div>;
  }

  return (
    <div style={{ padding: 24 }}>
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 26, fontWeight: 'bold', marginBottom: 4 }}>
          🚫 No-Show Log
        </h1>
        <p style={{ color: '#6B7280', fontSize: 14 }}>
          Track no-shows and manage user bans.
        </p>
      </div>

      {/* Stats */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: 16,
          marginBottom: 24,
        }}
      >
        <StatCard
          title="Total No-Shows"
          value={logs.length}
          icon="🚫"
          color="#EF4444"
        />
        <StatCard
          title="Active Bans"
          value={Object.keys(bans).length}
          icon="⛔"
          color="#F59E0B"
        />
        <StatCard
          title="Unique Users"
          value={new Set(logs.map((l) => l.userUid)).size}
          icon="👤"
          color="#3B82F6"
        />
      </div>

      {/* Filters */}
      <div style={cardStyle}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 16,
            flexWrap: 'wrap',
            gap: 12,
          }}
        >
          <div style={{ display: 'flex', gap: 8 }}>
            <FilterButton
              label="All"
              active={filter === 'all'}
              onClick={() => setFilter('all')}
            />
            <FilterButton
              label="Last 7 Days"
              active={filter === 'last7'}
              onClick={() => setFilter('last7')}
            />
            <FilterButton
              label="Last 30 Days"
              active={filter === 'last30'}
              onClick={() => setFilter('last30')}
            />
          </div>
          <button
            onClick={exportCSV}
            style={{
              padding: '8px 16px',
              background: '#10B981',
              color: 'white',
              border: 'none',
              borderRadius: 6,
              fontSize: 13,
              fontWeight: 'bold',
              cursor: 'pointer',
            }}
          >
            📥 Export CSV
          </button>
        </div>

        {/* Table */}
        {filtered.length === 0 ? (
          <EmptyState text="No no-shows recorded" />
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={tableStyle}>
              <thead>
                <tr style={theadRow}>
                  <th style={thStyle}>Date</th>
                  <th style={thStyle}>User</th>
                  <th style={thStyle}>Business</th>
                  <th style={thStyle}>Offer</th>
                  <th style={thStyle}>Reason</th>
                  <th style={thStyle}>Ban Status</th>
                  <th style={thStyle}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((log) => {
                  const ban = bans[log.userUid];
                  const isBanned =
                    ban?.bannedUntil?.toDate?.() > new Date();
                  return (
                    <tr key={log.id} style={tbodyRow}>
                      <td style={tdStyle}>{formatDate(log.timestamp)}</td>
                      <td style={tdStyle}>
                        <div style={{ fontWeight: 600 }}>
                          {log.userName || '—'}
                        </div>
                        <div
                          style={{
                            fontSize: 11,
                            color: '#9CA3AF',
                            wordBreak: 'break-all',
                          }}
                        >
                          {log.userUid}
                        </div>
                      </td>
                      <td style={tdStyle}>{log.businessName || '—'}</td>
                      <td style={tdStyle}>{log.offerId || '—'}</td>
                      <td style={tdStyle}>{log.reason || 'expired'}</td>
                      <td style={tdStyle}>
                        {isBanned ? (
                          <span
                            style={{
                              padding: '3px 8px',
                              borderRadius: 4,
                              fontSize: 11,
                              fontWeight: 'bold',
                              background: '#FEE2E2',
                              color: '#991B1B',
                            }}
                          >
                            BANNED until{' '}
                            {formatDate(ban.bannedUntil)}
                          </span>
                        ) : (
                          <span style={{ fontSize: 12, color: '#9CA3AF' }}>
                            Active
                          </span>
                        )}
                      </td>
                      <td style={tdStyle}>
                        {isBanned ? (
                          <button
                            onClick={() => unbanUser(log.userUid)}
                            style={btnStyle('#10B981')}
                          >
                            Unban
                          </button>
                        ) : (
                          <div style={{ display: 'flex', gap: 4 }}>
                            <button
                              onClick={() =>
                                banUser(log.userUid, log.userName, 7)
                              }
                              style={btnStyle('#F59E0B')}
                            >
                              7d
                            </button>
                            <button
                              onClick={() =>
                                banUser(log.userUid, log.userName, 30)
                              }
                              style={btnStyle('#EF4444')}
                            >
                              30d
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────

function StatCard({ title, value, icon, color }) {
  return (
    <div
      style={{
        ...cardStyle,
        borderLeft: `4px solid ${color}`,
      }}
    >
      <div style={{ fontSize: 28, marginBottom: 6 }}>{icon}</div>
      <div style={{ fontSize: 13, color: '#6B7280', marginBottom: 4 }}>
        {title}
      </div>
      <div style={{ fontSize: 24, fontWeight: 'bold', color }}>
        {value}
      </div>
    </div>
  );
}

function FilterButton({ label, active, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '8px 16px',
        borderRadius: 8,
        border: active ? 'none' : '1px solid #E5E7EB',
        background: active ? '#7C3AED' : 'white',
        color: active ? 'white' : '#374151',
        fontSize: 13,
        fontWeight: 600,
        cursor: 'pointer',
      }}
    >
      {label}
    </button>
  );
}

function EmptyState({ text }) {
  return (
    <div
      style={{
        padding: 40,
        textAlign: 'center',
        color: '#9CA3AF',
        fontSize: 14,
      }}
    >
      {text}
    </div>
  );
}

function formatDate(ts) {
  if (!ts) return '—';
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  return `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1)
    .toString()
    .padStart(2, '0')} ${d.getHours().toString().padStart(2, '0')}:${d
    .getMinutes()
    .toString()
    .padStart(2, '0')}`;
}

function btnStyle(bg) {
  return {
    padding: '4px 10px',
    background: bg,
    color: 'white',
    border: 'none',
    borderRadius: 4,
    fontSize: 11,
    fontWeight: 'bold',
    cursor: 'pointer',
  };
}

const cardStyle = {
  background: 'white',
  borderRadius: 12,
  padding: 20,
  marginBottom: 16,
  boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
};

const tableStyle = {
  width: '100%',
  borderCollapse: 'collapse',
  fontSize: 14,
};

const theadRow = {
  borderBottom: '2px solid #E5E7EB',
};

const thStyle = {
  padding: '10px 12px',
  textAlign: 'left',
  fontWeight: 'bold',
  color: '#6B7280',
  fontSize: 12,
  textTransform: 'uppercase',
};

const tbodyRow = {
  borderBottom: '1px solid #F3F4F6',
};

const tdStyle = {
  padding: '12px',
  color: '#374151',
  verticalAlign: 'top',
};