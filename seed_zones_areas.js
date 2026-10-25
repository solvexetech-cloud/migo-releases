const admin = require('firebase-admin');
const serviceAccount = require('./_seed/serviceAccountKey.json');

// firebase-admin-ന്റെ പുതിയ വേർഷനിൽ credential.cert() ഉപയോഗിക്കണം
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Zones (Country Code → Zones)
const zones = {
  'AE': [
    { slug: 'dubai', name: 'Dubai', order: 1 },
    { slug: 'abu-dhabi', name: 'Abu Dhabi', order: 2 },
    { slug: 'sharjah', name: 'Sharjah', order: 3 },
  ],
  'SA': [
    { slug: 'riyadh', name: 'Riyadh', order: 1 },
    { slug: 'jeddah', name: 'Jeddah', order: 2 },
    { slug: 'dammam', name: 'Dammam', order: 3 },
  ],
  'KW': [
    { slug: 'kuwait-city', name: 'Kuwait City', order: 1 },
    { slug: 'hawalli', name: 'Hawalli', order: 2 },
  ],
  'OM': [
    { slug: 'muscat', name: 'Muscat', order: 1 },
    { slug: 'salalah', name: 'Salalah', order: 2 },
  ],
  'BH': [
    { slug: 'manama', name: 'Manama', order: 1 },
    { slug: 'muharraq', name: 'Muharraq', order: 2 },
  ],
  'IN': [
    { slug: 'kerala', name: 'Kerala', order: 1 },
    { slug: 'mumbai', name: 'Mumbai', order: 2 },
    { slug: 'delhi', name: 'Delhi', order: 3 },
    { slug: 'bangalore', name: 'Bangalore', order: 4 },
    { slug: 'chennai', name: 'Chennai', order: 5 },
  ],
};

// Areas (Zone Slug → Areas)
const areas = {
  'dubai': [
    { slug: 'downtown-dubai', name: 'Downtown Dubai', order: 1 },
    { slug: 'dubai-marina', name: 'Dubai Marina', order: 2 },
    { slug: 'jumeirah', name: 'Jumeirah', order: 3 },
    { slug: 'deira', name: 'Deira', order: 4 },
  ],
  'abu-dhabi': [
    { slug: 'corniche', name: 'Corniche', order: 1 },
    { slug: 'al-reem-island', name: 'Al Reem Island', order: 2 },
  ],
  'sharjah': [
    { slug: 'al-majaz', name: 'Al Majaz', order: 1 },
    { slug: 'al-nahda', name: 'Al Nahda', order: 2 },
  ],
  'riyadh': [
    { slug: 'olaya', name: 'Olaya', order: 1 },
    { slug: 'al-malaz', name: 'Al Malaz', order: 2 },
  ],
  'jeddah': [
    { slug: 'al-balad', name: 'Al Balad', order: 1 },
    { slug: 'corniche-jeddah', name: 'Corniche', order: 2 },
  ],
  'dammam': [
    { slug: 'al-faisaliyah', name: 'Al Faisaliyah', order: 1 },
  ],
  'kuwait-city': [
    { slug: 'salmiya', name: 'Salmiya', order: 1 },
    { slug: 'fahaheel', name: 'Fahaheel', order: 2 },
  ],
  'hawalli': [
    { slug: 'salwa', name: 'Salwa', order: 1 },
  ],
  'muscat': [
    { slug: 'al-qurum', name: 'Al Qurum', order: 1 },
    { slug: 'ruwi', name: 'Ruwi', order: 2 },
  ],
  'salalah': [
    { slug: 'salalah-center', name: 'Salalah Center', order: 1 },
  ],
  'manama': [
    { slug: 'seef', name: 'Seef', order: 1 },
    { slug: 'juffair', name: 'Juffair', order: 2 },
  ],
  'muharraq': [
    { slug: 'arad', name: 'Arad', order: 1 },
  ],
  'kerala': [
    { slug: 'kochi', name: 'Kochi', order: 1 },
    { slug: 'trivandrum', name: 'Trivandrum', order: 2 },
    { slug: 'kozhikode', name: 'Kozhikode', order: 3 },
    { slug: 'thrissur', name: 'Thrissur', order: 4 },
  ],
  'mumbai': [
    { slug: 'andheri', name: 'Andheri', order: 1 },
    { slug: 'bandra', name: 'Bandra', order: 2 },
    { slug: 'colaba', name: 'Colaba', order: 3 },
  ],
  'delhi': [
    { slug: 'connaught-place', name: 'Connaught Place', order: 1 },
    { slug: 'karol-bagh', name: 'Karol Bagh', order: 2 },
  ],
  'bangalore': [
    { slug: 'indiranagar', name: 'Indiranagar', order: 1 },
    { slug: 'koramangala', name: 'Koramangala', order: 2 },
  ],
  'chennai': [
    { slug: 't-nagar', name: 'T Nagar', order: 1 },
    { slug: 'adyar', name: 'Adyar', order: 2 },
  ],
};

async function seedData() {
  console.log('🚀 Seeding Zones...');
  for (const [countryCode, zoneList] of Object.entries(zones)) {
    for (const zone of zoneList) {
      await db.collection('zones').doc(zone.slug).set({
        slug: zone.slug,
        name: zone.name,
        countryCode: countryCode,
        order: zone.order,
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ Zone: ${zone.name} (${countryCode})`);
    }
  }

  console.log('\n🚀 Seeding Areas...');
  for (const [zoneSlug, areaList] of Object.entries(areas)) {
    for (const area of areaList) {
      await db.collection('areas').doc(area.slug).set({
        slug: area.slug,
        name: area.name,
        zoneSlug: zoneSlug,
        order: area.order,
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ Area: ${area.name} (${zoneSlug})`);
    }
  }

  console.log('\n🎉 Done! All zones and areas seeded.');
  process.exit(0);
}

seedData().catch(console.error);