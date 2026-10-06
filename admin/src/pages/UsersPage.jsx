import { useEffect, useMemo, useState } from 'react';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const isMobile = useIsMobile();

  useEffect(() => {
    const q = query(collection(db, 'users'));
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.coins || 0) - (a.coins || 0));
      setUsers(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const filtered = useMemo(() => {
    if (!search.trim()) return users;
    const q = search.trim().toLowerCase();
    return users.filter(
      (u) =>
        (u.email || '').toLowerCase().includes(q) ||
        (u.displayName || '').toLowerCase().includes(q) ||
        (u.referralCode || '').toLowerCase().includes(q) ||
        (u.city || '').toLowerCase().includes(q),
    );
  }, [users, search]);

  return (
    <div
      style={{
        padding: isMobile ? 16 : 32,
        maxWidth: 1200,
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
          Users
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          {users.length} total user{users.length !== 1 ? 's' : ''} on MIGO.
        </p>
      </header>

      {/* Search */}
      <div
        style={{
          background: 'white',
          borderRadius: 14,
          padding: '10px 16px',
          boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          marginBottom: 20,
        }}
      >
        <span style={{ fontSize: 16, color: '#9CA3AF' }}>🔍</span>
        <input
          type="text"
          placeholder="Search by email, name, city, or referral code…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            border: 'none',
            outline: 'none',
            fontSize: 14,
            background: 'transparent',
            padding: '6px 0',
            minWidth: 0,
          }}
        />
        {search && (
          <button
            onClick={() => setSearch('')}
            style={{
              border: 'none',
              background: 'transparent',
              cursor: 'pointer',
              fontSize: 18,
              color: '#9CA3AF',
            }}
          >
            ×
          </button>
        )}
      </div>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : filtered.length === 0 ? (
        <div
          style={{
            background: 'white',
            borderRadius: 16,
            padding: 48,
            textAlign: 'center',
            color: '#6B7280',
          }}
        >
          {search ? 'No users match your search.' : 'No users yet.'}
        </div>
      ) : (
        <div
          style={{
            background: 'white',
            borderRadius: 16,
            boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
            overflow: 'hidden',
          }}
        >
          {/* Header row — desktop only */}
          {!isMobile && (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '2fr 1fr 1fr 1fr 1fr 1fr',
                padding: '14px 20px',
                background: '#F6F3EE',
                fontSize: 11,
                fontWeight: 800,
                color: '#6B7280',
                letterSpacing: 0.5,
                borderBottom: '1px solid #ECE7DE',
              }}
            >
              <div>USER</div>
              <div>COINS</div>
              <div>LOYALTY</div>
              <div>CITY</div>
              <div>ROLE</div>
              <div>REFERRAL</div>
            </div>
          )}

          {/* Data rows — Card on mobile, Grid on desktop */}
          {isMobile
            ? filtered.map((u, i) => (
                <MobileUserCard
                  key={u.id}
                  user={u}
                  isLast={i === filtered.length - 1}
                />
              ))
            : filtered.map((u, i) => (
                <div
                  key={u.id}
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '2fr 1fr 1fr 1fr 1fr 1fr',
                    padding: '16px 20px',
                    fontSize: 13,
                    color: '#374151',
                    borderBottom:
                      i < filtered.length - 1
                        ? '1px solid #F1EEEA'
                        : 'none',
                    alignItems: 'center',
                  }}
                >
                  <div style={{ minWidth: 0 }}>
                    <div
                      style={{
                        fontWeight: 800,
                        color: '#0B2B5B',
                        marginBottom: 2,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      {u.email || '—'}
                    </div>
                    {u.displayName && (
                      <div
                        style={{
                          fontSize: 11,
                          color: '#9CA3AF',
                        }}
                      >
                        {u.displayName}
                      </div>
                    )}
                  </div>

                  <div
                    style={{
                      fontWeight: 900,
                      color: '#D4A13A',
                      fontSize: 15,
                    }}
                  >
                    {u.coins ?? 0}
                  </div>

                  <div style={{ fontWeight: 600 }}>
                    {u.loyaltyLevel || 'Bronze'}
                  </div>

                  <div>{u.city || '—'}</div>

                  <div>
                    <RoleBadge role={u.role || 'customer'} />
                  </div>

                  <div
                    style={{
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: '#6B7280',
                    }}
                  >
                    {u.referralCode || '—'}
                  </div>
                </div>
              ))}
        </div>
      )}
    </div>
  );
}

function MobileUserCard({ user, isLast }) {
  return (
    <div
      style={{
        padding: 16,
        borderBottom: isLast ? 'none' : '1px solid #F1EEEA',
      }}
    >
      {/* Row 1: Email + Role */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: 10,
          marginBottom: 10,
        }}
      >
        <div style={{ flex: 1, minWidth: 0 }}>
          <div
            style={{
              fontSize: 14,
              fontWeight: 800,
              color: '#0B2B5B',
              wordBreak: 'break-word',
              marginBottom: 3,
            }}
          >
            {user.email || '—'}
          </div>
          {user.displayName && (
            <div style={{ fontSize: 12, color: '#6B7280' }}>
              {user.displayName}
            </div>
          )}
        </div>
        <RoleBadge role={user.role || 'customer'} />
      </div>

      {/* Row 2: Stats grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr 1fr',
          gap: 10,
          padding: 10,
          background: '#F6F3EE',
          borderRadius: 10,
          marginBottom: 10,
        }}
      >
        <div>
          <div
            style={{
              fontSize: 9,
              fontWeight: 800,
              color: '#9CA3AF',
              letterSpacing: 0.5,
              marginBottom: 3,
            }}
          >
            COINS
          </div>
          <div
            style={{
              fontSize: 16,
              fontWeight: 900,
              color: '#D4A13A',
            }}
          >
            {user.coins ?? 0}
          </div>
        </div>
        <div>
          <div
            style={{
              fontSize: 9,
              fontWeight: 800,
              color: '#9CA3AF',
              letterSpacing: 0.5,
              marginBottom: 3,
            }}
          >
            LOYALTY
          </div>
          <div
            style={{
              fontSize: 13,
              fontWeight: 700,
              color: '#374151',
            }}
          >
            {user.loyaltyLevel || 'Bronze'}
          </div>
        </div>
        <div>
          <div
            style={{
              fontSize: 9,
              fontWeight: 800,
              color: '#9CA3AF',
              letterSpacing: 0.5,
              marginBottom: 3,
            }}
          >
            CITY
          </div>
          <div
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: '#374151',
            }}
          >
            {user.city || '—'}
          </div>
        </div>
      </div>

      {/* Row 3: Referral */}
      {user.referralCode && (
        <div
          style={{
            fontSize: 11,
            color: '#6B7280',
          }}
        >
          <strong>Referral:</strong>{' '}
          <span style={{ fontFamily: 'monospace' }}>
            {user.referralCode}
          </span>
        </div>
      )}
    </div>
  );
}

function RoleBadge({ role }) {
  const colors = {
    admin: { bg: '#FEE2E2', fg: '#D64545' },
    business: { bg: '#EFF6FF', fg: '#1E4B8F' },
    creator: { bg: '#FFF3D6', fg: '#A67920' },
    customer: { bg: '#E5F5EA', fg: '#2E9E5B' },
  };
  const c = colors[role] || colors.customer;
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '3px 10px',
        borderRadius: 6,
        background: c.bg,
        color: c.fg,
        fontSize: 10,
        fontWeight: 800,
        letterSpacing: 0.5,
        textTransform: 'uppercase',
        whiteSpace: 'nowrap',
      }}
    >
      {role}
    </span>
  );
}