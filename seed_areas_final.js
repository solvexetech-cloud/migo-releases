const admin = require('firebase-admin');
const serviceAccount = require('./_seed/serviceAccountKey.json');

// Firebase Admin SDK Initialize
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'migo-app-3030e',
  });
}

const db = admin.firestore();

// Areas Data (Zone Slug -> List of Areas)
const areasData = {
  'dubai': [
    { id: 'downtown-dubai', name: 'Downtown Dubai', order: 1 },
    { id: 'dubai-marina', name: 'Dubai Marina', order: 2 },
    { id: 'jumeirah', name: 'Jumeirah', order: 3 },
    { id: 'deira', name: 'Deira', order: 4 },
  ],
  'abu-dhabi': [
    { id: 'corniche', name: 'Corniche', order: 1 },
    { id: 'al-reem-island', name: 'Al Reem Island', order: 2 },
  ],
  'sharjah': [
    { id: 'al-majaz', name: 'Al Majaz', order: 1 },
    { id: 'al-nahda', name: 'Al Nahda', order: 2 },
  ],
  'riyadh': [
    { id: 'olaya', name: 'Olaya', order: 1 },
    { id: 'al-malaz', name: 'Al Malaz', order: 2 },
  ],
  'jeddah': [
    { id: 'al-balad', name: 'Al Balad', order: 1 },
    { id: 'corniche-jeddah', name: 'Corniche', order: 2 },
  ],
  'dammam': [
    { id: 'al-faisaliyah', name: 'Al Faisaliyah', order: 1 },
  ],
  'kuwait-city': [
    { id: 'salmiya', name: 'Salmiya', order: 1 },
    { id: 'fahaheel', name: 'Fahaheel', order: 2 },
  ],
  'hawalli': [
    { id: 'salwa', name: 'Salwa', order: 1 },
  ],
  'muscat': [
    { id: 'al-qurum', name: 'Al Qurum', order: 1 },
    { id: 'ruwi', name: 'Ruwi', order: 2 },
  ],
  'salalah': [
    { id: 'salalah-center', name: 'Salalah Center', order: 1 },
  ],
  'manama': [
    { id: 'seef', name: 'Seef', order: 1 },
    { id: 'juffair', name: 'Juffair', order: 2 },
  ],
  'muharraq': [
    { id: 'arad', name: 'Arad', order: 1 },
  ],
  'ernakulam': [
    { id: 'kochi', name: 'Kochi', order: 1 },
  ],
  'thiruvananthapuram': [
    { id: 'trivandrum', name: 'Trivandrum', order: 1 },
  ],
  'kozhikode': [
    { id: 'kozhikode-city', name: 'Kozhikode City', order: 1 },
  ],
  'thrissur': [
    { id: 'thrissur-city', name: 'Thrissur City', order: 1 },
  ],
  'mumbai': [
    { id: 'andheri', name: 'Andheri', order: 1 },
    { id: 'bandra', name: 'Bandra', order: 2 },
    { id: 'colaba', name: 'Colaba', order: 3 },
  ],
  'delhi': [
    { id: 'connaught-place', name: 'Connaught Place', order: 1 },
    { id: 'karol-bagh', name: 'Karol Bagh', order: 2 },
  ],
  'bangalore': [
    { id: 'indiranagar', name: 'Indiranagar', order: 1 },
    { id: 'koramangala', name: 'Koramangala', order: 2 },
  ],
  'chennai': [
    { id: 't-nagar', name: 'T Nagar', order: 1 },
    { id: 'adyar', name: 'Adyar', order: 2 },
  ],
};

async function seedAreas() {
  console.log('🚀 Seeding Areas...');

  for (const [zoneSlug, areaList] of Object.entries(areasData)) {
    for (const area of areaList) {
      try {
        await db.collection('areas').doc(area.id).set({
          name: area.name,
          zoneSlug: zoneSlug,
          order: area.order,
          active: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Added: ${area.name} (${zoneSlug})`);
      } catch (e) {
        console.error(`❌ Failed: ${area.name} (${zoneSlug}) - ${e.message}`);
      }
    }
  }

  console.log('\n🎉 Done! All areas processed.');
  process.exit(0);
}

seedAreas().catch(console.error);