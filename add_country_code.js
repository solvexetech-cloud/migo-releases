const admin = require('firebase-admin');
const serviceAccount = require('./_seed/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function addCountryCode() {
  const offersRef = db.collection('offers');
  const snapshot = await offersRef.get();

  let count = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!data.countryCode) {
      await doc.ref.update({ countryCode: 'QA' });
      console.log(`✅ Added countryCode to: ${data.title || doc.id}`);
      count++;
    }
  }
  console.log(`\n🎉 Done! Updated ${count} offers.`);
  process.exit(0);
}

addCountryCode().catch(console.error);