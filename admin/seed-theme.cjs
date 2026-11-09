const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function seedTheme() {
  console.log("🚀 Seeding theme colors...");
  await db.collection("app_config").doc("theme").set({
    primaryColor: "#0F2B5B", // നീല (MIGO നിറം)
    accentColor: "#D4AF37",  // സ്വർണ്ണ നിറം (Yellow-ന് പകരം)
    secondaryColor: "#F6F3EE", // ബാക്ക്ഗ്രൗണ്ട്
    updatedAt: new Date()
  });
  console.log("✅ Theme colors seeded!");
  process.exit(0);
}

seedTheme().catch(console.error);