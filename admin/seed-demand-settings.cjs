// admin/seed-demand-settings.cjs
// FIXED VERSION - Works with Node.js v26 and latest firebase-admin

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// 1. Check if serviceAccountKey.json exists
let serviceAccount;
try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (error) {
  console.error('❌ ERROR: "serviceAccountKey.json" not found in this folder!');
  console.error('Please download it from Firebase Console (Project Settings > Service Accounts) and place it here.');
  process.exit(1);
}

// 2. Initialize Firebase Admin
try {
  initializeApp({
    credential: cert(serviceAccount),
  });
} catch (error) {
  console.error('❌ Error initializing Firebase Admin:', error.message);
  process.exit(1);
}

const db = getFirestore();

async function seedSettings() {
  console.log('🚀 Seeding Demand Settings...');

  const defaultSettings = {
    defaultThreshold: 3,
    categoryThresholds: {},
    autoGroupWindowHours: 72,
    demandExpiryDays: 7,
    allowPrivateBulk: true,
    privateBulkMinQuantity: 10,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: 'system_seed',
  };

  try {
    await db.collection('app_config').doc('demandSettings').set(defaultSettings);
    console.log('✅ Successfully created "demandSettings" in app_config!');
    console.log('Settings:', defaultSettings);
  } catch (error) {
    console.error('❌ Error seeding settings:', error.message);
  } finally {
    process.exit(0);
  }
}

seedSettings();