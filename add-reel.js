const admin = require('firebase-admin');
const serviceAccount = require('./admin/serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const db = admin.firestore();

async function addTestReel() {
  try {
    await db.collection('creator_content').add({
      collabId: 'test-collab-2',
      creatorId: 'test-creator-2',
      shopId: 'v2qxRjo4sxUvONqeYk2z',
      offerId: 'sRtMT9w7CvYtCRgXJmHF',
      platform: 'youtube',
      url: 'https://www.youtube.com/watch?v=9bZkp7q19f0',
      caption: 'Another amazing deal! Check this out! 🔥',
      disclosureConfirmed: true,
      status: 'approved',
      viewsCount: 200,
      likesCount: 80,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('✅ Second Test Reel Added!');
  } catch (e) {
    console.error('❌ Error:', e.message);
  }
}

addTestReel();