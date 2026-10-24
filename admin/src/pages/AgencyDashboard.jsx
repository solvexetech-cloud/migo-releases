import { useEffect, useState } from 'react';
import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  getDoc,
  getDocs,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useRole } from '../contexts/RoleContext';

export default function AgencyDashboard() {
  const { user, userData } = useRole();
  const [agency, setAgency] = useState(null);
  const [businesses, setBusinesses] = useState([]);
  const [pending, setPending] = useState([]);
  const [flyers, setFlyers] = useState([]);
  const [totalViews, setTotalViews] = useState(0);
  const [totalFullyRead, setTotalFullyRead] = useState(0);
  const [loading, setLoading] = useState(true);

  // ─── Load agency data ───
  useEffect(() => {
    if (!user?.uid) return;

    async function loadAgency() {
      try {
        // Find agency owned by this user
        const snap = await getDoc(doc(db, 'agencies', user.uid));
        if (snap.exists()) {
          setAgency({ id: snap.id, ...snap.data() });
        } else {
          // Try query by ownerUid
          const q = query(
            collection(db, 'agencies'),
            where('ownerUid', '==', user.uid)
          );
          const qSnap = await new Promise((resolve) => {
            const unsub = onSnapshot(q, (s) => {
              resolve(s);
              unsub();
            });
          });
          if (!qSnap.empty) {
            const d = qSnap.docs[0];
            setAgency({ id: d.id, ...d.data() });
          }
        }
      } catch (err) {
        console.error('Agency load error:', err);
      } finally {
        setLoading(false);
      }
    }

    loadAgency();
  }, [user?.uid]);

  // ─── Load businesses in this agency's areas ───
  useEffect(() => {
    if (!agency?.areaIds || agency.areaIds.length === 0) {
      setBusinesses([]);
      setPending([]);
      return;
    }

    // Businesses in this agency's areas
    const q = query(
      collection(db, 'businesses'),
      where('areaId', 'in', agency.areaIds.slice(0, 10))
    );

    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setBusinesses(list);
      setPending(list.filter((b) => b.status === 'pending'));
    });

    return () => unsub();
  }, [agency?.areaIds]);

  // ─── Load flyers for these businesses ───
  useEffect(() => {
    if (!businesses || businesses.length === 0) {
      setFlyers([]);
      setTotalViews(0);
      setTotalFullyRead(0);
      return;
    }

    // Get business IDs (max 10 for 'in' query)
    const businessIds = businesses.slice(0, 10).map((b) => b.id);

    const q = query(
      collection(db, 'flyers'),
      where('businessId', 'in', businessIds)
    );

    const unsub = onSnapshot(q, (snap) => {
      const flyerList = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setFlyers(flyerList);

      // Calculate total views and fully read
      let views = 0;
      let fullyRead = 0;
      flyerList.forEach((f) => {
        views += (f.viewedBy || []).length;
        fullyRead += (f.fullyViewedBy || []).length;
      });
      setTotalViews(views);
      setTotalFullyRead(fullyRead);
    });

    return () => unsub();
  }, [businesses]);

  // ─── Loading ───
  if (loading) {
    return (
      <div
        style={{
          padding: 40,
          textAlign: 'center',
          color: '#666',
        }}
      >
        Loading agency dashboard...
      </div>
    );
  }

  // ─── No agency found ───
  if (!agency) {
    return (
      <div style={{ padding: 40, maxWidth: 600, margin: '0 auto' }}>
        <div
          style={{
            background: '#FEF3C7',
            padding: 24,
            borderRadius: 12,
            border: '1px solid #F59E0B',
          }}
        >
          <h2
            style={{
              fontSize: 20,
              fontWeight: 800,
              color: '#92400E',
              marginBottom: 8,
            }}
          >
            ⚠️ No agency assigned
          </h2>
          <p style={{ color: '#78350F', fontSize: 14 }}>
            Your account is not linked to any agency. Please contact
            a super admin to set up your agency profile.
          </p>
        </div>
      </div>
    );
  }

  // ─── Stats ───
  const stats = {
    total: businesses.length,
    approved: businesses.filter((b) => b.status === 'approved').length,
    pending: pending.length,
    revenue: agency.revenueShare
      ? `QAR ${(agency.revenueShare * 100).toFixed(0)}%`
      : '—',
  };

  return (
    <div style={{ padding: 24 }}>
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h1
          style={{
            fontSize: 24,
            fontWeight: 800,
            marginBottom: 4,
          }}
        >
          Agency Dashboard
        </h1>
        <p style={{ color: '#666', fontSize: 14 }}>
          {agency.name || 'Your Agency'} — {agency.areaIds?.length || 0}{' '}
          area(s)
        </p>
      </div>

      {/* Stats Grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns:
            'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 12,
          marginBottom: 24,
        }}
      >
        <StatCard
          label="Total Businesses"
          value={stats.total}
          color="#3B82F6"
          icon="🏢"
        />
        <StatCard
          label="Approved"
          value={stats.approved}
          color="#10B981"
          icon="✅"
        />
        <StatCard
          label="Pending Approval"
          value={stats.pending}
          color="#F59E0B"
          icon="⏳"
        />
        <StatCard
          label="Revenue Share"
          value={stats.revenue}
          color="#7C3AED"
          icon="💰"
        />
        <StatCard
          label="Total Flyers"
          value={flyers.length}
          color="#EC4899"
          icon="📄"
        />
        <StatCard
          label="Flyer Views"
          value={totalViews}
          color="#8B5CF6"
          icon="👁️"
        />
        <StatCard
          label="Fully Read"
          value={totalFullyRead}
          color="#10B981"
          icon="✅"
        />
      </div>

      {/* Agency Info */}
      <div
        style={{
          background: '#fff',
          padding: 20,
          borderRadius: 12,
          border: '1px solid #eee',
          marginBottom: 24,
        }}
      >
        <h2
          style={{
            fontSize: 16,
            fontWeight: 800,
            marginBottom: 12,
            color: '#333',
          }}
        >
          🏢 Agency Info
        </h2>
        <InfoRow label="Name" value={agency.name || '—'} />
        <InfoRow label="Owner Email" value={user?.email || '—'} />
        <InfoRow
          label="Areas"
          value={agency.areaIds?.join(', ') || '—'}
        />
        <InfoRow
          label="Revenue Share"
          value={
            agency.revenueShare
              ? `${(agency.revenueShare * 100).toFixed(0)}%`
              : '—'
          }
        />
        <InfoRow label="Status" value={agency.status || '—'} />
      </div>

      {/* Pending Businesses */}
      {pending.length > 0 && (
        <div
          style={{
            background: '#fff',
            padding: 20,
            borderRadius: 12,
            border: '1px solid #eee',
            marginBottom: 24,
          }}
        >
          <h2
            style={{
              fontSize: 16,
              fontWeight: 800,
              marginBottom: 12,
              color: '#92400E',
            }}
          >
            ⏳ Pending Approval ({pending.length})
          </h2>
          {pending.slice(0, 5).map((b) => (
            <div
              key={b.id}
              style={{
                padding: 12,
                borderBottom: '1px solid #f0f0f0',
                fontSize: 14,
              }}
            >
              <div style={{ fontWeight: 700 }}>
                {b.name || 'Unnamed Business'}
              </div>
              <div style={{ color: '#666', fontSize: 12, marginTop: 2 }}>
                {b.category || '—'} • {b.addressLine || '—'}
              </div>
            </div>
          ))}
          {pending.length > 5 && (
            <div
              style={{
                paddingTop: 8,
                fontSize: 12,
                color: '#666',
                textAlign: 'center',
              }}
            >
              +{pending.length - 5} more...
            </div>
          )}
        </div>
      )}

      {/* Businesses List */}
      <div
        style={{
          background: '#fff',
          padding: 20,
          borderRadius: 12,
          border: '1px solid #eee',
          marginBottom: 24,
        }}
      >
        <h2
          style={{
            fontSize: 16,
            fontWeight: 800,
            marginBottom: 12,
            color: '#333',
          }}
        >
          🏢 Businesses in Your Areas ({businesses.length})
        </h2>

        {businesses.length === 0 ? (
          <div
            style={{
              padding: 20,
              textAlign: 'center',
              color: '#999',
              fontSize: 13,
            }}
          >
            No businesses in your areas yet.
          </div>
        ) : (
          businesses.slice(0, 10).map((b) => (
            <div
              key={b.id}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '12px 0',
                borderBottom: '1px solid #f5f5f5',
              }}
            >
              <div>
                <div style={{ fontWeight: 700, fontSize: 14 }}>
                  {b.name || 'Unnamed'}
                </div>
                <div
                  style={{
                    color: '#888',
                    fontSize: 12,
                    marginTop: 2,
                  }}
                >
                  {b.category || '—'} • {b.areaId || '—'}
                </div>
              </div>
              <StatusBadge status={b.status} />
            </div>
          ))
        )}

        {businesses.length > 10 && (
          <div
            style={{
              paddingTop: 12,
              fontSize: 12,
              color: '#666',
              textAlign: 'center',
            }}
          >
            Showing 10 of {businesses.length} businesses
          </div>
        )}
      </div>

      {/* Flyers List */}
      <div
        style={{
          background: '#fff',
          padding: 20,
          borderRadius: 12,
          border: '1px solid #eee',
        }}
      >
        <h2
          style={{
            fontSize: 16,
            fontWeight: 800,
            marginBottom: 12,
            color: '#333',
          }}
        >
          📄 Flyers in Your Areas ({flyers.length})
        </h2>
        {flyers.length === 0 ? (
          <div
            style={{
              padding: 20,
              textAlign: 'center',
              color: '#999',
              fontSize: 13,
            }}
          >
            No flyers uploaded yet.
          </div>
        ) : (
          flyers.slice(0, 10).map((f) => (
            <div
              key={f.id}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '12px 0',
                borderBottom: '1px solid #f5f5f5',
              }}
            >
              <div>
                <div style={{ fontWeight: 700, fontSize: 14 }}>
                  {f.title || 'Untitled'}
                </div>
                <div style={{ color: '#888', fontSize: 12, marginTop: 2 }}>
                  {f.businessName || '—'} · 👁️ {(f.viewedBy || []).length} · ✅{' '}
                  {(f.fullyViewedBy || []).length}
                </div>
              </div>
              <StatusBadge status={f.status} />
            </div>
          ))
        )}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════

