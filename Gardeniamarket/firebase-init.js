import { initializeApp } from "https://www.gstatic.com/firebasejs/9.1.3/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.1.3/firebase-analytics.js";

const firebaseConfig = {
apiKey: "AIzaSyCBWrU8jvaMjrachP9amOX1zJ-KavEPTjo",
authDomain: "gardeniatodaynew.firebaseapp.com",
projectId: "gardeniatodaynew",
storageBucket: "gardeniatodaynew.firebasestorage.app",
messagingSenderId: "805080687276",
appId: "1:805080687276:web:8cfa2db1884f916b1ff509",
  measurementId: "G-0KWN75E378"
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);