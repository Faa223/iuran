from zipfile import ZipFile
import os

# Create a directory for the project
project_dir = "/mnt/data/iuran_firebase_web"
os.makedirs(project_dir, exist_ok=True)

# File contents
files = {
    "index.html": """<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Platform Iuran Bulanan</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <div id="loginSection" class="login-form">
    <h2>Login Admin</h2>
    <input type="email" id="email" placeholder="Email" required />
    <input type="password" id="password" placeholder="Password" required />
    <div id="loginError" class="error-message hidden"></div>
    <button id="loginBtn">Login Admin</button>
    <button id="guestBtn" class="guest">Masuk Tamu</button>
  </div>

  <div id="appContent" class="hidden">
    <header>
      <h1>Platform Iuran Bulanan</h1>
      <div class="auth-section">
        <span id="userGreeting"></span>
        <button id="logoutBtn" class="logout">Logout</button>
      </div>
    </header>

    <div class="stats">
      <div class="stat-box">
        <div class="stat-number" id="totalMembers">0</div>
        <div>Total Anggota</div>
      </div>
      <div class="stat-box">
        <div class="stat-number" id="totalPaid">Rp 0</div>
        <div>Total Terkumpul</div>
      </div>
      <div class="stat-box">
        <div class="stat-number" id="paymentPercentage">0%</div>
        <div>Pembayaran</div>
      </div>
    </div>

    <div class="members-list">
      <h2>Daftar Pembayaran Iuran</h2>
      <table id="paymentTable">
        <thead>
          <tr>
            <th>No</th>
            <th>Nama</th>
            <th>Status</th>
            <th>Tanggal</th>
            <th>Metode</th>
            <th id="actionHeader">Aksi</th>
          </tr>
        </thead>
        <tbody id="paymentTableBody"></tbody>
      </table>
    </div>

    <div id="adminSection" class="hidden">
      <div class="payment-form">
        <h3>Tambah Anggota</h3>
        <input type="text" id="newMemberName" placeholder="Nama anggota baru" />
        <button id="addMemberBtn">Tambah</button>
      </div>

      <div class="payment-form">
        <h3>Konfirmasi Pembayaran</h3>
        <select id="memberSelect">
          <option value="">Pilih Anggota</option>
        </select>
        <select id="paymentMethod">
          <option value="Transfer">Transfer</option>
          <option value="Tunai">Tunai</option>
        </select>
        <input type="date" id="paymentDate" />
        <button id="confirmPaymentBtn">Tandai Lunas</button>
      </div>
    </div>
  </div>

  <script type="module" src="firebase.js"></script>
  <script type="module" src="script.js"></script>
</body>
</html>""",
    "firebase.js": """import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyBGHNOBLrJfqOumS4FbugETg8NUZl3wRxM",
  authDomain: "iuran-bulanan-cfd8f.firebaseapp.com",
  projectId: "iuran-bulanan-cfd8f",
  storageBucket: "iuran-bulanan-cfd8f.appspot.com",
  messagingSenderId: "1018825632880",
  appId: "1:1018825632880:web:00bb8fcd5a70af8d1ad8b5",
  measurementId: "G-MD8Q4M3ZNN"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);""",
    "script.js": """import { auth, db } from './firebase.js';
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import {
  collection, getDocs, addDoc
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const loginBtn = document.getElementById('loginBtn');
const logoutBtn = document.getElementById('logoutBtn');
const guestBtn = document.getElementById('guestBtn');
const appContent = document.getElementById('appContent');
const loginSection = document.getElementById('loginSection');

const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const loginError = document.getElementById('loginError');

let isAdmin = false;

loginBtn.addEventListener('click', async () => {
  const email = emailInput.value;
  const password = passwordInput.value;

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    isAdmin = true;
    showApp();
  } catch (error) {
    loginError.classList.remove('hidden');
    loginError.textContent = "Email atau password salah.";
  }
});

guestBtn.addEventListener('click', () => {
  isAdmin = false;
  showApp();
});

logoutBtn.addEventListener('click', async () => {
  await signOut(auth);
  location.reload();
});

function showApp() {
  loginSection.classList.add('hidden');
  appContent.classList.remove('hidden');
  if (isAdmin) document.getElementById('adminSection').classList.remove('hidden');
  loadData();
}

async function loadData() {
  const membersSnapshot = await getDocs(collection(db, "members"));
  const paymentsSnapshot = await getDocs(collection(db, "payments"));

  const members = [];
  const payments = [];

  membersSnapshot.forEach(doc => {
    members.push({ id: doc.id, ...doc.data() });
  });

  paymentsSnapshot.forEach(doc => {
    payments.push(doc.data());
  });

  renderTable(members, payments);
}

function renderTable(members, payments) {
  const tableBody = document.getElementById("paymentTableBody");
  tableBody.innerHTML = "";

  const select = document.getElementById("memberSelect");
  select.innerHTML = '<option value="">Pilih Anggota</option>';

  let paidCount = 0;

  members.forEach((member, index) => {
    const payment = payments.find(p => p.memberId === member.id);
    if (payment) paidCount++;

    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${index + 1}</td>
      <td>${member.name}</td>
      <td class=\"${payment ? 'paid' : 'unpaid'}\">${payment ? 'Lunas' : 'Belum'}</td>
      <td>${payment ? payment.date : '-'}</td>
      <td>${payment ? payment.method : '-'}</td>
      <td>${isAdmin && !payment ? \`<button onclick=\"markAsPaid('\${member.id}')\">Lunas</button>\` : '-'}</td>
    `;
    tableBody.appendChild(tr);

    if (!payment) {
      const opt = document.createElement('option');
      opt.value = member.id;
      opt.textContent = member.name;
      select.appendChild(opt);
    }
  });

  document.getElementById("totalMembers").textContent = members.length;
  document.getElementById("totalPaid").textContent = `Rp ${(paidCount * 10000).toLocaleString()}`;
  document.getElementById("paymentPercentage").textContent = `${Math.round((paidCount / members.length) * 100)}%`;
}

window.markAsPaid = async function(memberId) {
  const method = document.getElementById("paymentMethod").value;
  const date = document.getElementById("paymentDate").value;

  if (!method || !date) {
    alert("Lengkapi metode dan tanggal");
    return;
  }

  await addDoc(collection(db, "payments"), {
    memberId,
    method,
    date
  });

  loadData();
};

document.getElementById("addMemberBtn").addEventListener("click", async () => {
  const name = document.getElementById("newMemberName").value.trim();
  if (!name) return;

  await addDoc(collection(db, "members"), { name });
  document.getElementById("newMemberName").value = "";
  loadData();
});

document.getElementById("confirmPaymentBtn").addEventListener("click", async () => {
  const memberId = document.getElementById("memberSelect").value;
  window.markAsPaid(memberId);
});"""
}

# Write files to directory
for filename, content in files.items():
    with open(os.path.join(project_dir, filename), "w", encoding="utf-8") as f:
        f.write(content)

# Create zip file
zip_path = "/mnt/data/iuran_firebase_web.zip"
with ZipFile(zip_path, "w") as zipf:
    for filename in files:
        zipf.write(os.path.join(project_dir, filename), arcname=filename)

zip_path
