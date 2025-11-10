const API = "REPLACE_WITH_API_BASE_URL"; // e.g., https://abc123.execute-api.eu-central-1.amazonaws.com/dev

async function signup() {
  const email = valueOf("email");
  const password = valueOf("password");
  const res = await fetch(API + "/auth/signup", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  const json = await res.json();
  if (json.user_id) setValue("user_id", json.user_id);
  output(json);
}

async function login() {
  const email = valueOf("email");
  const password = valueOf("password");
  const user_id = valueOf("user_id");
  const res = await fetch(API + "/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, user_id }),
  });
  const json = await res.json();
  if (json.token) localStorage.setItem("token", json.token);
  output(json);
}

async function sendComment() {
  const token = localStorage.getItem("token");
  const body = { content_id: valueOf("content_id"), text: valueOf("text") };
  const res = await fetch(API + "/comments", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + token,
    },
    body: JSON.stringify(body),
  });
  output(await res.json());
}

function valueOf(id) {
  return document.getElementById(id).value;
}

function setValue(id, value) {
  document.getElementById(id).value = value;
}

function output(value) {
  document.getElementById("out").textContent = JSON.stringify(value, null, 2);
}
