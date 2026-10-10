import { useEffect, useMemo, useState } from 'react';
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

function makeIcon(color) {
  return L.divIcon({
    className: 'migo-marker',
    html: `<div style="width:28px;height:28px;border-radius:50% 50% 50% 0;background:${color};border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.3);transform:rotate(-45deg);"></div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 28],
    popupAnchor: [0, -28],
  });
}

const STATUS_COLORS = {
  approved: '#2E9E5B',
  pending: '#A67920',
  suspended: '#D64545',
  rejected: '#D64545',
};

const DOHA_CENTER = [25.2854, 51.531];

export default function BusinessesMapPage() {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const isMobile = useIsMobile();

  useEffect(() => {
    const q = query(collection(db, 'businesses'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(
      q,
      (snap) => {
        setBusinesses(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      () => setLoading(false),
    );
    return () => unsub();
  }, []);

  const withCoords = useMemo(
    () => businesses.filter((b) => b.lat && b.lng),
    [businesses],
  );

  const filtered = useMemo(() => {
    let list = withCoords;
    if (filter !== 'all') list = list.filter((b) => b.status === filter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (b) =>
          (b.name || '').toLowerCase().includes(q) ||
          (b.category || '').toLowerCase().includes(q) ||
          (b.city || '').toLowerCase().includes(q),
      );
    }
    return list;
  }, [withCoords, filter, search]);

  const stats = useMemo(() => {
    const counts = { approved: 0, pending: 0, suspended: 0, rejected: 0 };
    withCoords.forEach((b) => {
      if (counts[b.status] != null) counts[b.status]++;
    });
    return counts;
  }, [withCoords]);

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
          Business Map
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          {withCoords.length} businesses with location · {filtered.length} shown
        </p>
      </header>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile ? '1fr 1fr' : 'repeat(4, 1fr)',
          gap: 10,
          marginBottom: 16,
        }}
      >
        <StatCard label="APPROVED" value={stats.approved} color="#2E9E5B" bg="#E5F5EA" />
        <StatCard label="PENDING" value={stats.pending} color="#A67920" bg="#FFF3D6" />
        <StatCard label="SUSPENDED" value={stats.suspended} color="#D64545" bg="#FEE2E2" />
        <StatCard label="TOTAL" value={withCoords.length} color="#1E4B8F" bg="#EFF6FF" />
      </div>

      <div
        style={{
          display: 'flex',
          gap: 10,
          marginBottom: 16,
          flexWrap: 'wrap',
          alignItems: 'center',
        }}
      >
        {['all', 'approved', 'pending', 'suspended'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            style={{
              padding: '8px 16px',
              borderRadius: 8,
              border: 'none',
              background: filter === f ? '#0B2B5B' : 'white',
              color: filter === f ? 'white' : '#374151',
              fontSize: 13,
              fontWeight: 700,
              cursor: 'pointer',
              textTransform: 'capitalize',
              boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
            }}
          >
            {f}
          </button>
        ))}
        <input
          type="text"
          placeholder="Search business, category, city..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            minWidth: 220,
            padding: '10px 14px',
            borderRadius: 10,
            border: '1px solid #E5E7EB',
            fontSize: 13,
            outline: 'none',
            background: 'white',
          }}
        />
      </div>

      <div
        style={{
          background: 'white',
          borderRadius: 14,
          overflow: 'hidden',
          boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
          height: isMobile ? 480 : 640,
        }}
      >
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: '#6B7280' }}>
            Loading map…
          </div>
        ) : (
          <MapContainer
            center={DOHA_CENTER}
            zoom={12}
            style={{ height: '100%', width: '100%' }}
            scrollWheelZoom
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
              maxZoom={19}
            />

            {filtered.map((b) => {
              const color = STATUS_COLORS[b.status] || '#6B7280';
              return (
                <Marker key={b.id} position={[b.lat, b.lng]} icon={makeIcon(color)}>
                  <Popup>
                    <div style={{ minWidth: 180 }}>
                      <div
                        style={{
                          fontWeight: 900,
                          fontSize: 14,
                          color: '#0B2B5B',
                          marginBottom: 4,
                        }}
                      >
                        {b.name}
                      </div>
                      <div
                        style={{
                          fontSize: 11,
                          color: '#6B7280',
                          marginBottom: 6,
                          textTransform: 'capitalize',
                        }}
                      >
                        {b.category} · {b.status}
                      </div>
                      {b.addressLine && (
                        <div style={{ fontSize: 12, color: '#374151' }}>
                          📍 {b.addressLine}
                        </div>
                      )}
                      {b.phone && (
                        <div style={{ fontSize: 12, color: '#374151' }}>
                          📞 {b.phone}
                        </div>
                      )}
                      <div style={{ fontSize: 10, color: '#9CA3AF', marginTop: 6 }}>
                        {b.lat.toFixed(4)}, {b.lng.toFixed(4)}
                      </div>
                    </div>
                  </Popup>
                </Marker>
              );
            })}
          </MapContainer>
        )}
      </div>

      {filtered.length === 0 && !loading && (
        <div
          style={{
            background: 'white',
            borderRadius: 14,
            padding: 32,
            marginTop: 12,
            textAlign: 'center',
            color: '#6B7280',
            fontSize: 13,
          }}
        >
          No businesses match your filters.
        </div>
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
        padding: 14,
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
      <div style={{ fontSize: 22, fontWeight: 900, color: '#0B2B5B' }}>{value}</div>
    </div>
  );
}