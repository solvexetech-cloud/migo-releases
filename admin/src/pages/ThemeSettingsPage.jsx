import React, { useState, useEffect } from "react";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { db } from "../firebase";

const ThemeSettingsPage = () => {
  const [theme, setTheme] = useState({
    primaryColor: "#0F2B5B",
    accentColor: "#D4AF37",
    secondaryColor: "#F6F3EE",
    textPrimaryColor: "#1A1A1A",
    textSecondaryColor: "#6B6B6B",
    cardColor: "#FFFFFF",
    borderColor: "#E0E0E0",
    shadowColor: "#000000",
    shadowOpacity: 0.1,
    shadowBlur: 8,
    shadowOffsetY: 4,
    buttonRadius: 12,
    cardRadius: 16,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchTheme = async () => {
      const docRef = doc(db, "app_config", "theme");
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) setTheme(docSnap.data());
      setLoading(false);
    };
    fetchTheme();
  }, []);

  const handleChange = (e) => {
    setTheme({ ...theme, [e.target.name]: e.target.value });
  };

  const handleSave = async () => {
    await setDoc(doc(db, "app_config", "theme"), { ...theme, updatedAt: new Date() });
    alert("✅ Theme updated successfully! Restart the customer app to see changes.");
  };

  if (loading) return <div style={{ padding: 20 }}>Loading...</div>;

  const ColorField = ({ label, name, value }) => (
    <div style={{ marginBottom: 20 }}>
      <label style={{ display: "block", fontWeight: "bold", marginBottom: 8 }}>{label}</label>
      <div style={{ display: "flex", gap: 10 }}>
        <input type="color" name={name} value={value} onChange={handleChange} style={{ width: 50, height: 40, cursor: "pointer" }} />
        <input type="text" name={name} value={value} onChange={handleChange} style={{ flex: 1, padding: 8, border: "1px solid #ccc", borderRadius: 6 }} />
      </div>
    </div>
  );

  const NumberField = ({ label, name, value, min, max, step }) => (
    <div style={{ marginBottom: 20 }}>
      <label style={{ display: "block", fontWeight: "bold", marginBottom: 8 }}>{label}: {value}</label>
      <input type="range" name={name} value={value} onChange={handleChange} min={min} max={max} step={step} style={{ width: "100%" }} />
    </div>
  );

  return (
    <div style={{ padding: 20, maxWidth: 800 }}>
      <h1 style={{ fontSize: 24, fontWeight: 900, color: "#0F2B5B", marginBottom: 20 }}>App Theme Settings</h1>
      <div style={{ background: "#fff", borderRadius: 12, padding: 20, boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}>
        
        <h2 style={{ fontSize: 18, fontWeight: 800, marginBottom: 16, color: "#0F2B5B" }}>Colors</h2>
        <ColorField label="Primary Color (Blue)" name="primaryColor" value={theme.primaryColor} />
        <ColorField label="Accent Color (Gold)" name="accentColor" value={theme.accentColor} />
        <ColorField label="Background Color" name="secondaryColor" value={theme.secondaryColor} />
        <ColorField label="Text Primary Color" name="textPrimaryColor" value={theme.textPrimaryColor} />
        <ColorField label="Text Secondary Color" name="textSecondaryColor" value={theme.textSecondaryColor} />
        <ColorField label="Card Background Color" name="cardColor" value={theme.cardColor} />
        <ColorField label="Border Color" name="borderColor" value={theme.borderColor} />

        <h2 style={{ fontSize: 18, fontWeight: 800, marginTop: 32, marginBottom: 16, color: "#0F2B5B" }}>Shadows</h2>
        <ColorField label="Shadow Color" name="shadowColor" value={theme.shadowColor} />
        <NumberField label="Shadow Opacity" name="shadowOpacity" value={theme.shadowOpacity} min={0} max={1} step={0.05} />
        <NumberField label="Shadow Blur" name="shadowBlur" value={theme.shadowBlur} min={0} max={30} step={1} />
        <NumberField label="Shadow Offset Y" name="shadowOffsetY" value={theme.shadowOffsetY} min={0} max={20} step={1} />

        <h2 style={{ fontSize: 18, fontWeight: 800, marginTop: 32, marginBottom: 16, color: "#0F2B5B" }}>Border Radius</h2>
        <NumberField label="Button Radius" name="buttonRadius" value={theme.buttonRadius} min={0} max={30} step={1} />
        <NumberField label="Card Radius" name="cardRadius" value={theme.cardRadius} min={0} max={30} step={1} />

        <button onClick={handleSave} style={{ width: "100%", padding: 12, background: "#0F2B5B", color: "#fff", border: "none", borderRadius: 6, fontWeight: "bold", cursor: "pointer", fontSize: 16, marginTop: 20 }}>
          Save Theme
        </button>
      </div>
    </div>
  );
};

export default ThemeSettingsPage;