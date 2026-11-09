const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function seedTheme() {
  console.log("🚀 Seeding full theme...");
  await db.collection("app_config").doc("theme").set({
    // Colors
    primaryColor: "#0F2B5B",       // Main Blue
    accentColor: "#D4AF37",        // Gold (Yellow instead)
    secondaryColor: "#F6F3EE",     // Background
    textPrimaryColor: "#1A1A1A",   // Main Text
    textSecondaryColor: "#6B6B6B", // Sub Text
    cardColor: "#FFFFFF",          // Card Background
    borderColor: "#E0E0E0",        // Borders
    
    // Shadows
    shadowColor: "#000000",
    shadowOpacity: 0.1,
    shadowBlur: 8,
    shadowOffsetY: 4,
    
    // Border Radius
    buttonRadius: 12,
    cardRadius: 16,
    
    updatedAt: new Date()
  });
  console.log("✅ Full theme seeded!");
  process.exit(0);
}

seedTheme().catch(console.error);