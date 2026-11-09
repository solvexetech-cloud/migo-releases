const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

const locations = [
  { country: "Bahrain", code: "BH", flag: "🇧🇭", currency: "BHD", dialCode: "+973", timezone: "Asia/Bahrain", regions: ["Bahrain"] },
  { country: "Qatar", code: "QA", flag: "🇶🇦", currency: "QAR", dialCode: "+974", timezone: "Asia/Qatar", regions: ["Doha", "Al Rayyan", "Al Wakra", "Al Khor", "Al Shamal", "Al-Shahaniya", "Umm Salal", "Al Daayen"] },
  { country: "Kuwait", code: "KW", flag: "🇰🇼", currency: "KWD", dialCode: "+965", timezone: "Asia/Kuwait", regions: ["Kuwait City", "Ahmadi Governorate", "Jahra Governorate"] },
  { country: "Oman", code: "OM", flag: "🇴🇲", currency: "OMR", dialCode: "+968", timezone: "Asia/Muscat", regions: ["Muscat", "Salalah", "Sohar", "Ibri", "Nizwa"] },
  { country: "Saudi Arabia", code: "SA", flag: "🇸🇦", currency: "SAR", dialCode: "+966", timezone: "Asia/Riyadh", regions: ["Dammam", "Jeddah", "Riyadh", "Hafar Al Batin", "Hail", "Al Hasa", "Jubail", "Al Khobar", "Mecca", "Medina", "Ta'if", "Buraidah", "Tabuk", "Khamis Mushait", "Al-Kharj", "Abha", "Najran", "Yanbu", "Jazan", "Sakaka", "Arar", "Al Bahah", "Rafha", "Qatif", "Ar Rass", "Unayzah", "Bishah", "Al Duwadimi", "Al Majmaah", "Mahayil", "Ras Tanura", "Khafji", "Saihat", "Al Qunfudhah", "Az Zulfi", "Wadi ad Dawasir"] },
  { country: "United Arab Emirates", code: "AE", flag: "🇦🇪", currency: "AED", dialCode: "+971", timezone: "Asia/Dubai", regions: ["Dubai", "Abu Dhabi", "Sharjah and Ajman", "Al Ain", "Fujairah", "Ras al Khaimah", "Umm al Quwain"] },
  { country: "Egypt", code: "EG", flag: "🇪🇬", currency: "EGP", dialCode: "+20", timezone: "Africa/Cairo", regions: ["Cairo"] }
];

async function seedData() {
  console.log("🚀 Starting seed process...");
  
  for (const loc of locations) {
    const countryRef = db.collection("countries").doc(loc.code);
    await countryRef.set({
      name: loc.country,
      flag: loc.flag,
      currency: loc.currency,
      dialCode: loc.dialCode,
      timezone: loc.timezone,
      active: true,
      createdAt: new Date(),
    });
    console.log(`✅ Added Country: ${loc.country}`);

    const batch = db.batch();
    for (const region of loc.regions) {
      // സ്ലാഷുകൾ ഒഴിവാക്കാൻ ഇവിടെ മാറ്റം വരുത്തി
      const regionSlug = region.toLowerCase().replace(/ /g, "-").replace(/'/g, "").replace(/\//g, "-");
      const zoneRef = db.collection("zones").doc(`${loc.code}-${regionSlug}`);
      batch.set(zoneRef, {
        name: region,
        countryCode: loc.code,
        active: true,
        createdAt: new Date(),
      });
    }
    await batch.commit();
    console.log(`   ↳ Added ${loc.regions.length} regions for ${loc.country}`);
  }
  
  console.log("🎉 Seed completed successfully!");
  process.exit(0);
}

seedData().catch((err) => {
  console.error("❌ Error seeding data:", err);
  process.exit(1);
});