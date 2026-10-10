import { useEffect, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const TABS = [
  { key: 'plans', label: 'Subscription Plans' },
  { key: 'per_offer', label: 'Per-Offer Fees' },
  { key: 'commission', label: 'Success Commission' },
];

const OFFER_TYPES = [
  { key: 'standard', label: 'Standard Offer' },
  { key: 'flash', label: 'Flash Deal' },
  { key: 'group', label: 'Group Deal' },
  { key: 'hidden_gem', label: 'Hidden Gem' },
  { key: 'birthday', label: 'Birthday Special' },
];

export default function PricingPage() {
  const [tab, setTab] = useState('plans');
  const isMobile = useIsMobile();

  return (
    <div style={{ padding: isMobile ? 16 : 32, maxWidth: 1100 }}>
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
          Pricing
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Manage subscription plans, per-offer fees, and commission rates.
        </p>
      </header>

      {/* Tabs */}
      <div
        style={{
          display: 'flex',
          gap: 6,
          marginBottom: 20,
          borderBottom: '1px solid #E5E7EB',
        }}
      >
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            style={{
              padding: '10px 18px',
              border: 'none',
              background: 'transparent',
              color: tab === t.key ? '#0B2B5B' : '#6B7280',
              fontSize: 14,
              fontWeight: 800,
              cursor: 'pointer',
              borderBottom:
                tab === t.key
                  ? '3px solid #D4A13A'
                  : '3px solid transparent',
              marginBottom: -1,
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'plans' && <PlansTab isMobile={isMobile} />}
      {tab === 'per_offer' && <PerOfferTab isMobile={isMobile} />}
      {tab === 'commission' && <CommissionTab isMobile={isMobile} />}
    </div>
  );
}

// ---------- Tab 1: Subscription Plans ----------
function PlansTab({ isMobile }) {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'plans'), orderBy('order', 'asc'));
    const unsub = onSnapshot(q, (snap) => {
      setPlans(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  function openEdit(plan) {
    setEditing({
      id: plan.id,
      name: plan.name || '',
      priceMonthly: plan.priceMonthly ?? 0,
      currency: plan.currency || 'QAR',
      offersPerMonth: plan.offersPerMonth ?? 1,
      featuresText: (plan.features || []).join('\n'),
      active: plan.active ?? true,
    });
    setError('');
  }

  async function handleSave() {
    if (!editing.name.trim()) {
      setError('Name is required');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const features = editing.featuresText
        .split('\n')
        .map((f) => f.trim())
        .filter(Boolean);

      await updateDoc(doc(db, 'plans', editing.id), {
        name: editing.name.trim(),
        priceMonthly: Number(editing.priceMonthly) || 0,
        currency: editing.currency,
        offersPerMonth: Number(editing.offersPerMonth) ?? 1,
        features,
        active: editing.active,
        updatedAt: serverTimestamp(),
      });
      setEditing(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  }

  async function handleToggle(plan) {
    try {
      await updateDoc(doc(db, 'plans', plan.id), {
        active: !plan.active,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <div>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile
            ? '1fr'
            : 'repeat(auto-fit, minmax(240px, 1fr))',
          gap: 16,
        }}
      >
        {plans.map((p) => (
          <div
            key={p.id}
            style={{
              background: 'white',
              borderRadius: 16,
              padding: 20,
              boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
              borderTop: `4px solid ${p.active ? '#D4A13A' : '#E5E7EB'}`,
              opacity: p.active ? 1 : 0.6,
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-start',
                marginBottom: 12,
              }}
            >
              <div
                style={{
                  fontSize: 18,
                  fontWeight: 900,
                  color: '#0B2B5B',
                }}
              >
                {p.name}
              </div>
              <Tag
                bg={p.active ? '#E5F5EA' : '#F1EEEA'}
                fg={p.active ? '#2E9E5B' : '#6B7280'}
              >
                {p.active ? 'ACTIVE' : 'HIDDEN'}
              </Tag>
            </div>

            <div
              style={{
                fontSize: 28,
                fontWeight: 900,
                color: '#0B2B5B',
                marginBottom: 4,
              }}
            >
              {p.priceMonthly} {p.currency}
              <span
                style={{ fontSize: 13, fontWeight: 600, color: '#6B7280' }}
              >
                {' '}
                /month
              </span>
            </div>

            <div
              style={{
                fontSize: 12,
                color: '#6B7280',
                marginBottom: 12,
              }}
            >
              {p.offersPerMonth === -1
                ? '♾️ Unlimited offers'
                : `${p.offersPerMonth} offer${p.offersPerMonth !== 1 ? 's' : ''} /month`}
            </div>

            {(p.features || []).length > 0 && (
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 4,
                  marginBottom: 16,
                }}
              >
                {p.features.map((f, i) => (
                  <div
                    key={i}
                    style={{
                      fontSize: 12,
                      color: '#374151',
                      display: 'flex',
                      gap: 6,
                    }}
                  >
                    <span style={{ color: '#2E9E5B' }}>✓</span>
                    <span>{f}</span>
                  </div>
                ))}
              </div>
            )}

            <div style={{ display: 'flex', gap: 6 }}>
              <button onClick={() => openEdit(p)} style={btnPrimary}>
                Edit
              </button>
              <button
                onClick={() => handleToggle(p)}
                style={btnSecondary(p.active ? '#A67920' : '#2E9E5B')}
              >
                {p.active ? 'Hide' : 'Show'}
              </button>
            </div>
          </div>
        ))}
      </div>

      {editing && (
        <Modal title={`Edit ${editing.name}`} onClose={() => !saving && setEditing(null)}>
          <Field label="Name *">
            <input
              style={inputStyle}
              value={editing.name}
              onChange={(e) =>
                setEditing({ ...editing, name: e.target.value })
              }
            />
          </Field>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '2fr 1fr',
              gap: 12,
            }}
          >
            <Field label="Price / Month">
              <input
                type="number"
                style={inputStyle}
                value={editing.priceMonthly}
                onChange={(e) =>
                  setEditing({
                    ...editing,
                    priceMonthly: e.target.value,
                  })
                }
              />
            </Field>
            <Field label="Currency">
              <select
                style={inputStyle}
                value={editing.currency}
                onChange={(e) =>
                  setEditing({ ...editing, currency: e.target.value })
                }
              >
                <option value="QAR">QAR</option>
                <option value="INR">INR</option>
              </select>
            </Field>
          </div>

          <Field label="Offers per Month (-1 = unlimited)">
            <input
              type="number"
              style={inputStyle}
              value={editing.offersPerMonth}
              onChange={(e) =>
                setEditing({
                  ...editing,
                  offersPerMonth: e.target.value,
                })
              }
            />
          </Field>

          <Field label="Features (one per line)">
            <textarea
              style={{ ...inputStyle, minHeight: 100, resize: 'vertical' }}
              value={editing.featuresText}
              onChange={(e) =>
                setEditing({
                  ...editing,
                  featuresText: e.target.value,
                })
              }
              placeholder="Basic listing&#10;Analytics&#10;Priority"
            />
          </Field>

          <label
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              marginBottom: 16,
              fontSize: 13,
            }}
          >
            <input
              type="checkbox"
              checked={editing.active}
              onChange={(e) =>
                setEditing({ ...editing, active: e.target.checked })
              }
              style={{ width: 18, height: 18 }}
            />
            Active (visible in app)
          </label>

          {error && <ErrorBox text={error} />}

          <ModalButtons
            onCancel={() => setEditing(null)}
            onSave={handleSave}
            saving={saving}
          />
        </Modal>
      )}
    </div>
  );
}

