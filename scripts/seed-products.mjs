// Run from project root after: npm install firebase-admin
// Set GOOGLE_APPLICATION_CREDENTIALS to a Firebase service-account JSON path.
// Never commit the service-account file.
import admin from 'firebase-admin';
admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();
const categories = ['RO Purifier','UV Purifier','UF Purifier','Water Dispenser','Booster Pump','Sediment Filter','Carbon Filter','Membrane','Spare Part'];
const products = [
  ['AquaPure RO 7-Stage','RO Purifier','https://placehold.co/600x600/png?text=AquaPure+RO+7-Stage'],
  ['ClearWave UV Compact','UV Purifier','https://placehold.co/600x600/png?text=ClearWave+UV+Compact'],
  ['PureFlow UF Classic','UF Purifier','https://placehold.co/600x600/png?text=PureFlow+UF+Classic'],
  ['HydraCool Water Dispenser','Water Dispenser','https://placehold.co/600x600/png?text=HydraCool+Dispenser'],
  ['FlowMax Booster Pump','Booster Pump','https://placehold.co/600x600/png?text=FlowMax+Pump'],
  ['Sediment Filter 10-inch','Sediment Filter','https://placehold.co/600x600/png?text=Sediment+Filter'],
  ['Activated Carbon Filter','Carbon Filter','https://placehold.co/600x600/png?text=Carbon+Filter'],
  ['RO Membrane 75 GPD','Membrane','https://placehold.co/600x600/png?text=RO+Membrane'],
  ['Universal Filter Housing','Spare Part','https://placehold.co/600x600/png?text=Filter+Housing'],
];
let batch = db.batch(), count = 0;
for (let i = 1; i <= 54; i++) {
  const [base, category, imageUrl] = products[(i - 1) % products.length];
  const ref = db.collection('products').doc(`demo_${String(i).padStart(3,'0')}`);
  batch.set(ref, { name: i <= products.length ? base : `${base} - Model ${Math.ceil(i / products.length)}`, category,
    description: 'Demo catalog listing. Confirm specifications, warranty and compatibility before sale.',
    price: 499 + i * 125, wholesalePrice: 399 + i * 100, stock: 100, active: true, imageUrl,
    createdAt: admin.firestore.FieldValue.serverTimestamp() });
  count++;
  if (count % 400 === 0) { await batch.commit(); batch = db.batch(); }
}
if (count % 400 !== 0) await batch.commit();
console.log(`Seeded ${count} demo products. Replace placeholder images with real matching product imagery.`);
