// ═══════════════════════════════════════════════════════
// MIGO Admin — Reservation Rules Page (PHASE H)
// ═══════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import {
  doc, getDoc, getDocs, setDoc, updateDoc, collection,
  query, orderBy, serverTimestamp, where,
} from 'firebase/firestore';
import { db } from '../firebase';

export default function ReservationRulesPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [versions, setVersions] = useState([]);
  const [selectedVersion, setSelectedVersion] = useState(null);
  const [form, setForm] = useState({
    version: '',
    title: '',
    textEn: '',
    textAr: '',
    textMl: '',
    active: false,
  });

  useEffect(() => {
    loadVersions();
  }, []);

  async function loadVersions() {
    try {
      const q = query(
        collection(db, 'reservation_rules'),
        orderBy('createdAt', 'desc')
      );
      const snap = await getDocs(q);
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setVersions(list);

      // Auto-select active version
      const active = list.find((v) => v.active === true);
      if (active) {
        selectVersion(active);
      } else if (list.length > 0) {
        selectVersion(list[0]);
      }
    } catch (e) {
      console.error('Load error:', e);
    } finally {
      setLoading(false);
    }
  }

  function selectVersion(v) {
    setSelectedVersion(v);
    setForm({
      version: v.version || '',
      title: v.title || '',
      textEn: v.textEn || '',
      textAr: v.textAr || '',
      textMl: v.textMl || '',
      active: v.active || false,
    });
  }

  async function saveRules() {
    if (!form.version || !form.title || !form.textEn) {
      alert('❌ Version, title, and English text are required');
      return;
    }

    setSaving(true);
    try {
      // If activating this version, deactivate others first
      if (form.active) {
        const activeQ = query(
          collection(db, 'reservation_rules'),
          where('active', '==', true)
        );
        const activeSnap = await getDocs(activeQ);
        for (const d of activeSnap.docs) {
          if (d.id !== form.version) {
            await updateDoc(doc(db, 'reservation_rules', d.id), {
              active: false,
              updatedAt: serverTimestamp(),
            });
          }
        }
      }

      await setDoc(
        doc(db, 'reservation_rules', form.version),
        {
          ...form,
          updatedAt: serverTimestamp(),
          createdAt: selectedVersion?.createdAt || serverTimestamp(),
          createdBy: 'admin',
        },
        { merge: true }
      );

      alert('✅ Rules saved!');
      await loadVersions();
    } catch (e) {
      alert('❌ Error: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  function startNewVersion() {
    setSelectedVersion(null);
    setForm({
      version: '',
      title: 'MIGO Reserve Rules',
      textEn: '',
      textAr: '',
      textMl: '',
      active: false,
    });
  }

  function update(field, value) {
    setForm({ ...form, [field]: value });
  }

  if (loading) {
    return <div style={{ padding: 40 }}>Loading...</div>;
  }

  return (
    <div style={{ padding: 24, maxWidth: 1400 }}>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 26, fontWeight: 'bold', marginBottom: 4 }}>
          📜 Reservation Rules
        </h1>
        <p style={{ color: '#6B7280', fontSize: 14 }}>
          Manage reserve rules. Only one version can be active at a time.
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '280px 1fr', gap: 20 }}>
        {/* Left: Version list */}
        <div style={cardStyle}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 16,
            }}
          >
            <h2 style={{ fontSize: 15, fontWeight: 'bold' }}>Versions</h2>
            <button
              onClick={startNewVersion}
              style={{
                padding: '6px 12px',
                background: '#7C3AED',
                color: 'white',
                border: 'none',
                borderRadius: 6,
                fontSize: 12,
                fontWeight: 'bold',
                cursor: 'pointer',
              }}
            >
              + New
            </button>
          </div>

          {versions.length === 0 ? (
            <p style={{ fontSize: 13, color: '#9CA3AF' }}>
              No versions yet.
            </p>
          ) : (
            versions.map((v) => (
              <div
                key={v.id}
                onClick={() => selectVersion(v)}
                style={{
                  padding: 12,
                  borderRadius: 8,
                  marginBottom: 6,
                  cursor: 'pointer',
                  background:
                    selectedVersion?.id === v.id ? '#EDE9FE' : '#F9FAFB',
                  border:
                    selectedVersion?.id === v.id
                      ? '2px solid #7C3AED'
                      : '1px solid transparent',
                }}
              >
                <div
                  style={{
                    fontSize: 14,
                    fontWeight: 'bold',
                    marginBottom: 2,
                  }}
                >
                  {v.version}
                </div>
                <div style={{ fontSize: 12, color: '#6B7280' }}>
                  {v.title}
                </div>
                {v.active && (
                  <div
                    style={{
                      marginTop: 4,
                      fontSize: 10,
                      fontWeight: 'bold',
                      color: '#10B981',
                    }}
                  >
                    ✅ ACTIVE
                  </div>
                )}
              </div>
            ))
          )}
        </div>

        {/* Right: Editor */}
        <div style={cardStyle}>
          <h2 style={{ fontSize: 15, fontWeight: 'bold', marginBottom: 16 }}>
            {selectedVersion ? 'Edit Version' : 'New Version'}
          </h2>

          <Field
            label="Version (e.g., v1.0)"
            value={form.version}
            onChange={(v) => update('version', v)}
            disabled={!!selectedVersion}
          />

          <Field
            label="Title"
            value={form.title}
            onChange={(v) => update('title', v)}
          />

          {/* Active toggle */}
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '12px 0',
              marginBottom: 16,
            }}
          >
            <div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>
                🎯 Active Version
              </div>
              <div style={{ fontSize: 12, color: '#6B7280' }}>
                Activating this will deactivate others
              </div>
            </div>
            <button
              onClick={() => update('active', !form.active)}
              style={{
                width: 52,
                height: 28,
                borderRadius: 14,
                border: 'none',
                background: form.active ? '#10B981' : '#D1D5DB',
                position: 'relative',
                cursor: 'pointer',
              }}
            >
              <div
                style={{
                  width: 22,
                  height: 22,
                  borderRadius: '50%',
                  background: 'white',
                  position: 'absolute',
                  top: 3,
                  left: form.active ? 27 : 3,
                  transition: 'left 0.2s',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                }}
              />
            </button>
          </div>

          <TextareaField
            label="🇬🇧 English Text"
            value={form.textEn}
            onChange={(v) => update('textEn', v)}
            placeholder="Enter rules in English..."
          />

          <TextareaField
            label="🇸🇦 Arabic Text (العربية)"
            value={form.textAr}
            onChange={(v) => update('textAr', v)}
            placeholder="أدخل القواعد بالعربية..."
            rtl
          />

          <TextareaField
            label="🇮🇳 Malayalam Text (മലയാളം)"
            value={form.textMl}
            onChange={(v) => update('textMl', v)}
            placeholder="മലയാളത്തിൽ നിയമങ്ങൾ..."
          />

          <button
            onClick={saveRules}
            disabled={saving}
            style={{
              padding: '14px 32px',
              background: saving ? '#9CA3AF' : '#7C3AED',
              color: 'white',
              border: 'none',
              borderRadius: 8,
              fontSize: 15,
              fontWeight: 'bold',
              cursor: saving ? 'not-allowed' : 'pointer',
              marginTop: 8,
            }}
          >
            {saving ? 'Saving...' : '💾 Save Rules'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────

function Field({ label, value, onChange, disabled }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <label
        style={{
          display: 'block',
          fontSize: 13,
          fontWeight: 600,
          marginBottom: 6,
        }}
      >
        {label}
      </label>
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        style={{
          width: '100%',
          padding: '10px 12px',
          borderRadius: 8,
          border: '1px solid #D1D5DB',
          fontSize: 14,
          background: disabled ? '#F9FAFB' : 'white',
          boxSizing: 'border-box',
        }}
      />
    </div>
  );
}

function TextareaField({ label, value, onChange, placeholder, rtl }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <label
        style={{
          display: 'block',
          fontSize: 13,
          fontWeight: 600,
          marginBottom: 6,
        }}
      >
        {label}
      </label>
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        rows={8}
        dir={rtl ? 'rtl' : 'ltr'}
        style={{
          width: '100%',
          padding: '10px 12px',
          borderRadius: 8,
          border: '1px solid #D1D5DB',
          fontSize: 13,
          fontFamily: 'inherit',
          resize: 'vertical',
          boxSizing: 'border-box',
          lineHeight: 1.5,
        }}
      />
    </div>
  );
}

const cardStyle = {
  background: 'white',
  borderRadius: 12,
  padding: 20,
  boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
};