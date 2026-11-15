const admin = require('firebase-admin');
const serviceAccount = require('./admin/serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function check() {
  const pin = '416891';
  const snap = await db.collection('claims').where('pickupCode', '==', pin).get();
  
  if (snap.empty) {
    console.log('❌ No claim found with PIN ' + pin);
  } else {
    snap.forEach(doc => {
      const d = doc.data();
      console.log('✅ Claim Found:');
      console.log('ID:', doc.id);
      console.log('Status:', d.status);
      console.log('BusinessId:', d.businessId);
      console.log('OfferTitle:', d.offerTitle);
    });
  }
}
check().catch(e => console.error(e));