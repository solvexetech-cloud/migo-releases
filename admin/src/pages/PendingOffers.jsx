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

export default function PendingOffers() {
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState({});
  const isMobile = useIsMobile();

  useEffect(() => {
    const q = query(
      collection(db, 'offers'),
      where('status', '==', 'pending'),
    );
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setOffers(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  async function handleApprove(o) {
    setWorking((w) => ({ ...w, [o.id]: 'approving' }));
    try {
      await updateDoc(doc(db, 'offers', o.id), {
        status: 'live',
        updatedAt: new Date(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking((w) => ({ ...w, [o.id]: null }));
    }
  }

  async function handleReject(o) {
    if (!confirm(`Reject "${o.title}"? The business owner will see this as rejected.`)) {
      return;
    }
    setWorking((w) => ({ ...w, [o.id]: 'rejecting' }));
    try {
      await updateDoc(doc(db, 'offers', o.id), {
        status: 'rejected',
        updatedAt: new Date(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking((w) => ({ ...w, [o.id]: null }));
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
            fontSize: isMobile ? 24 : 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Pending Offers
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Review and approve new offers before they go live.
        </p>
      </header>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : offers.length === 0 ? (
        <EmptyState
          icon="🎉"
          title="No pending offers"
          body="All caught up. New offer submissions will appear here."
        />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {offers.map((o) => (
            <OfferCard
              key={o.id}
              offer={o}
              working={working[o.id]}
              onApprove={() => handleApprove(o)}
              onReject={() => handleReject(o)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function OfferCard({ offer, working, onApprove, onReject }) {
  const savings = (offer.originalPrice || 0) - (offer.offerPrice || 0);
  const percentOff =
    offer.originalPrice > 0
      ? Math.round((savings / offer.originalPrice) * 100)
      : 0;

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
              marginBottom: 6,
            }}
          >
            {offer.title}
          </div>
          <div
            style={{
              fontSize: 13,
              color: '#6B7280',
              fontWeight: 600,
              marginBottom: 10,
            }}
          >
            {offer.businessName}
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <Tag color="#EFF6FF" textColor="#1E4B8F">
              {offer.type?.toUpperCase() || 'STANDARD'}
            </Tag>
            <Tag color="#E5F5EA" textColor="#2E9E5B">
              {percentOff}% OFF
            </Tag>
            <Tag color="#FFF3D6" textColor="#A67920">
              PENDING
            </Tag>
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

      {/* Price row */}
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-end',
          gap: 12,
          padding: 14,
          background: '#F6F3EE',
          borderRadius: 12,
          marginBottom: 14,
        }}
      >
        <div>
          <div
            style={{
              fontSize: 10,
              fontWeight: 800,
              color: '#9CA3AF',
              letterSpacing: 0.5,
            }}
          >
            ORIGINAL
          </div>
          <div
            style={{
              fontSize: 14,
              color: '#9CA3AF',
              textDecoration: 'line-through',
            }}
          >
            {offer.currency} {offer.originalPrice}
          </div>
        </div>
        <div style={{ fontSize: 20, color: '#D4A13A' }}>→</div>
        <div>
          <div
            style={{
              fontSize: 10,
              fontWeight: 800,
              color: '#9CA3AF',
              letterSpacing: 0.5,
            }}
          >
            MIGO PRICE
          </div>
          <div
            style={{
              fontSize: 22,
              fontWeight: 900,
              color: '#0B2B5B',
              lineHeight: 1,
            }}
          >
            {offer.currency} {offer.offerPrice}
          </div>
        </div>
        <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 800,
              color: '#9CA3AF',
              letterSpacing: 0.5,
            }}
          >
            CUSTOMER SAVES
          </div>
          <div
            style={{
              fontSize: 16,
              fontWeight: 900,
              color: '#2E9E5B',
            }}
          >
            {offer.currency} {savings}
          </div>
        </div>
      </div>

      {/* Details grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
          gap: 12,
          fontSize: 13,
          color: '#374151',
        }}
      >
        <Field label="Category" value={offer.category} />
        <Field
          label="Duration"
          value={
            offer.startAt && offer.endAt
              ? `${formatDate(offer.startAt)} → ${formatDate(offer.endAt)}`
              : '—'
          }
        />
        <Field label="Daily limit" value={offer.dailyLimit || 'Unlimited'} />
        <Field label="Offer ID" value={offer.id} mono />
      </div>

      {offer.description && (
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
          {offer.description}
        </div>
      )}

      {offer.terms && (
        <div
          style={{
            marginTop: 8,
            padding: 12,
            background: '#FFF9E6',
            borderRadius: 10,
            fontSize: 12,
            color: '#A67920',
            lineHeight: 1.5,
          }}
        >
          <strong>Terms:</strong> {offer.terms}
        </div>
      )}
    </div>
  );
}

function formatDate(ts) {
  try {
    const d = ts.toDate ? ts.toDate() : new Date(ts);
    return d.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
    });
  } catch {
    return '—';
  }
}

function Tag({ children, color, textColor }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '3px 10px',
        borderRadius: 6,
        background: color,
        color: textColor,
        fontSize: 11,
        fontWeight: 800,
        letterSpacing: 0.5,
      }}
    >
      {children}
    </span>
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