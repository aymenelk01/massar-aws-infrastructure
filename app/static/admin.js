/* ============================================================
   admin.js — Massar Portal Admin Release Results Logic
   POST /admin/release-results with Bearer Token
   ============================================================ */

// API base URL — replace with your actual CloudFront 
const API_BASE_URL = "https://d1234567890abcdef.cloudfront.net";

// DOM references
const releaseBtn   = document.getElementById("release-btn");
const btnLabel     = document.getElementById("btn-label");
const btnSpinner   = document.getElementById("btn-spinner");
const successMsg   = document.getElementById("success-msg");
const successText  = document.getElementById("success-msg-text");
const errorMsg     = document.getElementById("error-msg");
const errorText    = document.getElementById("error-msg-text");
const logoutBtn    = document.getElementById("logout-btn");

// ── Auth Guard: check token presence ──────────────────────────
const token = sessionStorage.getItem("access_token");
if (!token) {
  sessionStorage.clear();
  window.location.replace("login.html");
}

// ── Helper: Clear sessions and route to login ────────────────
function handleSessionExpiry() {
  sessionStorage.clear();
  window.location.replace("login.html");
}

// ── Helpers: Show/Hide Message States ────────────────────────
function showSuccess(message) {
  successText.textContent = message;
  successMsg.hidden = false;
  errorMsg.hidden = true;
}

function showError(message) {
  errorText.textContent = message;
  errorMsg.hidden = false;
  successMsg.hidden = true;
}

function hideMessages() {
  successMsg.hidden = true;
  errorMsg.hidden = true;
}

/**
 * Set loading state on the release button.
 * @param {boolean} loading
 */
function setLoading(loading) {
  releaseBtn.disabled = loading;
  btnLabel.textContent = loading ? "Releasing..." : "Release Results";
  btnSpinner.hidden = !loading;
}

// ── Action: Release Results ──────────────────────────────────
releaseBtn.addEventListener("click", async () => {
  hideMessages();
  setLoading(true);

  try {
    const response = await fetch(`${API_BASE_URL}/admin/release-results`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({})
    });

    // If unauthorized or forbidden, redirect back to login page
    if (response.status === 401 || response.status === 403) {
      handleSessionExpiry();
      return;
    }

    let data = {};
    try {
      data = await response.json();
    } catch (_) {
      // Ignore parsing errors
    }

    if (response.ok) {
      const count = typeof data.count !== "undefined" ? data.count : 0;
      showSuccess(`Successfully queued exam results notifications for ${count} students.`);
    } else {
      const serverMessage = data.message || data.error || "An error occurred on the server.";
      showError(`Failed to release results: ${serverMessage}`);
    }
  } catch (err) {
    console.error("Error during release results request:", err);
    showError("Could not connect to the server. Please verify network access.");
  } finally {
    setLoading(false);
  }
});

// ── Event Handlers ───────────────────────────────────────────
logoutBtn.addEventListener("click", () => {
  handleSessionExpiry();
});
