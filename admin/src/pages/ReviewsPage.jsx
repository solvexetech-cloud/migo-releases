import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  orderBy,
  query,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const FILTERS = [
  { key: 'all', label: 'All' },
  { key: 'positive', label: '★ Positive (4-5)' },
  { key: 'negative', label: '⚠ Negative (1-3)' },
];

export default function ReviewsPage() {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const isMobile = useIsMobile();

  useEffect(() => {
    const q = query(
      collection(db, 'reviews'),
      orderBy('createdAt', 'desc'),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        const list = snap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            ...data,
            isPositive: data.isPositive ?? data.rating >= 4,
          };
        });
        setReviews(list);
        setLoading(false);
      },
      (err) => {
        console.error('Firestore error:', err);
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  const stats = useMemo(() => {
    if (reviews.length === 0) {
      return {
        total: 0,
        avg: 0,
        positive: 0,
        negative: 0,
        positivePercent: 0,
        distribution: [0, 0, 0, 0, 0],
      };
    }
    const total = reviews.length;
    const avg =
      reviews.reduce((s, r) => s + (r.rating || 0), 0) / total;
    const positive = reviews.filter((r) => (r.rating || 0) >= 4).length;
    const negative = total - positive;
    const distribution = [0, 0, 0, 0, 0];
    reviews.forEach((r) => {
      const idx = Math.min(5, Math.max(1, r.rating || 1)) - 1;
      distribution[4 - idx] += 1;
    });
    return {
      total,
      avg: avg.toFixed(1),
      positive,
      negative,
      positivePercent: ((positive / total) * 100).toFixed(0),
      distribution,
    };
  }, [reviews]);

  const filtered = useMemo(() => {
    let list = reviews;
    if (filter === 'positive')
      list = list.filter((r) => (r.rating || 0) >= 4);
    if (filter === 'negative')
      list = list.filter((r) => (r.rating || 0) < 4);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (r) =>
          (r.businessName || '').toLowerCase().includes(q) ||
          (r.userName || '').toLowerCase().includes(q) ||
          (r.comment || '').toLowerCase().includes(q),
      );
    }
    return list;
  }, [reviews, filter, search]);

  async function handleDelete(review) {
    if (
      !confirm(
        `Delete this review?\n\n${review.userName || 'User'} — ${review.rating}★\n"${review.comment || ''}"`,
      )
    ) {
      return;
    }
    try {
      await deleteDoc(doc(db, 'reviews', review.id));
    } catch (e) {
      alert('Failed to delete: ' + e.message);
    }
  }

  return (
    <div
      style={{
        padding: isMobile ? 16 : 32,
        maxWidth: 1300,
      }}
    >
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
          Reviews
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Manage customer reviews across all businesses.
        </p>
      </header>

      {/* Stats */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile
            ? '1fr 1fr'
            : 'repeat(auto-fit, minmax(160px, 1fr))',
          gap: 14,
          marginBottom: 24,
        }}
      >
        <StatCard label="TOTAL" value={stats.total} color="#0B2B5B" bg="#EFF6FF" />
        <StatCard
          label="AVG RATING"
          value={`${stats.avg} ★`}
          color="#A67920"
          bg="#FFF3D6"
        />
        <StatCard
          label="POSITIVE"
          value={`${stats.positive} (${stats.positivePercent}%)`}
          color="#2E9E5B"
          bg="#E5F5EA"
        />
        <StatCard
          label="NEGATIVE"
          value={stats.negative}
          color="#D64545"
          bg="#FEE2E2"
        />
      </div>

      {/* Rating Distribution */}
      <div
        style={{
          background: 'white',
          borderRadius: 14,
          padding: 20,
          boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
          marginBottom: 20,
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
          Rating Distribution
        </div>
        {[5, 4, 3, 2, 1].map((star, i) => {
          const count = stats.distribution[i];
          const percent =
            stats.total > 0 ? (count / stats.total) * 100 : 0;
          return (
            <div
              key={star}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                marginBottom: 8,
              }}
            >
              <div
                style={{
                  width: 40,
                  fontSize: 13,
                  fontWeight: 800,
                  color: '#374151',
                }}
              >
                {star}★
              </div>
              <div
                style={{
                  flex: 1,
                  height: 8,
                  background: '#F1EEEA',
                  borderRadius: 4,
                  overflow: 'hidden',
                }}
              >
                <div
                  style={{
                    width: `${percent}%`,
                    height: '100%',
                    background:
                      star >= 4 ? '#2E9E5B' : star === 3 ? '#A67920' : '#D64545',
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
                  color: '#6B7280',
                }}
              >
                {count}
              </div>
            </div>
          );
        })}
      </div>

      {/* Filters + Search */}
      <div
        style={{
          display: 'flex',
          gap: 10,
          marginBottom: 20,
          flexWrap: 'wrap',
          alignItems: 'center',
        }}
      >
        {FILTERS.map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            style={{
              padding: '8px 16px',
              borderRadius: 8,
              border: 'none',
              background: filter === f.key ? '#0B2B5B' : 'white',
              color: filter === f.key ? 'white' : '#374151',
              fontSize: 13,
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
            }}
          >
            {f.label}
          </button>
        ))}
        <input
          type="text"
          placeholder="Search business, user, comment..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            minWidth: 200,
            padding: '10px 14px',
            borderRadius: 10,
            border: '1px solid #E5E7EB',
            fontSize: 13,
            outline: 'none',
            background: 'white',
          }}
        />
      </div>

      {/* Reviews list */}
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
          No reviews found.
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {filtered.map((r) => (
            <ReviewCard
              key={r.id}
              review={r}
              isMobile={isMobile}
              onDelete={() => handleDelete(r)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ---------- Components ----------
function StatCard({ label, value, color, bg }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: 18,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div
        style={{
          display: 'inline-block',
          padding: '3px 9px',
          borderRadius: 6,
          background: bg,
          color,
          fontSize: 10,
          fontWeight: 900,
          letterSpacing: 0.5,
          marginBottom: 8,
        }}
      >
        {label}
      </div>
      <div style={{ fontSize: 22, fontWeight: 900, color: '#0B2B5B' }}>
        {value}
      </div>
    </div>
  );
}

function ReviewCard({ review, isMobile, onDelete }) {
  const rating = review.rating || 0;
  const isPositive = rating >= 4;
  const createdAt = review.createdAt?.toDate?.();

  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: isMobile ? 16 : 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
        borderLeft: `4px solid ${isPositive ? '#2E9E5B' : '#D64545'}`,
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: 12,
          flexWrap: 'wrap',
          marginBottom: 10,
        }}
      >
        <div style={{ flex: 1, minWidth: 200 }}>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              flexWrap: 'wrap',
              marginBottom: 6,
            }}
          >
            <div style={{ fontSize: 16, color: '#F0C566', letterSpacing: 2 }}>
              {'★'.repeat(rating)}
              <span style={{ color: '#E5E7EB' }}>
                {'★'.repeat(5 - rating)}
              </span>
            </div>
            <Tag
              bg={isPositive ? '#E5F5EA' : '#FEE2E2'}
              fg={isPositive ? '#2E9E5B' : '#D64545'}
            >
              {isPositive ? 'POSITIVE' : 'NEGATIVE'}
            </Tag>
          </div>
          <div
            style={{
              fontSize: 13,
              color: '#6B7280',
              display: 'flex',
              gap: 12,
              flexWrap: 'wrap',
            }}
          >
            <span>
              <strong style={{ color: '#0B2B5B' }}>
                {review.businessName || '—'}
              </strong>
            </span>
            <span>by {review.userName || 'Anonymous'}</span>
            {createdAt && (
              <span>{createdAt.toLocaleDateString()}</span>
            )}
          </div>
        </div>

        <button
          onClick={onDelete}
          style={{
            padding: '7px 12px',
            borderRadius: 7,
            border: 'none',
            background: '#D6454515',
            color: '#D64545',
            fontSize: 11,
            fontWeight: 800,
            cursor: 'pointer',
          }}
        >
          Delete
        </button>
      </div>

      {review.comment && (
        <div
          style={{
            marginTop: 12,
            padding: 12,
            background: '#F6F3EE',
            borderRadius: 10,
            fontSize: 13,
            color: '#374151',
            lineHeight: 1.5,
            fontStyle: 'italic',
          }}
        >
          "{review.comment}"
        </div>
      )}
    </div>
  );
}

function Tag({ children, bg, fg }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '3px 10px',
        borderRadius: 6,
        background: bg,
        color: fg,
        fontSize: 10,
        fontWeight: 800,
        letterSpacing: 0.5,
      }}
    >
      {children}
    </span>
  );
}