// ---------- Tab 2: Per-Offer Fees ----------
function PerOfferTab({ isMobile }) {
  const [fees, setFees] = useState({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(
      doc(db, 'config', 'per_offer_fees'),
      (snap) => {
        setFees(snap.exists() ? snap.data().fees || {} : {});
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  async function handleSave() {
    setSaving(true);
    try {
      const cleaned = {};
      Object.entries(fees).forEach(([k, v]) => {
        cleaned[k] = Number(v) || 0;
      });
      await setDoc(
        doc(db, 'config', 'per_offer_fees'),
        { fees: cleaned, updatedAt: serverTimestamp() },
        { merge: true },
      );
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: 24,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
        maxWidth: 600,
      }}
    >
      <h2
        style={{
          fontSize: 16,
          fontWeight: 900,
          color: '#0B2B5B',
          marginBottom: 4,
        }}
      >
        Per-Offer Fee
      </h2>
      <p
        style={{
          fontSize: 13,
          color: '#6B7280',
          marginBottom: 20,
        }}
      >
        Charge per offer posted (in QAR). Business pays this each time they
        create an offer of that type.
      </p>

      {OFFER_TYPES.map((t) => (
        <div
          key={t.key}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '12px 0',
            borderBottom: '1px solid #F1EEEA',
            gap: 12,
          }}
        >
          <div style={{ flex: 1 }}>
            <div
              style={{
                fontSize: 14,
                fontWeight: 800,
                color: '#0B2B5B',
              }}
            >
              {t.label}
            </div>
            <div style={{ fontSize: 11, color: '#9CA3AF' }}>
              {t.key}
            </div>
          </div>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            <input
              type="number"
              step="0.5"
              style={{ ...inputStyle, width: 100, textAlign: 'right' }}
              value={fees[t.key] ?? 0}
              onChange={(e) =>
                setFees({ ...fees, [t.key]: e.target.value })
              }
            />
            <span
              style={{
                fontSize: 13,
                fontWeight: 800,
                color: '#6B7280',
                minWidth: 40,
              }}
            >
              QAR
            </span>
          </div>
        </div>
      ))}

      <div style={{ marginTop: 20, display: 'flex', gap: 10, alignItems: 'center' }}>
        <button onClick={handleSave} disabled={saving} style={btnPrimary}>
          {saving ? 'Saving…' : 'Save Changes'}
        </button>
        {saved && (
          <span
            style={{
              fontSize: 13,
              color: '#2E9E5B',
              fontWeight: 800,
            }}
          >
            ✓ Saved
          </span>
        )}
      </div>
    </div>
  );
}

// ---------- Tab 3: Commission Tiers ----------
function CommissionTab({ isMobile }) {
  const [tiers, setTiers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(
      doc(db, 'config', 'commission_tiers'),
      (snap) => {
        const data = snap.exists() ? snap.data().tiers || [] : [];
        setTiers(data);
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  function updateTier(i, field, value) {
    setTiers((prev) =>
      prev.map((t, idx) =>
        idx === i ? { ...t, [field]: Number(value) || 0 } : t,
      ),
    );
  }

  async function handleSave() {
    setSaving(true);
    try {
      await setDoc(
        doc(db, 'config', 'commission_tiers'),
        { tiers, updatedAt: serverTimestamp() },
        { merge: true },
      );
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: 24,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
        maxWidth: 700,
      }}
    >
      <h2
        style={{
          fontSize: 16,
          fontWeight: 900,
          color: '#0B2B5B',
          marginBottom: 4,
        }}
      >
        Success Commission
      </h2>
      <p
        style={{
          fontSize: 13,
          color: '#6B7280',
          marginBottom: 20,
        }}
      >
        Rate per claim charged to business, based on monthly claim volume.
      </p>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile ? '1fr' : '1fr 1fr 1fr',
          gap: 10,
          padding: '10px 0',
          borderBottom: '1px solid #E5E7EB',
          fontSize: 11,
          fontWeight: 800,
          color: '#6B7280',
          letterSpacing: 0.5,
        }}
      >
        <div>MIN CLAIMS</div>
        <div>MAX CLAIMS (-1 = ∞)</div>
        <div>RATE / CLAIM (QAR)</div>
      </div>

      {tiers.map((t, i) => (
        <div
          key={i}
          style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? '1fr' : '1fr 1fr 1fr',
            gap: 10,
            padding: '12px 0',
            borderBottom: '1px solid #F1EEEA',
          }}
        >
          <input
            type="number"
            style={inputStyle}
            value={t.minClaims}
            onChange={(e) => updateTier(i, 'minClaims', e.target.value)}
          />
          <input
            type="number"
            style={inputStyle}
            value={t.maxClaims}
            onChange={(e) => updateTier(i, 'maxClaims', e.target.value)}
          />
          <input
            type="number"
            step="0.05"
            style={inputStyle}
            value={t.ratePerClaim}
            onChange={(e) => updateTier(i, 'ratePerClaim', e.target.value)}
          />
        </div>
      ))}

      <div style={{ marginTop: 20, display: 'flex', gap: 10, alignItems: 'center' }}>
        <button onClick={handleSave} disabled={saving} style={btnPrimary}>
          {saving ? 'Saving…' : 'Save Changes'}
        </button>
        {saved && (
          <span
            style={{
              fontSize: 13,
              color: '#2E9E5B',
              fontWeight: 800,
            }}
          >
            ✓ Saved
          </span>
        )}
      </div>
    </div>
  );
}

