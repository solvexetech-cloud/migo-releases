import { useEffect, useState } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function ShareRewardsPage() {
  const [loading, setLoading] = useState(true);
  const [enabled, setEnabled] = useState(true);
  const [coinsPerRedeem, setCoinsPerRedeem] = useState(10);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function load() {
      const snap = await getDoc(doc(db, 'config', 'share_rewards'));
      if (snap.exists()) {
        const data = snap.data();
        setEnabled(data.enabled ?? true);
        setCoinsPerRedeem(data.coinsPerRedeem ?? 10);
      }
      setLoading(false);
    }
    load();
  }, []);

  async function handleSave() {
    setSaving(true);
    await setDoc(doc(db, 'config', 'share_rewards'), {
      enabled,
      coinsPerRedeem: Number(coinsPerRedeem),
      updatedAt: new Date(),
    });
    setSaving(false);
    alert('Saved successfully!');
  }

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;

  return (
    <div style={{ padding: 24, maxWidth: 600 }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 24 }}>Share Rewards</h1>
      <div style={{ backgroundColor: 'white', padding: 24, borderRadius: 8, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        
        <div style={{ marginBottom: 24 }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={enabled}
              onChange={(e) => setEnabled(e.target.checked)}
              style={{ width: 20, height: 20 }}
            />
            <span style={{ fontSize: 16, fontWeight: 600 }}>Enable Share Rewards</span>
          </label>
          <p style={{ fontSize: 13, color: '#6B7280', marginLeft: 32, marginTop: 4 }}>
            When enabled, customers earn coins when their shared offer is redeemed.
          </p>
        </div>

        <div style={{ marginBottom: 24 }}>
          <label style={{ display: 'block', fontSize: 14, fontWeight: 600, marginBottom: 8 }}>
            Coins per Redeem
          </label>
          <input
            type="number"
            value={coinsPerRedeem}
            onChange={(e) => setCoinsPerRedeem(e.target.value)}
            min={1}
            max={100}
            style={{
              width: '100%',
              padding: 10,
              border: '1px solid #d1d5db',
              borderRadius: 6,
              fontSize: 14,
            }}
          />
          <p style={{ fontSize: 13, color: '#6B7280', marginTop: 4 }}>
            Number of coins awarded to the sharer when their shared link is redeemed.
          </p>
        </div>

        <button
          onClick={handleSave}
          disabled={saving}
          style={{
            padding: '10px 24px',
            backgroundColor: saving ? '#9ca3af' : '#0B2B5B',
            color: 'white',
            border: 'none',
            borderRadius: 6,
            fontSize: 14,
            fontWeight: 600,
            cursor: saving ? 'not-allowed' : 'pointer',
          }}
        >
          {saving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>
    </div>
  );
}