function StatCard({ label, value, color, icon }) {
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
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 6,
          fontSize: 12,
          color: '#888',
          fontWeight: 600,
          marginBottom: 6,
        }}
      >
        <span>{icon}</span>
        <span>{label}</span>
      </div>
      <div
        style={{
          fontSize: 24,
          fontWeight: 800,
          color,
        }}
      >
        {value}
      </div>
    </div>
  );
}

function InfoRow({ label, value }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        padding: '8px 0',
        borderBottom: '1px solid #f5f5f5',
        fontSize: 13,
      }}
    >
      <span style={{ color: '#666', fontWeight: 600 }}>{label}</span>
      <span style={{ color: '#333', fontWeight: 700 }}>
        {value}
      </span>
    </div>
  );
}

function StatusBadge({ status }) {
  const colors = {
    approved: { bg: '#D1FAE5', text: '#065F46' },
    pending: { bg: '#FEF3C7', text: '#92400E' },
    rejected: { bg: '#FEE2E2', text: '#991B1B' },
    suspended: { bg: '#E5E7EB', text: '#374151' },
  };
  const c = colors[status] || colors.pending;

  return (
    <span
      style={{
        background: c.bg,
        color: c.text,
        padding: '4px 10px',
        borderRadius: 12,
        fontSize: 11,
        fontWeight: 700,
        textTransform: 'uppercase',
      }}
    >
      {status || 'pending'}
    </span>
  );
}