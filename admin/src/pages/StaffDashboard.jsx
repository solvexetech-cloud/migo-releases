import { useEffect, useState } from 'react';
import {
  collection,
  query,
  where,
  onSnapshot,
  orderBy,
  limit,
} from 'firebase/firestore';
import { Link } from 'react-router-dom';
import { db } from '../firebase';
import { useRole } from '../contexts/RoleContext';

export default function StaffDashboard() {
  const { user } = useRole();
  const [pendingBusinesses, setPendingBusinesses] = useState([]);
  const [pendingOffers, setPendingOffers] = useState([]);
  const [recentReviews, setRecentReviews] = useState([]);
  const [recentFrauds, setRecentFrauds] = useState([]);
  const [loading, setLoading] = useState(true);

  // ─── Pending Businesses ───
  useEffect(() => {
    const q = query(
      collection(db, 'businesses'),
      where('status', '==', 'pending')
    );
    const unsub = onSnapshot(q, (snap) => {
      setPendingBusinesses(
        snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      );
    });
    return () => unsub();
  }, []);

  // ─── Pending Offers ───
  useEffect(() => {
    const q = query(
      collection(db, 'offers'),
      where('status', '==', 'pending')
    );
    const unsub = onSnapshot(q, (snap) => {
      setPendingOffers(
        snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      );
    });
    return () => unsub();
  }, []);

  // ─── Recent Reviews ───
  useEffect(() => {
    const q = query(
      collection(db, 'reviews'),
      orderBy('createdAt', 'desc'),
      limit(5)
    );
    const unsub = onSnapshot(q, (snap) => {
      setRecentReviews(
        snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      );
      setLoading(false);
    });
    return () => unsub();
  }, []);

  // ─── Recent Fraud Logs ───
  useEffect(() => {
    const q = query(
      collection(db, 'fraud_logs'),
      orderBy('createdAt', 'desc'),
      limit(5)
    );
    const unsub = onSnapshot(q, (snap) => {
      setRecentFrauds(
        snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      );
    });
    return () => unsub();
  }, []);

  if (loading) {
    return (
      <div
        style={{
          padding: 40,
          textAlign: 'center',
          color: '#666',
        }}
      >
        Loading staff dashboard...
      </div>
    );
  }

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
          Staff Dashboard
        </h1>
        <p style={{ color: '#666', fontSize: 14 }}>
          Moderation queue — {user?.email}
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
          label="Pending Businesses"
          value={pendingBusinesses.length}
          color="#F59E0B"
          icon="🏢"
          to="/pending-businesses"
        />
        <StatCard
          label="Pending Offers"
          value={pendingOffers.length}
          color="#3B82F6"
          icon="🎁"
          to="/offers"
        />
        <StatCard
          label="Recent Reviews"
          value={recentReviews.length}
          color="#10B981"
          icon="⭐"
          to="/reviews"
        />
        <StatCard
          label="Fraud Alerts"
          value={recentFrauds.length}
          color="#EF4444"
          icon="🚨"
          to="/fraud-logs"
        />
      </div>

      {/* Quick Actions */}
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
          ⚡ Quick Actions
        </h2>
        <div
          style={{
            display: 'flex',
            gap: 10,
            flexWrap: 'wrap',
          }}
        >
          <QuickAction to="/pending-businesses" icon="🏢">
            Review Businesses
          </QuickAction>
          <QuickAction to="/offers" icon="🎁">
            Review Offers
          </QuickAction>
          <QuickAction to="/reviews" icon="⭐">
            Moderate Reviews
          </QuickAction>
          <QuickAction to="/fraud-logs" icon="🚨">
            Check Fraud Logs
          </QuickAction>
        </div>
      </div>

      {/* Pending Businesses */}
      {pendingBusinesses.length > 0 && (
        <Section
          title={`⏳ Pending Businesses (${pendingBusinesses.length})`}
          linkTo="/pending-businesses"
          linkText="View all"
        >
          {pendingBusinesses.slice(0, 5).map((b) => (
            <ListItem
              key={b.id}
              title={b.name || 'Unnamed'}
              subtitle={`${b.category || '—'} • ${b.addressLine || '—'}`}
              badge="pending"
            />
          ))}
        </Section>
      )}

      {/* Pending Offers */}
      {pendingOffers.length > 0 && (
        <Section
          title={`⏳ Pending Offers (${pendingOffers.length})`}
          linkTo="/offers"
          linkText="View all"
        >
          {pendingOffers.slice(0, 5).map((o) => (
            <ListItem
              key={o.id}
              title={o.title || 'Untitled Offer'}
              subtitle={`${o.currency || ''} ${o.offerPrice || '—'} • ${o.type || '—'}`}
              badge="pending"
            />
          ))}
        </Section>
      )}

      {/* Recent Reviews */}
      {recentReviews.length > 0 && (
        <Section
          title={`⭐ Recent Reviews`}
          linkTo="/reviews"
          linkText="View all"
        >
          {recentReviews.slice(0, 5).map((r) => (
            <ListItem
              key={r.id}
              title={`${'⭐'.repeat(r.rating || 0)} — ${
                r.comment?.slice(0, 60) || '(no comment)'
              }`}
              subtitle={r.isPositive ? '✅ Positive' : '⚠️ Negative'}
              badge={r.isPositive ? 'approved' : 'rejected'}
            />
          ))}
        </Section>
      )}

      {/* Recent Fraud Logs */}
      {recentFrauds.length > 0 && (
        <Section
          title={`🚨 Recent Fraud Alerts`}
          linkTo="/fraud-logs"
          linkText="View all"
        >
          {recentFrauds.slice(0, 5).map((f) => (
            <ListItem
              key={f.id}
              title={f.reason?.replace(/_/g, ' ') || 'Unknown'}
              subtitle={`User: ${f.userUid?.slice(0, 12) || '—'}...`}
              badge={f.reviewed ? 'approved' : 'rejected'}
            />
          ))}
        </Section>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════

function StatCard({ label, value, color, icon, to }) {
  const inner = (
    <div
      style={{
        background: '#fff',
        padding: 16,
        borderRadius: 12,
        border: '1px solid #eee',
        borderLeft: `4px solid ${color}`,
        cursor: to ? 'pointer' : 'default',
        transition: 'all 0.15s',
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

  if (to) {
    return (
      <Link to={to} style={{ textDecoration: 'none' }}>
        {inner}
      </Link>
    );
  }
  return inner;
}

function QuickAction({ to, icon, children }) {
  return (
    <Link
      to={to}
      style={{
        padding: '10px 16px',
        borderRadius: 10,
        background: '#F6F3EE',
        color: '#0B2B5B',
        textDecoration: 'none',
        fontSize: 13,
        fontWeight: 700,
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        border: '1px solid #e5e5e5',
      }}
    >
      <span style={{ fontSize: 16 }}>{icon}</span>
      <span>{children}</span>
    </Link>
  );
}

function Section({ title, linkTo, linkText, children }) {
  return (
    <div
      style={{
        background: '#fff',
        padding: 20,
        borderRadius: 12,
        border: '1px solid #eee',
        marginBottom: 16,
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 12,
        }}
      >
        <h2
          style={{
            fontSize: 15,
            fontWeight: 800,
            color: '#333',
          }}
        >
          {title}
        </h2>
        {linkTo && (
          <Link
            to={linkTo}
            style={{
              fontSize: 12,
              color: '#3B82F6',
              textDecoration: 'none',
              fontWeight: 700,
            }}
          >
            {linkText || 'View all →'}
          </Link>
        )}
      </div>
      {children}
    </div>
  );
}

function ListItem({ title, subtitle, badge }) {
  const badgeColors = {
    pending: { bg: '#FEF3C7', text: '#92400E' },
    approved: { bg: '#D1FAE5', text: '#065F46' },
    rejected: { bg: '#FEE2E2', text: '#991B1B' },
  };
  const c = badgeColors[badge] || badgeColors.pending;

  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '10px 0',
        borderBottom: '1px solid #f5f5f5',
        gap: 12,
      }}
    >
      <div style={{ flex: 1, minWidth: 0 }}>
        <div
          style={{
            fontWeight: 700,
            fontSize: 13,
            color: '#333',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {title}
        </div>
        <div
          style={{
            color: '#888',
            fontSize: 11,
            marginTop: 2,
          }}
        >
          {subtitle}
        </div>
      </div>
      {badge && (
        <span
          style={{
            background: c.bg,
            color: c.text,
            padding: '3px 8px',
            borderRadius: 10,
            fontSize: 10,
            fontWeight: 700,
            textTransform: 'uppercase',
            flexShrink: 0,
          }}
        >
          {badge}
        </span>
      )}
    </div>
  );
}