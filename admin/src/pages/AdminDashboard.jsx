import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  collection,
  getCountFromServer,
  query,
  where,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

export default function AdminDashboard() {
  const [stats, setStats] = useState({
    users: 0,
    businesses: 0,
    pendingBusinesses: 0,
    offers: 0,
    pendingOffers: 0,
    claims: 0,
  });
  const [loading, setLoading] = useState(true);
  const isMobile = useIsMobile();

  useEffect(() => {
    async function load() {
      try {
        const [
          usersCount,
          bizCount,
          pendingBiz,
          offersCount,
          pendingOffers,
          claimsCount,
        ] = await Promise.all([
          getCountFromServer(collection(db, 'users')),
          getCountFromServer(collection(db, 'businesses')),
          getCountFromServer(
            query(
              collection(db, 'businesses'),
              where('status', '==', 'pending'),
            ),
          ),
          getCountFromServer(collection(db, 'offers')),
          getCountFromServer(
            query(
              collection(db, 'offers'),
              where('status', '==', 'pending'),
            ),
          ),
          getCountFromServer(collection(db, 'claims')),
        ]);

        setStats({
          users: usersCount.data().count,
          businesses: bizCount.data().count,
          pendingBusinesses: pendingBiz.data().count,
          offers: offersCount.data().count,
          pendingOffers: pendingOffers.data().count,
          claims: claimsCount.data().count,
        });
      } catch (err) {
        console.error('Stats load failed:', err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  return (
    <div
  style={{
    padding: isMobile ? 16 : 32,
    maxWidth: 1200,
  }}
>
      <header style={{ marginBottom: 28 }}>
        <h1
          style={{
            fontSize: 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Dashboard
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Welcome to the MIGO Admin Panel.
        </p>
      </header>

      {/* Alerts */}
      {(stats.pendingBusinesses > 0 || stats.pendingOffers > 0) && (
        <div
          style={{
            display: 'flex',
            gap: 12,
            marginBottom: 24,
            flexWrap: 'wrap',
          }}
        >
          {stats.pendingBusinesses > 0 && (
            <Link
              to="/businesses"
              style={{
                padding: '12px 18px',
                background: '#FFF3D6',
                border: '1px solid #F0C566',
                borderRadius: 12,
                color: '#A67920',
                fontSize: 14,
                fontWeight: 800,
                textDecoration: 'none',
              }}
            >
              ⚠️ {stats.pendingBusinesses} business
              {stats.pendingBusinesses > 1 ? 'es' : ''} need approval →
            </Link>
          )}
          {stats.pendingOffers > 0 && (
            <Link
              to="/offers"
              style={{
                padding: '12px 18px',
                background: '#FFF3D6',
                border: '1px solid #F0C566',
                borderRadius: 12,
                color: '#A67920',
                fontSize: 14,
                fontWeight: 800,
                textDecoration: 'none',
              }}
            >
              ⚠️ {stats.pendingOffers} offer
              {stats.pendingOffers > 1 ? 's' : ''} need approval →
            </Link>
          )}
        </div>
      )}

      {loading ? (
        <div style={{ padding: 40, color: '#6B7280' }}>Loading…</div>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns:
              'repeat(auto-fill, minmax(220px, 1fr))',
            gap: 16,
          }}
        >
          <StatCard
            label="Total users"
            value={stats.users}
            icon="👥"
            color="#0B2B5B"
          />
          <StatCard
            label="Businesses"
            value={stats.businesses}
            icon="🏪"
            color="#1E4B8F"
            sub={
              stats.pendingBusinesses > 0
                ? `${stats.pendingBusinesses} pending`
                : null
            }
          />
          <StatCard
            label="Offers"
            value={stats.offers}
            icon="🏷️"
            color="#2E9E5B"
            sub={
              stats.pendingOffers > 0
                ? `${stats.pendingOffers} pending`
                : null
            }
          />
          <StatCard
            label="Claims"
            value={stats.claims}
            icon="🎫"
            color="#D4A13A"
          />
        </div>
      )}
    </div>
  );
}

function StatCard({ label, value, icon, color, sub }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div style={{ fontSize: 28, marginBottom: 12 }}>{icon}</div>
      <div
        style={{
          fontSize: 32,
          fontWeight: 900,
          color,
          lineHeight: 1,
          letterSpacing: -1,
        }}
      >
        {value}
      </div>
      <div
        style={{
          fontSize: 13,
          fontWeight: 700,
          color: '#6B7280',
          marginTop: 6,
        }}
      >
        {label}
      </div>
      {sub && (
        <div
          style={{
            fontSize: 11,
            fontWeight: 700,
            color: '#D4A13A',
            marginTop: 8,
          }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}