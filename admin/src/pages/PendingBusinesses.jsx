import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  query,
  updateDoc,
  doc,
  where,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

export default function PendingBusinesses() {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState({});
  const isMobile = useIsMobile();

  useEffect(() => {
    const q = query(
      collection(db, 'businesses'),
      where('status', '==', 'pending'),
    );
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setBusinesses(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  async function handleApprove(b) {
    setWorking((w) => ({ ...w, [b.id]: 'approving' }));
    try {
      await updateDoc(doc(db, 'businesses', b.id), {
        status: 'approved',
        verified: true,
        updatedAt: new Date(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking((w) => ({ ...w, [b.id]: null }));
    }
  }

  async function handleReject(b) {
    if (!confirm(`Reject "${b.name}"? The owner will see this as rejected.`)) {
      return;
    }
    setWorking((w) => ({ ...w, [b.id]: 'rejecting' }));
    try {
      await updateDoc(doc(db, 'businesses', b.id), {
        status: 'rejected',
        updatedAt: new Date(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking((w) => ({ ...w, [b.id]: null }));
    }
  }

  return (
    <div
  style={{
    padding: isMobile ? 16 : 32,
    maxWidth: 1100,
  }}
>
      <header style={{ marginBottom: 24 }}>
        <h1
          style={{
            fontSize: 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Pending Businesses
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Review and approve new business registrations.
        </p>
      </header>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : businesses.length === 0 ? (
        <EmptyState
          icon="🎉"
          title="No pending businesses"
          body="All caught up. New registrations will appear here."
        />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {businesses.map((b) => (
            <BusinessCard
              key={b.id}
              business={b}
              working={working[b.id]}
              onApprove={() => handleApprove(b)}
              onReject={() => handleReject(b)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function BusinessCard({ business, working, onApprove, onReject }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: 14,
        }}
      >
        <div style={{ flex: 1, minWidth: 220 }}>
          <div
            style={{
              fontSize: 18,
              fontWeight: 900,
              color: '#0B2B5B',
              marginBottom: 4,
            }}
          >
            {business.name}
          </div>
          <div
            style={{
              display: 'inline-block',
              padding: '3px 10px',
              borderRadius: 6,
              background: '#EFF6FF',
              color: '#1E4B8F',
              fontSize: 11,
              fontWeight: 800,
              letterSpacing: 0.5,
              marginRight: 8,
            }}
          >
            {business.category}
          </div>
          <div
            style={{
              display: 'inline-block',
              padding: '3px 10px',
              borderRadius: 6,
              background: '#FFF3D6',
              color: '#A67920',
              fontSize: 11,
              fontWeight: 800,
              letterSpacing: 0.5,
            }}
          >
            PENDING
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8 }}>
          <button
            onClick={onApprove}
            disabled={working}
            style={{
              padding: '10px 20px',
              borderRadius: 10,
              border: 'none',
              background: working === 'approving' ? '#94A3B8' : '#2E9E5B',
              color: 'white',
              fontSize: 13,
              fontWeight: 800,
              cursor: working ? 'not-allowed' : 'pointer',
            }}
          >
            {working === 'approving' ? 'Approving…' : '✓ Approve'}
          </button>
          <button
            onClick={onReject}
            disabled={working}
            style={{
              padding: '10px 20px',
              borderRadius: 10,
              border: '1px solid #D64545',
              background: 'white',
              color: '#D64545',
              fontSize: 13,
              fontWeight: 800,
              cursor: working ? 'not-allowed' : 'pointer',
            }}
          >
            {working === 'rejecting' ? 'Rejecting…' : 'Reject'}
          </button>
        </div>
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 12,
          fontSize: 13,
          color: '#374151',
        }}
      >
        <Field label="Address" value={business.addressLine} />
        <Field label="City" value={`${business.city}, ${business.country}`} />
        <Field label="Phone" value={business.phone || '—'} />
        <Field label="WhatsApp" value={business.whatsapp || '—'} />
        <Field label="Currency" value={business.currency} />
        <Field label="Owner UID" value={business.ownerUid} mono />
      </div>

      {business.description && (
        <div
          style={{
            marginTop: 14,
            padding: 12,
            background: '#F6F3EE',
            borderRadius: 10,
            fontSize: 13,
            color: '#374151',
            lineHeight: 1.5,
          }}
        >
          {business.description}
        </div>
      )}
    </div>
  );
}

function Field({ label, value, mono }) {
  return (
    <div>
      <div
        style={{
          fontSize: 10,
          fontWeight: 800,
          color: '#9CA3AF',
          letterSpacing: 0.5,
          marginBottom: 3,
        }}
      >
        {label.toUpperCase()}
      </div>
      <div
        style={{
          fontSize: 13,
          fontWeight: 600,
          color: '#111418',
          fontFamily: mono ? 'monospace' : 'inherit',
          wordBreak: 'break-all',
        }}
      >
        {value || '—'}
      </div>
    </div>
  );
}

function EmptyState({ icon, title, body }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: 48,
        textAlign: 'center',
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div style={{ fontSize: 48, marginBottom: 12 }}>{icon}</div>
      <div
        style={{
          fontSize: 18,
          fontWeight: 800,
          color: '#0B2B5B',
          marginBottom: 6,
        }}
      >
        {title}
      </div>
      <div style={{ fontSize: 13, color: '#6B7280' }}>{body}</div>
    </div>
  );
}