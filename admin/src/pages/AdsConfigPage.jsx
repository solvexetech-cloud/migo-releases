// ═══════════════════════════════════════════════════════
// MIGO Admin — Ads Config Page (D4)
// ═══════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';

export default function AdsConfigPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [config, setConfig] = useState({
    enabled: true,
    bannerHome: true,
    nativeList: true,
    interstitialClaim: true,
  });

  useEffect(() => {
    loadConfig();
  }, []);

  async function loadConfig() {
    try {
      const snap = await getDoc(doc(db, 'config', 'ads'));
      if (snap.exists()) {
        setConfig((prev) => ({ ...prev, ...snap.data() }));
      }
    } catch (e) {
      console.error('Load error:', e);
    } finally {
      setLoading(false);
    }
  }

  async function saveConfig() {
    setSaving(true);
    try {
      await setDoc(
        doc(db, 'config', 'ads'),
        { ...config, updatedAt: serverTimestamp() },
        { merge: true }
      );
      alert('✅ Saved successfully!');
    } catch (e) {
      alert('❌ Error: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  function toggle(key) {
    setConfig({ ...config, [key]: !config[key] });
  }

  if (loading) {
    return (
      <div style={{ padding: 40, textAlign: 'center' }}>
        Loading...
      </div>
    );
  }

  return (
    <div style={{ padding: 24, maxWidth: 800 }}>
      <h1 style={{ fontSize: 24, fontWeight: 'bold', marginBottom: 8 }}>
        📢 Ads Configuration
      </h1>
      <p style={{ color: '#6B7280', marginBottom: 24 }}>
        Toggle ads on/off without app update.
      </p>

      {/* Master Switch */}
      <div style={cardStyle}>
        <ToggleRow
          title="🎯 Master Switch"
          subtitle="Turn off to disable ALL ads instantly"
          value={config.enabled}
          onChange={() => toggle('enabled')}
          highlight
        />
      </div>

      {/* Individual Placements */}
      <div style={cardStyle}>
        <h2 style={{ fontSize: 16, fontWeight: 'bold', marginBottom: 16 }}>
          📍 Placements
        </h2>

        <ToggleRow
          title="🏠 Home Banner"
          subtitle="Top of home screen"
          value={config.bannerHome}
          onChange={() => toggle('bannerHome')}
          disabled={!config.enabled}
        />

        <ToggleRow
          title="🎴 List Native Ads"
          subtitle="Every 5th offer card"
          value={config.nativeList}
          onChange={() => toggle('nativeList')}
          disabled={!config.enabled}
        />

        <ToggleRow
          title="🎬 Claim Interstitial"
          subtitle="Every 3rd claim (60s gap)"
          value={config.interstitialClaim}
          onChange={() => toggle('interstitialClaim')}
          disabled={!config.enabled}
        />
      </div>

      {/* Save Button */}
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
        {saving ? 'Saving...' : '💾 Save'}
      </button>

      {/* Info */}
      <div style={{ ...cardStyle, marginTop: 24, background: '#FEF3C7' }}>
        <p style={{ fontSize: 13, color: '#92400E', margin: 0 }}>
          ℹ️ <strong>Note:</strong> Business owners, admins, agencies,
          and moderators never see ads. Only customers.
        </p>
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
        padding: '14px 0',
        borderBottom: '1px solid #F3F4F6',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      <div>
        <div
          style={{
            fontWeight: highlight ? 'bold' : '600',
            fontSize: 15,
          }}
        >
          {title}
        </div>
        {subtitle && (
          <div
            style={{
              fontSize: 13,
              color: '#6B7280',
              marginTop: 2,
            }}
          >
            {subtitle}
          </div>
        )}
      </div>
      <button
        onClick={onChange}
        disabled={disabled}
        style={{
          width: 52,
          height: 28,
          borderRadius: 14,
          border: 'none',
          background: value ? '#10B981' : '#D1D5DB',
          position: 'relative',
          cursor: disabled ? 'not-allowed' : 'pointer',
          transition: 'background 0.2s',
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
  boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
};