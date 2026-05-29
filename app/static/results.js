/* ============================================================
   results.js — Massar Portal Results Page Logic
   GET /results with Bearer Token → Render Student Details & Grades
   ============================================================ */

// API base URL — replace with your actual CloudFront 
const API_BASE_URL = "https://d1234567890abcdef.cloudfront.net";

// DOM references
const loadingState = document.getElementById("loading-state");
const resultsState = document.getElementById("results-state");
const errorState   = document.getElementById("error-state");
const errorMsgText = document.getElementById("error-msg-text");

const studentName  = document.getElementById("student-name");
const studentCode  = document.getElementById("student-code");
const resultBadge  = document.getElementById("result-badge");
const resultLabel  = document.getElementById("result-label");
const subjectsTbody = document.getElementById("subjects-tbody");
const averageGrade = document.getElementById("average-grade");
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

// ── Helper: Calculate Grade Status ───────────────────────────
/**
 * Determines grade status description.
 * @param {number} grade
 * @returns {{text: string, className: string}}
 */
function getGradeStatus(grade) {
  if (grade >= 10.0) {
    return { text: "Passed", className: "grade-badge--pass" };
  } else {
    return { text: "Failed", className: "grade-badge--fail" };
  }
}

// ── Fetch and Render Results ─────────────────────────────────
async function loadResults() {
  try {
    const response = await fetch(`${API_BASE_URL}/results`, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${token}`
      }
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
      // 1. Student Info & Badge
      studentName.textContent = data.full_name || "—";
      studentCode.textContent = data.code_massar || "—";

      const outcome = data.result || "Ajourné";
      if (outcome === "Admis") {
        resultLabel.textContent = "Admitted";
        resultBadge.className = "result-badge result-badge--pass";
      } else {
        resultLabel.textContent = "Deferred";
        resultBadge.className = "result-badge result-badge--fail";
      }

      // 2. Clear subjects body
      subjectsTbody.innerHTML = "";

      const subjects = data.subject_results || [];
      let totalGrades = 0;
      let subjectCount = 0;

      // 3. Render each subject row
      subjects.forEach(sub => {
        const gradeValue = parseFloat(sub.grade);
        const hasGrade = !isNaN(gradeValue);
        
        if (hasGrade) {
          totalGrades += gradeValue;
          subjectCount++;
        }

        const status = hasGrade ? getGradeStatus(gradeValue) : { text: "—", className: "" };
        const gradeText = hasGrade ? gradeValue.toFixed(2) : "—";

        const row = document.createElement("tr");
        row.innerHTML = `
          <td>${sub.subject_name || "—"}</td>
          <td class="grade-col">${gradeText}</td>
          <td class="status-col">
            ${hasGrade ? `<span class="grade-badge ${status.className}">${status.text}</span>` : "—"}
          </td>
        `;
        subjectsTbody.appendChild(row);
      });

      // 4. GPA/Average Grade
      if (subjectCount > 0) {
        const average = totalGrades / subjectCount;
        averageGrade.textContent = average.toFixed(2);
      } else {
        averageGrade.textContent = "—";
      }

      // 5. Toggle views
      loadingState.hidden = true;
      resultsState.hidden = false;
    } else {
      const serverMessage = data.message || data.error || "Unknown server error.";
      showError(serverMessage);
    }
  } catch (err) {
    console.error("Error fetching results:", err);
    showError("Could not connect to the server. Please check your internet connection.");
  }
}

/**
 * Display the error state banner.
 * @param {string} message
 */
function showError(message) {
  errorMsgText.textContent = message;
  loadingState.hidden = true;
  errorState.hidden = false;
}

// ── Event Handlers ───────────────────────────────────────────
logoutBtn.addEventListener("click", () => {
  handleSessionExpiry();
});

// Run load on start
loadResults();
