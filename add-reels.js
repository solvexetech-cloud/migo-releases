const admin = require('firebase-admin');
const serviceAccount = require('./admin/serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const db = admin.firestore();

async function addTestReels() {
  try {
    // Video 1: Facebook
    await db.collection('creator_content').add({
      collabId: 'test-collab-fb',
      creatorId: 'test-creator-fb',
      shopId: 'v2qxRjo4sxUvONqeYk2z',
      offerId: 'sRtMT9w7CvYtCRgXJmHF',
      platform: 'facebook',
      url: 'https://www.facebook.com/watch/?v=10153231379946729', // Facebook Video
      caption: 'Facebook deal! Check it out! 🎉',
      disclosureConfirmed: true,
      status: 'approved',
      viewsCount: 150,
      likesCount: 50,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Video 2: Instagram
    await db.collection('creator_content').add({
      collabId: 'test-collab-insta',
      creatorId: 'test-creator-insta',
      shopId: 'v2qxRjo4sxUvONqeYk2z',
      offerId: 'sRtMT9w7CvYtCRgXJmHF',
      platform: 'instagram',
      url: 'https://www.instagram.com/reel/C0y5Z7dLqXp/', // Instagram Reel
      caption: 'Instagram reel deal! 🔥',
      disclosureConfirmed: true,
      status: 'approved',
      viewsCount: 300,
      likesCount: 120,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Video 3: TikTok
    await db.collection('creator_content').add({
      collabId: 'test-collab-tiktok',
      creatorId: 'test-creator-tiktok',
      shopId: 'v2qxRjo4sxUvONqeYk2z',
      offerId: 'sRtMT9w7CvYtCRgXJmHF',
      platform: 'tiktok',
      url: 'https://www.tiktok.com/@scout2015/video/6718335390845095173', // TikTok Video
      caption: 'TikTok deal! 💃',
      disclosureConfirmed: true,
      status: 'approved',
      viewsCount: 500,
      likesCount: 200,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ 3 Test Reels Added Successfully!');
  } catch (e) {
    console.error('❌ Error:', e.message);
  }
}

addTestReels();