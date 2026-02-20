// Script untuk set admin claim
// Usage: node set-admin.js admin@example.com

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Download dari Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const email = process.argv[2];

if (!email) {
  console.error('Usage: node set-admin.js <email>');
  process.exit(1);
}

admin.auth().getUserByEmail(email)
  .then((user) => {
    return admin.auth().setCustomUserClaims(user.uid, { admin: true });
  })
  .then(() => {
    console.log(`✅ ${email} is now an admin!`);
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
