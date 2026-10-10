import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  limit,
  onSnapshot,
  orderBy,
  query,
  where,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const RANGE_FILTERS = [
  { key: '7d', label: 'Last 7 days', days: 7 },
  { key: '30d', label: 'Last 30 days', days: 30 },
  { key: '90d', label: 'Last 90 days', days: 90 },
  { key: 'all', label: 'All time', days: null },
];

const EVENT_COLORS = {
  view_offer: '#1E4B8F',
  search: '#A67920',
  save_offer: '#2E9E5B',
  save_business: '#7C3AED',
  view_business: '#0E7490',
  claim: '#D64545',
  redeem: '#2E9E5B',
};

export default function AnalyticsPage() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [range, setRange] = useState('7d');
  const isMobile = useIsMobile();

  useEffect(() => {
    // Load most recent 1000 events (Firestore limit)
    const q = query(
      collection(db, 'customer_behavior'),
      orderBy('timestamp', 'desc'),
      limit(1000),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        setEvents(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      (err) => {
        console.error(err);
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  // Filter by time range
  const filtered = useMemo(() => {
    const def = RANGE_FILTERS.find((r) => r.key === range);
    if (!def || def.days === null) return events;
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - def.days);
    return events.filter((e) => {
      const ts = e.timestamp?.toDate?.();
      return ts && ts >= cutoff;
    });
  }, [events, range]);

  // Stats
  const stats = useMemo(() => {
    const total = filtered.length;
    const uniqueUsers = new Set(filtered.map((e) => e.userUid)).size;
    const eventsByType = {};
    const byCategory = {};
    const byBusiness = {};
    const byHour = Array(24).fill(0);
    const searches = {};

    filtered.forEach((e) => {
      // By type
      eventsByType[e.eventType] = (eventsByType[e.eventType] || 0) + 1;

      // By category
      if (e.category) {
        byCategory[e.category] = (byCategory[e.category] || 0) + 1;
      }

      // By business
      if (e.businessId) {
        byBusiness[e.businessId] = (byBusiness[e.businessId] || 0) + 1;
      }

      // By hour
      const ts = e.timestamp?.toDate?.();
      if (ts) byHour[ts.getHours()]++;

      // Searches
      if (e.eventType === 'search' && e.query) {
        const q = e.query.toLowerCase().trim();
        if (q) searches[q] = (searches[q] || 0) + 1;
      }
    });

    const topCategory =
      Object.entries(byCategory).sort((a, b) => b[1] - a[1])[0]?.[0] || '—';

    return { total, uniqueUsers, eventsByType, byCategory, byBusiness, byHour, searches, topCategory };
  }, [filtered]);

  // Convert to sorted arrays
  const topCategories = useMemo(
    () =>
      Object.entries(stats.byCategory)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8),
    [stats.byCategory],
  );

  const topSearches = useMemo(
    () =>
      Object.entries(stats.searches)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10),
    [stats.searches],
  );

  const eventsByTypeList = useMemo(
    () =>
      Object.entries(stats.eventsByType).sort((a, b) => b[1] - a[1]),
    [stats.eventsByType],
  );

  const maxEventCount = Math.max(
    1,
    ...eventsByTypeList.map(([, v]) => v),
  );
  const maxCategoryCount = Math.max(1, ...topCategories.map(([, v]) => v));
  const maxHourCount = Math.max(1, ...stats.byHour);

  return (
    <div style={{ padding: isMobile ? 16 : 32, maxWidth: 1400 }}>
      <header style={{ marginBottom: 20 }}>
        <h1
          style={{
            fontSize: 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Analytics
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Customer behavior insights ({filtered.length} events)
        </p>
      </header>

      {/* Range filter */}
      <div
        style={{
          display: 'flex',
          gap: 8,
          marginBottom: 20,
          flexWrap: 'wrap',
        }}
      >
        {RANGE_FILTERS.map((r) => (
          <button
            key={r.key}
            onClick={() => setRange(r.key)}
            style={{
              padding: '8px 16px',
              borderRadius: 8,
              border: 'none',
              background: range === r.key ? '#0B2B5B' : 'white',
              color: range === r.key ? 'white' : '#374151',
              fontSize: 13,
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
            }}
          >
            {r.label}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : filtered.length === 0 ? (
        <div
          style={{
            background: 'white',
            borderRadius: 14,
            padding: 48,
            textAlign: 'center',
            color: '#6B7280',
          }}
        >
          No events yet. Data will appear as users interact with the app.
        </div>
      ) : (
        <>
          {/* Stats cards */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: isMobile
                ? '1fr 1fr'
                : 'repeat(auto-fit, minmax(200px, 1fr))',
              gap: 12,
              marginBottom: 20,
            }}
          >
            <StatCard
              label="TOTAL EVENTS"
              value={stats.total}
              color="#1E4B8F"
              bg="#EFF6FF"
            />
            <StatCard
              label="UNIQUE USERS"
              value={stats.uniqueUsers}
              color="#2E9E5B"
              bg="#E5F5EA"
            />
            <StatCard
              label="TOP CATEGORY"
              value={stats.topCategory}
              color="#A67920"
              bg="#FFF3D6"
            />
            <StatCard
              label="AVG / USER"
              value={
                stats.uniqueUsers > 0
                  ? (stats.total / stats.uniqueUsers).toFixed(1)
                  : 0
              }
              color="#7C3AED"
              bg="#F3E8FF"
            />
          </div>

          {/* Events by type */}
          <Section title="Events by Type">
            {eventsByTypeList.map(([type, count]) => (
              <BarRow
                key={type}
                label={type.replace('_', ' ')}
                value={count}
                max={maxEventCount}
                color={EVENT_COLORS[type] || '#6B7280'}
              />
            ))}
          </Section>

          {/* Top categories */}
          <Section title="Top Categories">
            {topCategories.length === 0 ? (
              <div style={{ fontSize: 13, color: '#9CA3AF' }}>
                No category data.
              </div>
            ) : (
              topCategories.map(([cat, count]) => (
                <BarRow
                  key={cat}
                  label={cat}
                  value={count}
                  max={maxCategoryCount}
                  color="#1E4B8F"
                />
              ))
            )}
          </Section>

          {/* Peak hours */}
          <Section title="Peak Hours (24h)">
            <div
              style={{
                display: 'flex',
                alignItems: 'flex-end',
                gap: 2,
                height: 100,
                paddingTop: 8,
              }}
            >
              {stats.byHour.map((count, hour) => {
                const height = (count / maxHourCount) * 90;
                return (
                  <div
                    key={hour}
                    style={{
                      flex: 1,
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      gap: 4,
                    }}
                    title={`${hour}:00 — ${count} events`}
                  >
                    <div
                      style={{
                        width: '100%',
                        height: Math.max(2, height),
                        background:
                          count > 0 ? '#D4A13A' : '#F1EEEA',
                        borderRadius: 3,
                        transition: 'height 0.3s',
                      }}
                    />
                    {hour % 3 === 0 && (
                      <div
                        style={{
                          fontSize: 9,
                          color: '#9CA3AF',
                          fontWeight: 700,
                        }}
                      >
                        {hour}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </Section>

          {/* Top searches */}
          <Section title="Top Searches">
            {topSearches.length === 0 ? (
              <div style={{ fontSize: 13, color: '#9CA3AF' }}>
                No search data yet.
              </div>
            ) : (
              <div
                style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: 6,
                }}
              >
                {topSearches.map(([q, count], i) => (
                  <span
                    key={q}
                    style={{
                      padding: '6px 12px',
                      borderRadius: 8,
                      background: i === 0 ? '#FFF3D6' : '#F6F3EE',
                      color: i === 0 ? '#A67920' : '#374151',
                      fontSize: 12,
                      fontWeight: 700,
                    }}
                  >
                    {q} <span style={{ color: '#9CA3AF' }}>×{count}</span>
                  </span>
                ))}
              </div>
            )}
          </Section>

          {/* Info footer */}
          <div
            style={{
              fontSize: 11,
              color: '#9CA3AF',
              textAlign: 'center',
              marginTop: 20,
            }}
          >
            Showing latest 1000 events · {RANGE_FILTERS.find((r) => r.key === range)?.label}
          </div>
        </>
      )}
    </div>
  );
}

function StatCard({ label, value, color, bg }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 12,
        padding: 16,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div
        style={{
          display: 'inline-block',
          padding: '2px 8px',
          borderRadius: 5,
          background: bg,
          color,
          fontSize: 10,
          fontWeight: 900,
          letterSpacing: 0.5,
          marginBottom: 6,
        }}
      >
        {label}
      </div>
      <div
        style={{
          fontSize: 22,
          fontWeight: 900,
          color: '#0B2B5B',
          textTransform: 'capitalize',
        }}
      >
        {value}
      </div>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
        marginBottom: 16,
      }}
    >
      <div
        style={{
          fontSize: 14,
          fontWeight: 900,
          color: '#0B2B5B',
          marginBottom: 14,
          letterSpacing: 0.3,
        }}
      >
        {title}
      </div>
      {children}
    </div>
  );
}

function BarRow({ label, value, max, color }) {
  const percent = (value / max) * 100;
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginBottom: 8,
      }}
    >
      <div
        style={{
          width: 110,
          fontSize: 12,
          fontWeight: 700,
          color: '#374151',
          textTransform: 'capitalize',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
        }}
        title={label}
      >
        {label}
      </div>
      <div
        style={{
          flex: 1,
          height: 10,
          background: '#F1EEEA',
          borderRadius: 5,
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            width: `${percent}%`,
            height: '100%',
            background: color,
            transition: 'width 0.3s',
          }}
        />
      </div>
      <div
        style={{
          width: 40,
          textAlign: 'right',
          fontSize: 12,
          fontWeight: 800,
          color: '#0B2B5B',
        }}
      >
        {value}
      </div>
    </div>
  );
}