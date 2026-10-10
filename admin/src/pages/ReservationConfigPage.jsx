// ═══════════════════════════════════════════════════════
// MIGO Admin — Reservation Config Page (PHASE H)
// ═══════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';

const DEFAULT_CONFIG = {
  enabled: true,
  defaultHoldHours: 4,
  maxHoldHours: 24,
  minHoldHours: 1,
  tokenRequired: false,
  tokenAmount: 0,
  tokenMinAmount: 5,
  tokenMaxAmount: 50,
  noShowLimit7Day: 3,
  noShowLimit30Day: 5,
  banDurationDays: 7,
  locationLockEnabled: true,
  locationLockRadiusKm: 5,
};

export default function ReservationConfigPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [config, setConfig] = useState(DEFAULT_CONFIG);

  useEffect(() => {
    loadConfig();
  }, []);

  async function loadConfig() {
    try {
      const snap = await getDoc(
        doc(db, 'reservation_config', 'global')
      );
      if (snap.exists()) {
        setConfig({ ...DEFAULT_CONFIG, ...snap.data() });
      }
    } catch (e) {
      console.error('Load error:', e);
    } finally {
      setLoading(false);
    }
  }

  async function saveConfig() {
    // Validation
    if (config.minHoldHours > config.defaultHoldHours) {
      alert('❌ Default hold hours must be ≥ minimum');
      return;
    }
    if (config.defaultHoldHours > config.maxHoldHours) {
      alert('❌ Default hold hours must be ≤ maximum');
      return;
    }

    setSaving(true);
    try {
      await setDoc(
        doc(db, 'reservation_config', 'global'),
        { ...config, updatedAt: serverTimestamp() },
        { merge: true }
      );
      alert('✅ Configuration saved!');
    } catch (e) {
      alert('❌ Error: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  function update(field, value) {
    setConfig({ ...config, [field]: value });
  }

  if (loading) {
    return <div style={{ padding: 40 }}>Loading...</div>;
  }

  return (
    <div style={{ padding: 24, maxWidth: 900 }}>
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 26, fontWeight: 'bold', marginBottom: 4 }}>
          ⚙️ Reservation Config
        </h1>
        <p style={{ color: '#6B7280', fontSize: 14 }}>
          Global settings for MIGO Reserve feature.
        </p>
      </div>

      {/* Master Switch */}
      <Card>
        <ToggleRow
          title="🎯 Reserve Feature Enabled"
          subtitle="Turn off to disable all reservations"
          value={config.enabled}
          onChange={(v) => update('enabled', v)}
          highlight
        />
      </Card>

      {/* Hold Hours */}
      <Card>
        <SectionTitle>⏰ Hold Duration</SectionTitle>
        <NumberField
          label="Default Hold Hours"
          value={config.defaultHoldHours}
          onChange={(v) => update('defaultHoldHours', v)}
          suffix="hours"
          disabled={!config.enabled}
        />
        <NumberField
          label="Minimum Hold Hours"
          value={config.minHoldHours}
          onChange={(v) => update('minHoldHours', v)}
          suffix="hours"
          disabled={!config.enabled}
        />
        <NumberField
          label="Maximum Hold Hours"
          value={config.maxHoldHours}
          onChange={(v) => update('maxHoldHours', v)}
          suffix="hours"
          disabled={!config.enabled}
        />
      </Card>

      {/* Location Lock */}
      <Card>
        <SectionTitle>📍 Location Lock</SectionTitle>
        <ToggleRow
          title="Enable Location Lock"
          subtitle="Only allow bookings from customer's current area"
          value={config.locationLockEnabled}
          onChange={(v) => update('locationLockEnabled', v)}
          disabled={!config.enabled}
        />
        <NumberField
          label="Location Radius"
          value={config.locationLockRadiusKm}
          onChange={(v) => update('locationLockRadiusKm', v)}
          suffix="km"
          disabled={!config.enabled || !config.locationLockEnabled}
        />
      </Card>

      {/* No-Show Protection */}
      <Card>
        <SectionTitle>🚫 No-Show Protection</SectionTitle>
        <NumberField
          label="No-Shows Limit (7 days)"
          value={config.noShowLimit7Day}
          onChange={(v) => update('noShowLimit7Day', v)}
          suffix="times"
          disabled={!config.enabled}
        />
        <NumberField
          label="No-Shows Limit (30 days)"
          value={config.noShowLimit30Day}
          onChange={(v) => update('noShowLimit30Day', v)}
          suffix="times"
          disabled={!config.enabled}
        />
        <NumberField
          label="Ban Duration"
          value={config.banDurationDays}
          onChange={(v) => update('banDurationDays', v)}
          suffix="days"
          disabled={!config.enabled}
        />
      </Card>

      {/* Token */}
      <Card>
        <SectionTitle>💰 Token (Optional Deposit)</SectionTitle>
        <ToggleRow
          title="Token Required (Global)"
          subtitle="Businesses can override per-offer"
          value={config.tokenRequired}
          onChange={(v) => update('tokenRequired', v)}
          disabled={!config.enabled}
        />
        <NumberField
          label="Default Token Amount"
          value={config.tokenAmount}
          onChange={(v) => update('tokenAmount', v)}
          suffix="QAR"
          disabled={!config.enabled || !config.tokenRequired}
        />
        <NumberField
          label="Minimum Token"
          value={config.tokenMinAmount}
          onChange={(v) => update('tokenMinAmount', v)}
          suffix="QAR"
          disabled={!config.enabled || !config.tokenRequired}
        />
        <NumberField
          label="Maximum Token"
          value={config.tokenMaxAmount}
          onChange={(v) => update('tokenMaxAmount', v)}
          suffix="QAR"
          disabled={!config.enabled || !config.tokenRequired}
        />
      </Card>

      {/* Save */}
      <button
        onClick={saveConfig}
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
        }}
      >
        {saving ? 'Saving...' : '💾 Save Configuration'}
      </button>

      {/* Info */}
      <div
        style={{
          ...cardStyle,
          marginTop: 24,
          background: '#FEF3C7',
        }}
      >
        <p style={{ fontSize: 13, color: '#92400E', margin: 0 }}>
          ℹ️ <strong>Note:</strong> These settings apply globally.
          Individual businesses can override hold hours and token
          requirements per offer.
        </p>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────

