const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function seedTrustScores() {
  console.log("🚀 Adding trustScore to all businesses...");
  const snapshot = await db.collection("businesses").get();
  const batch = db.batch();
  let count = 0;

  snapshot.forEach((doc) => {
    const data = doc.data();
    if (data.trustScore === undefined) {
      batch.update(doc.ref, { trustScore: 50.0 });
      count++;
    }
  });

  if (count > 0) {
    await batch.commit();
    console.log(`✅ Added trustScore to ${count} businesses!`);
  } else {
    console.log("✅ All businesses already have trustScore!");
  }
  process.exit(0);
}

seedTrustScores().catch(console.error);