import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  doc,
  updateDoc,
  query,
  orderBy,
} from 'firebase/firestore';
import { db } from '../firebase';

const STATUS_COLORS = {
  pending: { bg: '#FEF3C7', text: '#92400E', label: 'Pending' },
  approved: { bg: '#D1FAE5', text: '#065F46', label: 'Approved' },
  rejected: { bg: '#FEE2E2', text: '#991B1B', label: 'Rejected' },
  suspended: { bg: '#E5E7EB', text: '#374151', label: 'Suspended' },
};

export default function CreatorsPage() {
  const [creators, setCreators] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  useEffect(() => {
    const q = query(
      collection(db, 'creators'),
      orderBy('createdAt', 'desc')
    );
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setCreators(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleStatusChange = async (creatorId, newStatus) => {
    try {
      await updateDoc(doc(db, 'creators', creatorId), {
        status: newStatus,
        reviewedAt: new Date().toISOString(),
      });
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const filtered = creators.filter((c) => {
    if (filter !== 'all' && c.status !== filter) return false;
    if (search) {
      const s = search.toLowerCase();
      return (
        c.name?.toLowerCase().includes(s) ||
        c.email?.toLowerCase().includes(s) ||
        c.channelName?.toLowerCase().includes(s)
      );
    }
    return true;
  });

  const stats = {
    total: creators.length,
    pending: creators.filter((c) => c.status === 'pending').length,
    approved: creators.filter((c) => c.status === 'approved').length,
    rejected: creators.filter((c) => c.status === 'rejected').length,
  };

  if (loading) {
    return <div style={{ padding: 40 }}>Loading creators...</div>;
  }

  return (
    <div style={{ padding: 24 }}>
      <h1 style={{ fontSize: 24, fontWeight: 800, marginBottom: 4 }}>
        Creators
      </h1>
      <p style={{ color: '#666', marginBottom: 24 }}>
        Manage creator accounts and applications
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
        <StatCard label="Pending" value={stats.pending} color="#F59E0B" />
        <StatCard label="Approved" value={stats.approved} color="#10B981" />
        <StatCard label="Rejected" value={stats.rejected} color="#EF4444" />
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
        {['all', 'pending', 'approved', 'rejected', 'suspended'].map((f) => (
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
        <input
          type="text"
          placeholder="Search name, email, channel..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            minWidth: 200,
            padding: '8px 14px',
            borderRadius: 8,
            border: '1px solid #ddd',
          }}
        />
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#999' }}>
          No creators found
        </div>
      ) : (
        <div
          style={{
            background: '#fff',
            borderRadius: 12,
            border: '1px solid #eee',
            overflow: 'hidden',
          }}
        >
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#F9FAFB', textAlign: 'left' }}>
                <th style={th}>Name</th>
                <th style={th}>Channel</th>
                <th style={th}>Email</th>
                <th style={th}>Platform</th>
                <th style={th}>Status</th>
                <th style={th}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((c) => {
                const sc = STATUS_COLORS[c.status] || STATUS_COLORS.pending;
                return (
                  <tr key={c.id} style={{ borderTop: '1px solid #eee' }}>
                    <td style={td}>
                      <div style={{ fontWeight: 600 }}>{c.name || '—'}</div>
                      <div style={{ fontSize: 12, color: '#888' }}>
                        {c.id.slice(0, 8)}...
                      </div>
                    </td>
                    <td style={td}>{c.channelName || '—'}</td>
                    <td style={td}>{c.email || '—'}</td>
                    <td style={td}>{c.platform || '—'}</td>
                    <td style={td}>
                      <span
                        style={{
                          background: sc.bg,
                          color: sc.text,
                          padding: '4px 10px',
                          borderRadius: 12,
                          fontSize: 12,
                          fontWeight: 700,
                        }}
                      >
                        {sc.label}
                      </span>
                    </td>
                    <td style={td}>
                      {c.status === 'pending' && (
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button
                            onClick={() => handleStatusChange(c.id, 'approved')}
                            style={btnApprove}
                          >
                            Approve
                          </button>
                          <button
                            onClick={() => handleStatusChange(c.id, 'rejected')}
                            style={btnReject}
                          >
                            Reject
                          </button>
                        </div>
                      )}
                      {c.status === 'approved' && (
                        <button
                          onClick={() => handleStatusChange(c.id, 'suspended')}
                          style={btnReject}
                        >
                          Suspend
                        </button>
                      )}
                      {c.status === 'suspended' && (
                        <button
                          onClick={() => handleStatusChange(c.id, 'approved')}
                          style={btnApprove}
                        >
                          Restore
                        </button>
                      )}
                      {c.status === 'rejected' && (
                        <button
                          onClick={() => handleStatusChange(c.id, 'approved')}
                          style={btnApprove}
                        >
                          Approve
                        </button>
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

const th = {
  padding: '12px 16px',
  fontSize: 12,
  fontWeight: 700,
  color: '#666',
  textTransform: 'uppercase',
  letterSpacing: 0.5,
};

const td = {
  padding: '14px 16px',
  fontSize: 14,
  verticalAlign: 'top',
};

const btnApprove = {
  padding: '6px 12px',
  background: '#10B981',
  color: '#fff',
  border: 'none',
  borderRadius: 6,
  cursor: 'pointer',
  fontWeight: 600,
  fontSize: 13,
};

const btnReject = {
  padding: '6px 12px',
  background: '#EF4444',
  color: '#fff',
  border: 'none',
  borderRadius: 6,
  cursor: 'pointer',
  fontWeight: 600,
  fontSize: 13,
};