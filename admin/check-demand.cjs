const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkDemands() {
  const snapshot = await db.collection("demands").where("title.en", "==", "Beef Mandhi").limit(1).get();
  if (snapshot.empty) {
    console.log("❌ Beef Mandhi not found");
    process.exit(0);
  }
  snapshot.forEach((doc) => {
    console.log("Beef Mandhi Data:", JSON.stringify(doc.data(), null, 2));
  });
  process.exit(0);
}

checkDemands().catch(console.error);