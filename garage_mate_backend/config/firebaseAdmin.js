const {
  initializeApp,
  cert,
  getApps,
} = require("firebase-admin/app");

const {
  getMessaging,
} = require("firebase-admin/messaging");

const {
  getAuth,
} = require("firebase-admin/auth");

const serviceAccount = require(
  "../firebase-service-account.json"
);


// =====================================================
// INITIALIZE FIREBASE ADMIN
// =====================================================

let firebaseApp;

if (getApps().length === 0) {
  firebaseApp = initializeApp({
    credential: cert(serviceAccount),
  });
} else {
  firebaseApp = getApps()[0];
}


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  firebaseApp,
  auth: getAuth(firebaseApp),
  messaging: getMessaging(firebaseApp),
};