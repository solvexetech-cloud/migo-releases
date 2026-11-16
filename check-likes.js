const admin = require('firebase-admin');
const serviceAccount = require('./admin/serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function check() {
  const likes = await db.collection('content_likes').get();
  console.log('Total Likes:', likes.docs.length);
  
  const saves = await db.collection('saved_reels').get();
  console.log('Total Saves:', saves.docs.length);
}
check();