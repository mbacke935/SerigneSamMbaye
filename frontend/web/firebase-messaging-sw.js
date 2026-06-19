importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBVKQuyGe1-UM537aDuTiqqTwr18RIO1yY",
  authDomain: "serigne-sam-mbaye-app.firebaseapp.com",
  projectId: "serigne-sam-mbaye-app",
  storageBucket: "serigne-sam-mbaye-app.firebasestorage.app",
  messagingSenderId: "443768597916",
  appId: "1:443768597916:web:0c3961041def3a3ac8ac59"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Serigne Sam Mbaye';
  const body  = payload.notification?.body  ?? '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  });
});
