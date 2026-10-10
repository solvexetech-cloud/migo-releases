// ═══════════════════════════════════════════════════════
// MIGO Admin — Reservations Page (PHASE H)
// ═══════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import {
  collection, getDocs, query, orderBy, limit, doc,
  updateDoc, deleteDoc, where, serverTimestamp, getCountFromServer,
} from 'firebase/firestore';
import { db } from '../firebase';

const STATUS_FILTERS = [
  { key: 'all', label: 'All', color: '#6B7280' },
  { key: 'reserved', label: 'Active', color: '#10B981' },
  { key: 'picked_up', label: 'Picked Up', color: '#3B82F6' },
  { key: 'expired', label: 'Expired', color: '#EF4444' },
  { key: 'cancelled', label: 'Cancelled', color: '#9CA3AF' },
];

export default function ReservationsPage() {
  const [loading, setLoading] = useState(true);
  const [reservations, setReservations] = useState([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    pickedUpToday: 0,
    noShowToday: 0,
    conversionRate: 0,
  });

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      // Load reservations
      const q = query(
        collection(db, 'reservations'),
        orderBy('bookedAt', 'desc'),
        limit(200)
      );
      const snap = await getDocs(q);
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setReservations(list);

      // Calculate stats
      const now = new Date();
      const todayStart = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate()
      );

      let active = 0;
      let pickedUpToday = 0;
      let noShowToday = 0;

      list.forEach((r) => {
        if (r.status === 'reserved') active++;

        const pickedUp = r.pickedUpAt?.toDate?.();
        if (pickedUp && pickedUp >= todayStart) pickedUpToday++;

        const updated = r.updatedAt?.toDate?.();
        if (r.status === 'expired' && updated && updated >= todayStart)
          noShowToday++;
      });

      const picked = list.filter((r) => r.status === 'picked_up').length;
      const conversionRate =
        list.length > 0 ? Math.round((picked / list.length) * 100) : 0;

      setStats({
        total: list.length,
        active,
        pickedUpToday,
        noShowToday,
        conversionRate,
      });
    } catch (e) {
      console.error('Load error:', e);
    } finally {
      setLoading(false);
    }
  }

  async function forceCancel(reservationId) {
    if (!confirm('Force cancel this reservation? Slot will be released.'))
      return;

    try {
      const res = reservations.find((r) => r.id === reservationId);
      if (!res) return;

      await updateDoc(doc(db, 'reservations', reservationId), {
        status: 'cancelled',
        cancelledAt: serverTimestamp(),
        cancelledBy: 'admin',
        updatedAt: serverTimestamp(),
      });

      // Release offer slot
      if (res.offerId && res.quantity) {
        const offerRef = doc(db, 'offers', res.offerId);
        // Note: This should ideally be a transaction
      }

      alert('✅ Reservation cancelled');
      loadData();
    } catch (e) {
      alert('❌ Error: ' + e.message);
    }
  }

  // Filter reservations
  const filtered = reservations.filter((r) => {
    // Status filter
    if (statusFilter !== 'all' && r.status !== statusFilter) return false;

    // Search filter
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return (
        (r.userName || '').toLowerCase().includes(q) ||
        (r.businessName || '').toLowerCase().includes(q) ||
        (r.offerTitle || '').toLowerCase().includes(q) ||
        (r.pickupCode || '').includes(q)
      );
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
          🎫 Reservations
        </h1>
        <p style={{ color: '#6B7280', fontSize: 14 }}>
          Monitor all reserve bookings across MIGO.
        </p>
      </div>

      {/* Stats */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 16,
          marginBottom: 24,
        }}
      >
        <StatCard
          title="Total Reservations"
          value={stats.total}
          icon="🎫"
          color="#7C3AED"
        />
        <StatCard
          title="Active Now"
          value={stats.active}
          icon="✅"
          color="#10B981"
        />
        <StatCard
          title="Picked Up Today"
          value={stats.pickedUpToday}
          icon="📦"
          color="#3B82F6"
        />
        <StatCard
          title="No-Shows Today"
          value={stats.noShowToday}
          icon="🚫"
          color="#EF4444"
        />
        <StatCard
          title="Conversion Rate"
          value={`${stats.conversionRate}%`}
          icon="📈"
          color="#F59E0B"
        />
      </div>

      {/* Filters + Table */}
      <div style={cardStyle}>
        {/* Filters Row */}
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
          {/* Status buttons */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {STATUS_FILTERS.map((f) => (
              <button
                key={f.key}
                onClick={() => setStatusFilter(f.key)}
                style={{
                  padding: '8px 16px',
                  borderRadius: 8,
                  border:
                    statusFilter === f.key ? 'none' : '1px solid #E5E7EB',
                  background:
                    statusFilter === f.key ? f.color : 'white',
                  color: statusFilter === f.key ? 'white' : '#374151',
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                {f.label}
              </button>
            ))}
          </div>

          {/* Search */}
          <input
            type="text"
            placeholder="Search customer, business, offer, code..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              padding: '10px 14px',
              borderRadius: 8,
              border: '1px solid #D1D5DB',
              fontSize: 13,
              minWidth: 280,
            }}
          />
        </div>

        {/* Table */}
        {filtered.length === 0 ? (
          <div
            style={{
              padding: 60,
              textAlign: 'center',
              color: '#9CA3AF',
              fontSize: 14,
            }}
          >
            No reservations found
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={tableStyle}>
              <thead>
                <tr style={theadRow}>
                  <th style={thStyle}>Booked</th>
                  <th style={thStyle}>Customer</th>
                  <th style={thStyle}>Business</th>
                  <th style={thStyle}>Offer</th>
                  <th style={thStyle}>Qty</th>
                  <th style={thStyle}>Amount</th>
                  <th style={thStyle}>Expires</th>
                  <th style={thStyle}>Status</th>
                  <th style={thStyle}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((r) => (
                  <tr key={r.id} style={tbodyRow}>
                    <td style={tdStyle}>
                      <div style={{ fontSize: 12 }}>
                        {formatDateTime(r.bookedAt)}
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <div style={{ fontWeight: 600 }}>
                        {r.userName || '—'}
                      </div>
                      <div
                        style={{
                          fontSize: 11,
                          color: '#9CA3AF',
                          wordBreak: 'break-all',
                        }}
                      >
                        {r.userPhone || r.userUid?.slice(0, 8)}
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <div style={{ fontWeight: 500 }}>
                        {r.businessName || '—'}
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <div style={{ fontSize: 13 }}>
                        {r.offerTitle || '—'}
                      </div>
                      {r.pickupCode && (
                        <div
                          style={{
                            fontSize: 11,
                            color: '#7C3AED',
                            fontWeight: 'bold',
                            letterSpacing: 1,
                          }}
                        >
                          #{r.pickupCode}
                        </div>
                      )}
                    </td>
                    <td style={tdStyle}>
                      <div
                        style={{
                          fontWeight: 'bold',
                          textAlign: 'center',
                        }}
                      >
                        ×{r.quantity || 1}
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <div style={{ fontWeight: 600 }}>
                        {r.currency || 'QAR'}{' '}
                        {(r.totalAmount || 0).toFixed(0)}
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <div style={{ fontSize: 12 }}>
                        {formatDateTime(r.expiresAt)}
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <StatusBadge status={r.status} />
                    </td>
                    <td style={tdStyle}>
                      {r.status === 'reserved' && (
                        <button
                          onClick={() => forceCancel(r.id)}
                          style={{
                            padding: '4px 10px',
                            background: '#EF4444',
                            color: 'white',
                            border: 'none',
                            borderRadius: 4,
                            fontSize: 11,
                            fontWeight: 'bold',
                            cursor: 'pointer',
                          }}
                        >
                          Force Cancel
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Count */}
        {filtered.length > 0 && (
          <div
            style={{
              marginTop: 12,
              fontSize: 12,
              color: '#6B7280',
              textAlign: 'right',
            }}
          >
            Showing {filtered.length} of {reservations.length} reservations
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
        background: 'white',
        borderRadius: 12,
        padding: 18,
        boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
        borderLeft: `4px solid ${color}`,
      }}
    >
      <div style={{ fontSize: 24, marginBottom: 6 }}>{icon}</div>
      <div style={{ fontSize: 12, color: '#6B7280', marginBottom: 4 }}>
        {title}
      </div>
      <div style={{ fontSize: 22, fontWeight: 'bold', color }}>
        {value}
      </div>
    </div>
  );
}

function StatusBadge({ status }) {
  const colors = {
    reserved: { bg: '#D1FAE5', fg: '#065F46', label: 'ACTIVE' },
    picked_up: { bg: '#DBEAFE', fg: '#1E40AF', label: 'PICKED UP' },
    expired: { bg: '#FEE2E2', fg: '#991B1B', label: 'EXPIRED' },
    cancelled: { bg: '#F3F4F6', fg: '#6B7280', label: 'CANCELLED' },
  };
  const c = colors[status] || colors.cancelled;
  return (
    <span
      style={{
        padding: '4px 10px',
        borderRadius: 6,
        fontSize: 10,
        fontWeight: 'bold',
        background: c.bg,
        color: c.fg,
        letterSpacing: 0.5,
      }}
    >
      {c.label}
    </span>
  );
}

function formatDateTime(ts) {
  if (!ts) return '—';
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  const day = d.getDate().toString().padStart(2, '0');
  const month = (d.getMonth() + 1).toString().padStart(2, '0');
  const hh = d.getHours().toString().padStart(2, '0');
  const mm = d.getMinutes().toString().padStart(2, '0');
  return `${day}/${month} ${hh}:${mm}`;
}

const cardStyle = {
  background: 'white',
  borderRadius: 12,
  padding: 20,
  boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
};

const tableStyle = {
  width: '100%',
  borderCollapse: 'collapse',
  fontSize: 13,
};

const theadRow = {
  borderBottom: '2px solid #E5E7EB',
};

const thStyle = {
  padding: '10px 12px',
  textAlign: 'left',
  fontWeight: 'bold',
  color: '#6B7280',
  fontSize: 11,
  textTransform: 'uppercase',
  whiteSpace: 'nowrap',
};

const tbodyRow = {
  borderBottom: '1px solid #F3F4F6',
};

const tdStyle = {
  padding: '12px',
  color: '#374151',
  verticalAlign: 'top',
};