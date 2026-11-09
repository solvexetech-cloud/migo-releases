const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkBusiness() {
  const snapshot = await db.collection("businesses").limit(1).get();
  if (snapshot.empty) {
    console.log("❌ No businesses found");
    process.exit(0);
  }
  snapshot.forEach((doc) => {
    console.log("Business ID:", doc.id);
    console.log("Data:", JSON.stringify(doc.data(), null, 2));
  });
  process.exit(0);
}

checkBusiness().catch(console.error);