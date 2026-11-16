const admin = require('firebase-admin');
const serviceAccount = require('./admin/serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const db = admin.firestore();

async function updateCreator() {
  try {
    const snap = await db.collection('creators').where('displayName', '==', 'Ahmed Vlogger').get();
    if (snap.empty) {
      console.log('Creator not found');
      return;
    }
    const doc = snap.docs[0];
    await doc.ref.update({
      'categories': ['food'],
      'instagramUrl': 'https://instagram.com/ahmedvlogs',
      'tiktokUrl': 'https://tiktok.com/@ahmedvlogs',
    });
    console.log('✅ Creator updated with categories and social links!');
  } catch (e) {
    console.error('❌ Error:', e.message);
  }
}

updateCreator();