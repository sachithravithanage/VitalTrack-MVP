importScripts(
  "https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyDummyKeyForLocalEmulator",
  appId: "1:123456789:web:abcdef1234567890",
  messagingSenderId: "123456789",
  projectId: "vitaltrack-vcode",
  storageBucket: "vitaltrack-vcode.appspot.com",
});

firebase.messaging();