// ---------- Shared ----------
function Field({ label, children }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <label
        style={{
          display: 'block',
          fontSize: 12,
          fontWeight: 800,
          color: '#374151',
          marginBottom: 6,
          letterSpacing: 0.3,
        }}
      >
        {label}
      </label>
      {children}
    </div>
  );
}

function Modal({ title, children, onClose }) {
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
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: 'white',
          borderRadius: 16,
          padding: 28,
          maxWidth: 520,
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
        }}
      >
        <h2
          style={{
            fontSize: 20,
            fontWeight: 900,
            color: '#0B2B5B',
            marginBottom: 20,
          }}
        >
          {title}
        </h2>
        {children}
      </div>
    </div>
  );
}

function ModalButtons({ onCancel, onSave, saving, saveText = 'Save' }) {
  return (
    <div
      style={{
        display: 'flex',
        gap: 10,
        justifyContent: 'flex-end',
        marginTop: 8,
      }}
    >
      <button
        onClick={onCancel}
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
      <button onClick={onSave} disabled={saving} style={btnPrimary}>
        {saving ? 'Saving…' : saveText}
      </button>
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

function ErrorBox({ text }) {
  return (
    <div
      style={{
        background: '#FEE2E2',
        color: '#D64545',
        padding: 10,
        borderRadius: 8,
        fontSize: 13,
        marginBottom: 12,
      }}
    >
      {text}
    </div>
  );
}

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

const btnPrimary = {
  padding: '10px 20px',
  borderRadius: 8,
  border: 'none',
  background: 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
  color: '#0B2B5B',
  fontSize: 13,
  fontWeight: 800,
  cursor: 'pointer',
  boxShadow: '0 2px 8px rgba(212,161,58,0.25)',
};

function btnSecondary(color) {
  return {
    padding: '10px 20px',
    borderRadius: 8,
    border: 'none',
    background: color + '15',
    color,
    fontSize: 13,
    fontWeight: 800,
    cursor: 'pointer',
  };
}