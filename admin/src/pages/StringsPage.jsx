import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const LANGS = [
  { code: 'en', label: 'English', flag: '🇬🇧', rtl: false },
  { code: 'ar', label: 'العربية', flag: '🇸🇦', rtl: true },
];

export default function StringsPage() {
  const [strings, setStrings] = useState([]); // all lang_key docs
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [langFilter, setLangFilter] = useState('all');
  const [showMissing, setShowMissing] = useState(false);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const isMobile = useIsMobile();

  // Listen to app_strings
  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'app_strings'), orderBy('key', 'asc')),
      (snap) => {
        const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setStrings(list);
        setLoading(false);
      },
      () => setLoading(false),
    );
    return () => unsub();
  }, []);

  // Group by key
  const grouped = useMemo(() => {
    const map = {};
    strings.forEach((s) => {
      if (!map[s.key]) map[s.key] = {};
      map[s.key][s.lang] = { id: s.id, value: s.value };
    });
    return map;
  }, [strings]);

  // Keys with stats
  const allKeys = useMemo(() => {
    return Object.entries(grouped)
      .map(([key, langs]) => {
        const enVal = langs.en?.value || '';
        const arVal = langs.ar?.value || '';
        const missing = [];
        if (!enVal) missing.push('en');
        if (!arVal) missing.push('ar');
        return { key, en: enVal, ar: arVal, missing };
      })
      .sort((a, b) => a.key.localeCompare(b.key));
  }, [grouped]);

  // Filtered
  const filtered = useMemo(() => {
    let list = allKeys;

    if (showMissing) {
      list = list.filter((k) => k.missing.length > 0);
    }

    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (k) =>
          k.key.toLowerCase().includes(q) ||
          k.en.toLowerCase().includes(q) ||
          k.ar.toLowerCase().includes(q),
      );
    }

    return list;
  }, [allKeys, search, showMissing]);

  // Stats
  const stats = useMemo(() => {
    const total = allKeys.length;
    const enDone = allKeys.filter((k) => k.en).length;
    const arDone = allKeys.filter((k) => k.ar).length;
    const complete = allKeys.filter(
      (k) => k.en && k.ar,
    ).length;
    return { total, enDone, arDone, complete };
  }, [allKeys]);

  async function handleSave() {
    if (!editing) return;
    setSaving(true);
    try {
      // Update en
      if (editing.enId) {
        await updateDoc(doc(db, 'app_strings', editing.enId), {
          value: editing.enValue,
          updatedAt: serverTimestamp(),
        });
      }
      // Update ar
      if (editing.arId) {
        await updateDoc(doc(db, 'app_strings', editing.arId), {
          value: editing.arValue,
          updatedAt: serverTimestamp(),
        });
      }
      setEditing(null);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  function openEdit(row) {
    setEditing({
      key: row.key,
      enId: grouped[row.key]?.en?.id || null,
      arId: grouped[row.key]?.ar?.id || null,
      enValue: row.en || '',
      arValue: row.ar || '',
    });
  }

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
          App Strings
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Manage translations for English and Arabic.
        </p>
      </header>

      {/* Stats */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile
            ? '1fr 1fr'
            : 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 14,
          marginBottom: 20,
        }}
      >
        <StatCard label="TOTAL KEYS" value={stats.total} bg="#EFF6FF" fg="#1E4B8F" />
        <StatCard
          label="ENGLISH"
          value={`${stats.enDone}/${stats.total}`}
          bg="#E5F5EA"
          fg="#2E9E5B"
        />
        <StatCard
          label="ARABIC"
          value={`${stats.arDone}/${stats.total}`}
          bg="#FFF3D6"
          fg="#A67920"
        />
        <StatCard
          label="COMPLETE"
          value={`${stats.complete}/${stats.total}`}
          bg="#F3E8FF"
          fg="#7C3AED"
        />
      </div>

      {/* Filters */}
      <div
        style={{
          display: 'flex',
          gap: 10,
          marginBottom: 20,
          flexWrap: 'wrap',
          alignItems: 'center',
        }}
      >
        <button
          onClick={() => setShowMissing((v) => !v)}
          style={{
            padding: '8px 16px',
            borderRadius: 8,
            border: 'none',
            background: showMissing ? '#D64545' : 'white',
            color: showMissing ? 'white' : '#D64545',
            fontSize: 13,
            fontWeight: 700,
            cursor: 'pointer',
            boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
          }}
        >
          ⚠ Show Missing Only
        </button>
        <input
          type="text"
          placeholder="Search key, English, or Arabic..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            minWidth: 240,
            padding: '10px 14px',
            borderRadius: 10,
            border: '1px solid #E5E7EB',
            fontSize: 13,
            outline: 'none',
            background: 'white',
          }}
        />
      </div>

      {/* Table */}
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
          No strings found.
        </div>
      ) : (
        <div
          style={{
            background: 'white',
            borderRadius: 14,
            overflow: 'hidden',
            boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
          }}
        >
          {!isMobile && (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '2fr 3fr 3fr 100px',
                gap: 12,
                padding: '14px 20px',
                background: '#F6F3EE',
                fontSize: 11,
                fontWeight: 800,
                color: '#6B7280',
                letterSpacing: 0.5,
              }}
            >
              <div>KEY</div>
              <div>🇬🇧 ENGLISH</div>
              <div>🇸🇦 ARABIC</div>
              <div>ACTIONS</div>
            </div>
          )}

          {filtered.map((row, i) => (
            <div
              key={row.key}
              style={{
                display: isMobile ? 'block' : 'grid',
                gridTemplateColumns: '2fr 3fr 3fr 100px',
                gap: 12,
                padding: isMobile ? 14 : '12px 20px',
                borderBottom:
                  i < filtered.length - 1 ? '1px solid #F1EEEA' : 'none',
                fontSize: 13,
                alignItems: 'center',
              }}
            >
              <div>
                <div
                  style={{
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: 800,
                    color: '#0B2B5B',
                    wordBreak: 'break-word',
                  }}
                >
                  {row.key}
                </div>
                {row.missing.length > 0 && (
                  <span
                    style={{
                      display: 'inline-block',
                      marginTop: 4,
                      padding: '2px 8px',
                      borderRadius: 4,
                      background: '#FEE2E2',
                      color: '#D64545',
                      fontSize: 10,
                      fontWeight: 800,
                    }}
                  >
                    MISSING: {row.missing.join(', ').toUpperCase()}
                  </span>
                )}
              </div>

              <div
                style={{
                  fontSize: 13,
                  color: row.en ? '#374151' : '#9CA3AF',
                  fontStyle: row.en ? 'normal' : 'italic',
                  marginTop: isMobile ? 8 : 0,
                  wordBreak: 'break-word',
                }}
              >
                {row.en || '— not translated —'}
              </div>

              <div
                dir="rtl"
                style={{
                  fontSize: 13,
                  color: row.ar ? '#374151' : '#9CA3AF',
                  fontStyle: row.ar ? 'normal' : 'italic',
                  marginTop: isMobile ? 4 : 0,
                  wordBreak: 'break-word',
                  textAlign: isMobile ? 'right' : 'left',
                }}
              >
                {row.ar || '— غير مترجم —'}
              </div>

              <div
                style={{
                  display: 'flex',
                  gap: 6,
                  marginTop: isMobile ? 10 : 0,
                }}
              >
                <button
                  onClick={() => openEdit(row)}
                  style={{
                    padding: '6px 12px',
                    borderRadius: 6,
                    border: 'none',
                    background: '#1E4B8F15',
                    color: '#1E4B8F',
                    fontSize: 11,
                    fontWeight: 800,
                    cursor: 'pointer',
                  }}
                >
                  Edit
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {editing && (
        <EditModal
          editing={editing}
          setEditing={setEditing}
          saving={saving}
          onSave={handleSave}
        />
      )}
    </div>
  );
}

function StatCard({ label, value, bg, fg }) {
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
          color: fg,
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

function EditModal({ editing, setEditing, saving, onSave }) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: 20,
      }}
      onClick={() => !saving && setEditing(null)}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: 'white',
          borderRadius: 16,
          padding: 28,
          maxWidth: 600,
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
        }}
      >
        <h2
          style={{
            fontSize: 18,
            fontWeight: 900,
            color: '#0B2B5B',
            marginBottom: 8,
          }}
        >
          Edit Translation
        </h2>
        <div
          style={{
            fontFamily: 'monospace',
            fontSize: 12,
            color: '#6B7280',
            marginBottom: 20,
            wordBreak: 'break-all',
          }}
        >
          {editing.key}
        </div>

        <div style={{ marginBottom: 16 }}>
          <label style={labelStyle}>🇬🇧 English</label>
          <textarea
            value={editing.enValue}
            onChange={(e) =>
              setEditing({ ...editing, enValue: e.target.value })
            }
            style={{ ...inputStyle, minHeight: 70, resize: 'vertical' }}
            dir="ltr"
          />
        </div>

        <div style={{ marginBottom: 16 }}>
          <label style={labelStyle}>🇸🇦 العربية (Arabic)</label>
          <textarea
            value={editing.arValue}
            onChange={(e) =>
              setEditing({ ...editing, arValue: e.target.value })
            }
            style={{ ...inputStyle, minHeight: 70, resize: 'vertical' }}
            dir="rtl"
          />
        </div>

        <div
          style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}
        >
          <button
            onClick={() => setEditing(null)}
            disabled={saving}
            style={{
              padding: '10px 20px',
              borderRadius: 8,
              border: '1px solid #E5E7EB',
              background: 'white',
              fontSize: 14,
              fontWeight: 700,
              cursor: 'pointer',
              color: '#6B7280',
            }}
          >
            Cancel
          </button>
          <button
            onClick={onSave}
            disabled={saving}
            style={{
              padding: '10px 24px',
              borderRadius: 8,
              border: 'none',
              background:
                'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
              color: '#0B2B5B',
              fontSize: 14,
              fontWeight: 800,
              cursor: saving ? 'not-allowed' : 'pointer',
              opacity: saving ? 0.6 : 1,
            }}
          >
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}

const labelStyle = {
  display: 'block',
  fontSize: 12,
  fontWeight: 800,
  color: '#374151',
  marginBottom: 6,
  letterSpacing: 0.3,
};

const inputStyle = {
  width: '100%',
  padding: '10px 14px',
  borderRadius: 10,
  border: '1px solid #E5E7EB',
  fontSize: 14,
  outline: 'none',
  fontFamily: 'inherit',
  background: 'white',
  boxSizing: 'border-box',
};