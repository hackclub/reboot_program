// Reboot Frontend Application
(function () {
  const API_BASE = "/api/v1";

  // Get JWT from localStorage
  function getToken() {
    return localStorage.getItem("reboot.jwt");
  }

  // Save JWT to localStorage
  function saveToken(token) {
    localStorage.setItem("reboot.jwt", token);
  }

  // Clear JWT from localStorage
  function clearToken() {
    localStorage.removeItem("reboot.jwt");
  }

  // Get current user from localStorage
  function getUser() {
    try {
      const raw = localStorage.getItem("reboot.user");
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  // Save user to localStorage
  function saveUser(user) {
    localStorage.setItem("reboot.user", JSON.stringify(user));
  }

  // Clear user from localStorage
  function clearUser() {
    localStorage.removeItem("reboot.user");
  }

  // Check if user is authenticated
  function isAuthenticated() {
    return getToken() && getUser();
  }

  // Require authentication, redirect to signin if not
  function requireAuth() {
    if (!isAuthenticated()) {
      window.location.replace("/signin");
    }
  }

  // Redirect to projects if already authenticated
  function redirectIfAuthed() {
    if (isAuthenticated()) {
      window.location.replace("/projects");
    }
  }

  // API request helper
  async function apiRequest(path, options = {}) {
    const token = getToken();
    const headers = {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    };

    const response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || "Request failed");
    }

    return data;
  }

  // Sign out
  function signOut() {
    clearToken();
    clearUser();
    window.location.replace("/signin");
  }

  // Initialize signin page
  function initSignin() {
    redirectIfAuthed();

    // Handle OAuth callback token if present
    const urlParams = new URLSearchParams(window.location.search);
    const accessToken = urlParams.get("access_token");

    if (accessToken) {
      exchangeToken(accessToken);
    }
  }

  // Exchange HCA token for JWT
  async function exchangeToken(accessToken) {
    try {
      const data = await apiRequest("/auth/token", {
        method: "POST",
        body: JSON.stringify({ access_token: accessToken }),
      });

      saveToken(data.token);
      saveUser(data.user);

      // Clean URL and redirect
      window.history.replaceState({}, document.title, "/signin");
      window.location.replace("/projects");
    } catch (error) {
      console.error("Auth failed:", error);
      alert("Authentication failed. Please try again.");
    }
  }

  // Initialize projects page
  function initProjects() {
    requireAuth();

    const user = getUser();
    const userDisplay = document.getElementById("user-display");
    if (userDisplay && user) {
      userDisplay.textContent = user.slack_username || user.email || "User";
    }

    const signoutBtn = document.getElementById("signout-btn");
    if (signoutBtn) {
      signoutBtn.addEventListener("click", signOut);
    }

    // Project selection logic
    const projectRows = Array.from(
      document.querySelectorAll(".projects-list .project-row")
    );
    let selectedRow = null;

    function selectProject(row) {
      if (!row) return;
      if (selectedRow) selectedRow.classList.remove("project-row--selected");
      selectedRow = row;
      selectedRow.classList.add("project-row--selected");

      const title =
        row.querySelector(".project-row__title")?.textContent.trim() ||
        "Untitled";
      const status = (
        row.dataset.status ||
        row.querySelector(".pill--status")?.textContent ||
        ""
      )
        .trim()
        .toLowerCase();
      const description = row.dataset.description || null;

      const detailTitleEl = document.querySelector(".project-detail__title");
      if (detailTitleEl) detailTitleEl.textContent = title;

      const firstDetailRowValue = document.querySelector(
        ".detail-row .detail-value"
      );
      if (firstDetailRowValue && description) {
        firstDetailRowValue.textContent = description;
      }

      // Update status dots
      const statusContainer = document.getElementById("project-status");
      if (statusContainer) {
        const dots = statusContainer.querySelectorAll(".dot");
        dots.forEach((d) => d.classList.remove("dot--filled"));
        if (status === "pending" && dots[0]) dots[0].classList.add("dot--filled");
        if ((status === "in review" || status === "in-review") && dots[1])
          dots[1].classList.add("dot--filled");
        if (status === "approved" && dots[2]) dots[2].classList.add("dot--filled");
      }

      // Update request review button
      const requestBtn = document.querySelector(".btn.btn--accent.btn--block");
      if (requestBtn) {
        if (status === "pending") {
          requestBtn.disabled = false;
          requestBtn.textContent = "Request review";
        } else if (status === "in review" || status === "in-review") {
          requestBtn.disabled = true;
          requestBtn.textContent = "Requested";
        } else if (status === "approved") {
          requestBtn.disabled = true;
          requestBtn.textContent = "Approved";
        }
      }
    }

    projectRows.forEach((row) => {
      row.addEventListener("click", () => selectProject(row));
    });
    if (projectRows.length > 0) selectProject(projectRows[0]);
  }

  // Public API
  window.Reboot = {
    getToken,
    getUser,
    isAuthenticated,
    signOut,
    apiRequest,
  };

  // Page initialization
  document.addEventListener("DOMContentLoaded", () => {
    const page = document.body.dataset.page;
    if (page === "signin") initSignin();
    if (page === "projects") initProjects();
  });
})();
