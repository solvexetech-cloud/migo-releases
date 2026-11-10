// admin/src/pages/DemandSettingsPage.jsx
// NEW FILE - Super Admin Demand Settings
// Created: Nov 09, 2026
// Purpose: Control thresholds, expiry, and bulk limits for the new Demand System

import React, { useState, useEffect } from 'react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase'; // Adjust path if your firebase config is elsewhere

const DemandSettingsPage = () => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ text: '', type: '' });

  const [settings, setSettings] = useState({
    defaultThreshold: 3,
    autoGroupWindowHours: 72,
    demandExpiryDays: 7,
    allowPrivateBulk: true,
    privateBulkMinQuantity: 10,
  });

  // Fetch current settings
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const docRef = doc(db, 'app_config', 'demandSettings');
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
          setSettings((prev) => ({ ...prev, ...docSnap.data() }));
        }
      } catch (error) {
        console.error('Error fetching settings:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchSettings();
  }, []);

  // Handle form changes
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setSettings((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : Number(value),
    }));
  };

  // Save settings
  const handleSave = async () => {
    setSaving(true);
    setMessage({ text: '', type: '' });

    try {
      const docRef = doc(db, 'app_config', 'demandSettings');
      await setDoc(
        docRef,
        {
          ...settings,
          updatedAt: serverTimestamp(),
          updatedBy: 'super_admin', // In a real app, use auth.currentUser.email
        },
        { merge: true }
      );

      setMessage({ text: 'Settings saved successfully!', type: 'success' });
    } catch (error) {
      console.error('Error saving settings:', error);
      setMessage({ text: 'Failed to save settings.', type: 'error' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div style={{ padding: '20px' }}>Loading settings...</div>;
  }

  return (
    <div style={{ padding: '24px', maxWidth: '800px', margin: '0 auto' }}>
      <h1 style={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '8px' }}>
        Demand System Settings
      </h1>
      <p style={{ color: '#666', marginBottom: '24px' }}>
        Control how customer demands are grouped and shown to businesses.
      </p>

      {message.text && (
        <div
          style={{
            padding: '12px',
            marginBottom: '20px',
            borderRadius: '8px',
            backgroundColor: message.type === 'success' ? '#e6fffa' : '#fff5f5',
            color: message.type === 'success' ? '#2c7a7b' : '#c53030',
            border: `1px solid ${message.type === 'success' ? '#b2f5ea' : '#feb2b2'}`,
          }}
        >
          {message.text}
        </div>
      )}

      <div style={{ backgroundColor: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        
        {/* Default Threshold */}
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '8px' }}>
            Minimum People Required (Default Threshold)
          </label>
          <p style={{ fontSize: '12px', color: '#666', marginBottom: '8px' }}>
            Demands are hidden from businesses until this many people want the same item.
          </p>
          <input
            type="number"
            name="defaultThreshold"
            value={settings.defaultThreshold}
            onChange={handleChange}
            min="1"
            style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ccc' }}
          />
        </div>

        {/* Auto Group Window */}
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '8px' }}>
            Auto-Group Window (Hours)
          </label>
          <p style={{ fontSize: '12px', color: '#666', marginBottom: '8px' }}>
            How long the system waits to collect similar demands before finalizing.
          </p>
          <input
            type="number"
            name="autoGroupWindowHours"
            value={settings.autoGroupWindowHours}
            onChange={handleChange}
            min="1"
            style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ccc' }}
          />
        </div>

        {/* Demand Expiry */}
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '8px' }}>
            Demand Expiry (Days)
          </label>
          <p style={{ fontSize: '12px', color: '#666', marginBottom: '8px' }}>
            Demands automatically expire after this many days if no bid is placed.
          </p>
          <input
            type="number"
            name="demandExpiryDays"
            value={settings.demandExpiryDays}
            onChange={handleChange}
            min="1"
            style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ccc' }}
          />
        </div>

        <hr style={{ margin: '24px 0', borderColor: '#eee' }} />

        {/* Private Bulk Settings */}
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'flex', alignItems: 'center', fontWeight: 'bold', marginBottom: '8px', cursor: 'pointer' }}>
            <input
              type="checkbox"
              name="allowPrivateBulk"
              checked={settings.allowPrivateBulk}
              onChange={handleChange}
              style={{ marginRight: '10px', width: '18px', height: '18px' }}
            />
            Allow Private Bulk Orders
          </label>
          <p style={{ fontSize: '12px', color: '#666', marginBottom: '8px' }}>
            If disabled, all demands go through the community grouping process.
          </p>
        </div>

        {settings.allowPrivateBulk && (
          <div style={{ marginBottom: '20px', paddingLeft: '28px' }}>
            <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '8px' }}>
              Private Bulk Minimum Quantity
            </label>
            <p style={{ fontSize: '12px', color: '#666', marginBottom: '8px' }}>
              If a customer asks for this many items (e.g., 10), it becomes a Private Bulk (no grouping needed).
            </p>
            <input
              type="number"
              name="privateBulkMinQuantity"
              value={settings.privateBulkMinQuantity}
              onChange={handleChange}
              min="2"
              style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ccc' }}
            />
          </div>
        )}

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={saving}
          style={{
            padding: '12px 24px',
            backgroundColor: saving ? '#ccc' : '#0F2B5B',
            color: '#fff',
            border: 'none',
            borderRadius: '8px',
            fontWeight: 'bold',
            cursor: saving ? 'not-allowed' : 'pointer',
            width: '100%',
          }}
        >
          {saving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>
    </div>
  );
};

export default DemandSettingsPage;