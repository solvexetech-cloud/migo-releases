import { useEffect, useState } from 'react';
import { doc, getDoc, setDoc, collection, getDocs } from 'firebase/firestore';
import { db } from '../firebase';

export default function CoinSettingsPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  // സ്റ്റേറ്റുകൾ
  const [rewards, setRewards] = useState({
    claim: 10,
    review: 5,
    referral: 50,
    signup: 20,
  });

  const [caps, setCaps] = useState({
    daily: 50,
    monthly: 500,
  });

  // 🆕 ഡൈനാമിക് കൺട്രി റേറ്റ്സ്
  const [countryRates, setCountryRates] = useState({
    QA: 1,
    IN: 10,
    AE: 1,
  });
  
  const [allCountries, setAllCountries] = useState([]);
  const [selectedCountryToAdd, setSelectedCountryToAdd] = useState('');

  const [expiryDays, setExpiryDays] = useState(60);

  useEffect(() => {
    fetchSettings();
    fetchCountries();
  }, []);

  // 🆕 ഫയർബേസിൽ നിന്ന് രാജ്യങ്ങളുടെ ലിസ്റ്റ് എടുക്കുന്നു
  const fetchCountries = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'countries'));
      const list = querySnapshot.docs.map(doc => ({
        code: doc.id,
        name: doc.data().name || doc.id,
        currency: doc.data().currency || '',
      }));
      setAllCountries(list);
    } catch (error) {
      console.error("Error fetching countries: ", error);
    }
  };

  const fetchSettings = async () => {
    try {
      const docRef = doc(db, 'config', 'coin_settings');
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();
        if (data.rewards) setRewards(data.rewards);
        if (data.caps) setCaps(data.caps);
        if (data.countryRates) setCountryRates(data.countryRates);
        if (data.expiryDays) setExpiryDays(data.expiryDays);
      }
    } catch (error) {
      console.error("Error fetching settings: ", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    setMessage('');
    try {
      await setDoc(doc(db, 'config', 'coin_settings'), {
        rewards,
        caps,
        countryRates,
        expiryDays,
        updatedAt: new Date(),
      });
      setMessage('Settings saved successfully! ✅');
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      console.error(error);
      setMessage('Failed to save settings. ❌');
    } finally {
      setSaving(false);
    }
  };

  // 🆕 രാജ്യം ചേർക്കാൻ
  const handleAddCountry = () => {
    if (selectedCountryToAdd && !countryRates[selectedCountryToAdd]) {
      setCountryRates(prev => ({
        ...prev,
        [selectedCountryToAdd]: 1 // ഡിഫോൾട്ട് മൂല്യം 1
      }));
      setSelectedCountryToAdd('');
    }
  };

  // 🆕 രാജ്യം ഒഴിവാക്കാൻ
  const handleRemoveCountry = (code) => {
    setCountryRates(prev => {
      const copy = { ...prev };
      delete copy[code];
      return copy;
    });
  };

  // 🆕 മൂല്യം മാറ്റാൻ
  const handleRateChange = (code, val) => {
    setCountryRates(prev => ({ ...prev, [code]: Number(val) }));
  };

  if (loading) return <div style={{ padding: 24 }}>Loading settings...</div>;

  return (
    <div style={{ padding: 24, maxWidth: 800, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, color: '#0B2B5B' }}>Coin Settings 🪙</h1>
        <button 
          onClick={handleSave} 
          disabled={saving}
          style={{ 
            padding: '10px 20px', 
            backgroundColor: '#22c55e', 
            color: 'white', 
            border: 'none', 
            borderRadius: 6, 
            cursor: saving ? 'not-allowed' : 'pointer',
            fontWeight: 600,
            opacity: saving ? 0.7 : 1
          }}
        >
          {saving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>

      {message && (
        <div style={{ padding: 12, backgroundColor: message.includes('✅') ? '#dcfce7' : '#fee2e2', color: message.includes('✅') ? '#166534' : '#991b1b', borderRadius: 6, marginBottom: 20, fontWeight: 600 }}>
          {message}
        </div>
      )}

      {/* --- Section 1: Rewards --- */}
      <div style={{ backgroundColor: 'white', padding: 20, borderRadius: 8, marginBottom: 20, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 16, borderBottom: '1px solid #eee', paddingBottom: 8 }}>🎁 Action Rewards (Coins)</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Claim Offer</label>
            <input type="number" value={rewards.claim} onChange={(e) => setRewards({...rewards, claim: Number(e.target.value)})} style={inputStyle} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Write Review</label>
            <input type="number" value={rewards.review} onChange={(e) => setRewards({...rewards, review: Number(e.target.value)})} style={inputStyle} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Referral Bonus</label>
            <input type="number" value={rewards.referral} onChange={(e) => setRewards({...rewards, referral: Number(e.target.value)})} style={inputStyle} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Sign Up Welcome Bonus</label>
            <input type="number" value={rewards.signup} onChange={(e) => setRewards({...rewards, signup: Number(e.target.value)})} style={inputStyle} />
          </div>
        </div>
      </div>

      {/* --- Section 2: Limits & Caps --- */}
      <div style={{ backgroundColor: 'white', padding: 20, borderRadius: 8, marginBottom: 20, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 16, borderBottom: '1px solid #eee', paddingBottom: 8 }}>⚖️ Limits & Expiry</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Daily Earning Limit (Coins)</label>
            <input type="number" value={caps.daily} onChange={(e) => setCaps({...caps, daily: Number(e.target.value)})} style={inputStyle} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Monthly Earning Limit (Coins)</label>
            <input type="number" value={caps.monthly} onChange={(e) => setCaps({...caps, monthly: Number(e.target.value)})} style={inputStyle} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 4 }}>Coin Expiry (Days)</label>
            <input type="number" value={expiryDays} onChange={(e) => setExpiryDays(Number(e.target.value))} style={inputStyle} />
          </div>
        </div>
      </div>

      {/* --- Section 3: Country Values (Dynamic) --- */}
      <div style={{ backgroundColor: 'white', padding: 20, borderRadius: 8, marginBottom: 20, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 16, borderBottom: '1px solid #eee', paddingBottom: 8 }}>🌍 Country Values (100 Coins = ?)</h2>
        <p style={{ fontSize: 13, color: '#6b7280', marginBottom: 16 }}>Define how much 100 coins are worth in each country's currency.</p>
        
        {/* 🆕 പുതിയ രാജ്യം ചേർക്കാനുള്ള ബാർ */}
        <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
          <select 
            value={selectedCountryToAdd} 
            onChange={(e) => setSelectedCountryToAdd(e.target.value)}
            style={{ ...inputStyle, flex: 1 }}
          >
            <option value="">— Select Country to Add —</option>
            {allCountries.map(c => (
              <option key={c.code} value={c.code} disabled={!!countryRates[c.code]}>
                {c.name} ({c.code}) {countryRates[c.code] ? '— Already Added' : ''}
              </option>
            ))}
          </select>
          <button 
            onClick={handleAddCountry}
            disabled={!selectedCountryToAdd}
            style={{ padding: '10px 20px', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: 6, cursor: selectedCountryToAdd ? 'pointer' : 'not-allowed', fontWeight: 600, opacity: selectedCountryToAdd ? 1 : 0.5 }}
          >
            + Add
          </button>
        </div>

        {/* 🆕 ലഭ്യമായ രാജ്യങ്ങളുടെ ലിസ്റ്റ് */}
        {Object.keys(countryRates).length === 0 ? (
          <p style={{ fontSize: 13, color: '#9ca3af' }}>No countries added yet.</p>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 16 }}>
            {Object.entries(countryRates).map(([code, value]) => {
              const countryData = allCountries.find(c => c.code === code);
              const displayName = countryData ? `${countryData.name} (${code})` : code;
              
              return (
                <div key={code} style={{ display: 'flex', alignItems: 'center', gap: 8, backgroundColor: '#f9fafb', padding: 10, borderRadius: 6, border: '1px solid #e5e7eb' }}>
                  <label style={{ flex: 1, fontSize: 13, fontWeight: 600, color: '#374151' }}>{displayName}</label>
                  <input 
                    type="number" 
                    value={value} 
                    onChange={(e) => handleRateChange(code, e.target.value)} 
                    style={{ ...inputStyle, width: 80 }} 
                  />
                  <button 
                    onClick={() => handleRemoveCountry(code)}
                    style={{ padding: '6px 10px', backgroundColor: '#fee2e2', color: '#dc2626', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 'bold' }}
                    title="Remove Country"
                  >
                    ✕
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>

    </div>
  );
}

const inputStyle = {
  width: '100%',
  padding: '10px 12px',
  border: '1px solid #d1d5db',
  borderRadius: 6,
  fontSize: 14,
  outline: 'none',
  backgroundColor: 'white',
  boxSizing: 'border-box',
};