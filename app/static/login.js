/* ============================================================
   login.js — Massar Portal Login Logic
   POST /login → store access_token → redirect to results.html
   ============================================================ */

/// API base URL — replace with your actual CloudFront 
const API_BASE_URL = "https://d1234567890abcdef.cloudfront.net";

// DOM references
const form           = document.getElementById("login-form");
const usernameInput  = document.getElementById("username");
const passwordInput  = document.getElementById("password");
const submitBtn      = document.getElementById("submit-btn");
const btnLabel       = document.getElementById("btn-label");
const btnSpinner     = document.getElementById("btn-spinner");
const errorMsg       = document.getElementById("error-msg");
const errorMsgText   = document.getElementById("error-msg-text");
const passwordToggle = document.getElementById("password-toggle");

// ── Redirect if already authenticated ────────────────────────
if (sessionStorage.getItem("access_token")) {
  window.location.replace("results.html");
}

// ── Password visibility toggle ───────────────────────────────
passwordToggle.addEventListener("click", function () {
  const isPassword = passwordInput.type === "password";
  passwordInput.type = isPassword ? "text" : "password";
  this.setAttribute("aria-pressed", isPassword);
  const icon = document.getElementById("eye-icon");
  icon.style.opacity = isPassword ? "0.5" : "1";
});

// ── Helpers ──────────────────────────────────────────────────

/**
 * Show an error banner with the given message.
 * @param {string} message
 */
function showError(message) {
  errorMsgText.textContent = message;
  errorMsg.hidden = false;
  errorMsg.focus();
}

/** Hide the error banner. */
function hideError() {
  errorMsg.hidden = true;
  errorMsgText.textContent = "";
}

/**
 * Set loading state on the submit button.
 * @param {boolean} loading
 */
function setLoading(loading) {
  submitBtn.disabled = loading;
  btnLabel.textContent = loading ? "Authenticating..." : "Log In";
  btnSpinner.hidden = !loading;
}

// ── Form Submit Handler ───────────────────────────────────────
form.addEventListener("submit", async function (event) {
  event.preventDefault();
  hideError();

  const username = usernameInput.value.trim();
  const password = passwordInput.value;

  // Basic client-side validation
  if (!username || !password) {
    showError("Please enter your Massar Code and password.");
    return;
  }

  setLoading(true);

  try {
    const response = await fetch(`${API_BASE_URL}/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ username, password })
    });

    let data = {};
    try {
      data = await response.json();
    } catch (_) {
      // Ignore parsing errors
    }

    if (response.ok && data.access_token) {
      // Store the access token in sessionStorage (cleared on tab close)
      sessionStorage.setItem("access_token", data.access_token);

      if (data.id_token)      sessionStorage.setItem("id_token", data.id_token);
      if (data.refresh_token) sessionStorage.setItem("refresh_token", data.refresh_token);

      // Redirect to the results page
      window.location.replace("results.html");
    } else {
      // Authentication failure
      const serverMessage = data.message || data.error || "";
      if (response.status === 401 || response.status === 403) {
        showError("Invalid Massar Code or password. Please try again.");
      } else if (serverMessage) {
        showError(`Authentication failed: ${serverMessage}`);
      } else {
        showError("An error occurred during authentication. Please try again later.");
      }
    }
  } catch (networkError) {
    console.error("Network error during login:", networkError);
    showError("Failed to connect to the server. Please check your internet connection and try again.");
  } finally {
    setLoading(false);
  }
});

// Clear error on input change
usernameInput.addEventListener("input", hideError);
passwordInput.addEventListener("input", hideError);
