const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

const flagMap = {
  "BH": "🇧🇭",
  "QA": "🇶🇦",
  "KW": "🇰🇼",
  "OM": "🇴🇲",
  "SA": "🇸🇦",
  "AE": "🇦🇪",
  "EG": "🇪🇬",
  "IN": "🇮🇳",
};

async function fixFlags() {
  console.log("🚀 Fixing flags...");
  const countriesRef = db.collection("countries");
  const snapshot = await countriesRef.get();

  const batch = db.batch();
  snapshot.forEach((doc) => {
    const code = doc.id;
    if (flagMap[code]) {
      batch.update(doc.ref, { flag: flagMap[code] });
      console.log(`✅ Fixed flag for ${code}`);
    }
  });

  await batch.commit();
  console.log("🎉 All flags fixed!");
  process.exit(0);
}

fixFlags().catch((err) => {
  console.error("❌ Error fixing flags:", err);
  process.exit(1);
});