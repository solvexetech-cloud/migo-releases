const admin = require('firebase-admin');
const serviceAccount = require('./admin/serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function createTestReel() {
  try {
    await db.collection('creator_content').add({
      collabId: 'test-collab-1',
      creatorId: 'test-creator-1',
      shopId: 'v2qxRjo4sxUvONqeYk2z',
      offerId: 'sRtMT9w7CvYtCRgXJmHF',
      platform: 'youtube',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      caption: 'Check out this amazing Pizza deal in Doha! 🍕',
      disclosureConfirmed: true,
      status: 'approved',
      viewsCount: 120,
      likesCount: 45,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('✅ Test Reel Created Successfully!');
  } catch (e) {
    console.error('❌ Error:', e.message);
  }
}

createTestReel();