function Card({ children }) {
  return (
    <div style={cardStyle}>
      {children}
    </div>
  );
}

function SectionTitle({ children }) {
  return (
    <h2
      style={{
        fontSize: 16,
        fontWeight: 'bold',
        marginBottom: 16,
      }}
    >
      {children}
    </h2>
  );
}

function NumberField({ label, value, onChange, suffix, disabled }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '12px 0',
        borderBottom: '1px solid #F3F4F6',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      <span style={{ fontSize: 15, fontWeight: 500 }}>{label}</span>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(Number(e.target.value) || 0)}
          disabled={disabled}
          style={{
            width: 100,
            padding: '8px 12px',
            borderRadius: 8,
            border: '1px solid #D1D5DB',
            fontSize: 14,
            fontWeight: 'bold',
            textAlign: 'right',
            background: disabled ? '#F9FAFB' : 'white',
          }}
        />
        <span style={{ fontSize: 13, color: '#6B7280', minWidth: 50 }}>
          {suffix}
        </span>
      </div>
    </div>
  );
}

function ToggleRow({ title, subtitle, value, onChange, disabled, highlight }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '12px 0',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      <div style={{ flex: 1 }}>
        <div
          style={{
            fontWeight: highlight ? 'bold' : 600,
            fontSize: 15,
          }}
        >
          {title}
        </div>
        {subtitle && (
          <div style={{ fontSize: 12, color: '#6B7280', marginTop: 2 }}>
            {subtitle}
          </div>
        )}
      </div>
      <button
        onClick={() => onChange(!value)}
        disabled={disabled}
        style={{
          width: 52,
          height: 28,
          borderRadius: 14,
          border: 'none',
          background: value ? '#10B981' : '#D1D5DB',
          position: 'relative',
          cursor: disabled ? 'not-allowed' : 'pointer',
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
            left: value ? 27 : 3,
            transition: 'left 0.2s',
            boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
          }}
        />
      </button>
    </div>
  );
}

const cardStyle = {
  background: 'white',
  borderRadius: 12,
  padding: 20,
  marginBottom: 16,
  boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
};