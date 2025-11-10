// === Konfiguration ===
// REST-URL für Kommentare (API Gateway, Typ: REST, CORS aktiviert).
// Das PDF nutzt 'key1' als Query-Parameter – wir übernehmen das 1:1.
const COMMENTS_API_URL = "https://YOUR_API_URL_FOR_COMMENTS";
// Optionaler GET-Endpunkt zum Listen. Wenn nicht vorhanden, bleiben Kommentare lokal.
const COMMENTS_LIST_API_URL = ""; // z.B. "https://.../comments/list"
// Video-Quelle (kann im UI geändert werden)
let VIDEO_URL = "https://samplelib.com/lib/preview/mp4/sample-5s.mp4"; // Demo-URL

// === Login (Stub) – [Außerhalb des Skripts] ===
function isLoggedIn() {
  return !!localStorage.getItem("demo_user");
}
function setLoginStatus() {
  const p = document.getElementById("loginStatus");
  p.textContent = isLoggedIn() ? "Eingeloggt als " + localStorage.getItem("demo_user") : "Nicht eingeloggt";
}
function login() {
  const u = document.getElementById("user").value.trim();
  const p = document.getElementById("pass").value;
  if (!u || !p) { alert("Bitte Name & Passwort ausfüllen (Demo)."); return; }
  localStorage.setItem("demo_user", u);
  setLoginStatus();
}

// === Video ===
function initVideo() {
  const player = document.getElementById("player");
  player.src = VIDEO_URL;
  const input = document.getElementById("videoUrl");
  input.value = VIDEO_URL;
}
function setVideo() {
  const input = document.getElementById("videoUrl");
  VIDEO_URL = input.value.trim();
  initVideo();
}

// === Kommentare ===
let localComments = [];

async function sendComment() {
  const status = document.getElementById("sendStatus");
  status.textContent = "Sende...";
  const user = localStorage.getItem("demo_user") || "anon";
  const comment = document.getElementById("comment").value.trim();
  if (!comment) { status.textContent = "Bitte Kommentar eingeben."; return; }

  try {
    // PDF-Muster: ?key1=<value>
    const resp = await fetch(COMMENTS_API_URL + "?key1=" + encodeURIComponent(user + ": " + comment));
    const text = await resp.text();
    status.textContent = "OK";
    // lokale Liste updaten (falls kein GET-Endpunkt existiert)
    localComments.unshift({ user, comment, ts: new Date().toISOString() });
    renderComments(localComments);
    document.getElementById("comment").value = "";
  } catch (e) {
    status.textContent = "Fehler (CORS? URL?)";
    console.error(e);
  }
}

async function loadComments() {
  const status = document.getElementById("loadStatus");
  status.textContent = "Lade...";
  if (!COMMENTS_LIST_API_URL) {
    status.textContent = "Nur lokale Demo – kein GET-Endpunkt gesetzt.";
    renderComments(localComments);
    return;
  }
  try {
    const resp = await fetch(COMMENTS_LIST_API_URL);
    const data = await resp.json();
    renderComments(Array.isArray(data) ? data : []);
    status.textContent = "OK";
  } catch (e) {
    status.textContent = "Fehler beim Laden";
    console.error(e);
  }
}

function renderComments(list) {
  const root = document.getElementById("comments");
  root.innerHTML = "";
  list.forEach(item => {
    const div = document.createElement("div");
    div.className = "comment";
    const who = document.createElement("div");
    who.innerHTML = '<span class="chip">' + (item.user || "anon") + "</span> • " + (item.ts || "");
    const txt = document.createElement("div");
    txt.textContent = item.comment || item;
    div.appendChild(who);
    div.appendChild(txt);
    root.appendChild(div);
  });
}

// === Boot ===
window.addEventListener("load", () => {
  document.getElementById("login").addEventListener("click", login);
  document.getElementById("setVideo").addEventListener("click", setVideo);
  document.getElementById("send").addEventListener("click", sendComment);
  document.getElementById("reload").addEventListener("click", loadComments);
  setLoginStatus();
  initVideo();
  renderComments(localComments);
});
