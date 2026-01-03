(function () {
  const AUTH_KEY = "reboot.auth.user";

  function getAuthUser() {
    try {
      const raw = localStorage.getItem(AUTH_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  function saveAuthUser(user) {
    localStorage.setItem(AUTH_KEY, JSON.stringify(user));
  }

  function clearAuthUser() {
    localStorage.removeItem(AUTH_KEY);
  }

  function requireAuth() {
    if (!getAuthUser()) {
      window.location.replace("./signin.html");
    }
  }

  function redirectIfAuthed() {
    if (getAuthUser()) {
      window.location.replace("./projects.html");
    }
  }

  function initSignin() {
    redirectIfAuthed();
    const form = document.getElementById("signin-form");
    if (!form) return;
    const submitBtn = form.querySelector('button[type="submit"]');
    const emailInput = document.getElementById("email");
    const nameInput = document.getElementById("name");

    function isValidEmail(value) {
      return /\S+@\S+\.\S+/.test(value);
    }

    function updateSubmitState() {
      const email = emailInput.value.trim();
      const name = nameInput.value.trim();
      const canSubmit = isValidEmail(email) && name.length > 0;
      if (submitBtn) submitBtn.disabled = !canSubmit;
    }

    // initialize and react to changes
    updateSubmitState();
    emailInput.addEventListener("input", updateSubmitState);
    nameInput.addEventListener("input", updateSubmitState);

    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const email = emailInput.value.trim();
      const name = nameInput.value.trim();
      if (!email || !name) return;
      if (submitBtn) {
        setButtonLoading(submitBtn, true, "Signing in…");
      }
      saveAuthUser({ email, name, createdAt: Date.now() });
      window.location.replace("./projects.html");
    });
  }

  function initProjects() {
    requireAuth();
    const signoutBtn = document.getElementById("signout-btn");
    if (signoutBtn) {
      signoutBtn.addEventListener("click", () => {
        clearAuthUser();
        window.location.replace("./signin.html");
      });
    }

    // Selection: left list controls right detail panel
    const projectRows = Array.from(document.querySelectorAll(".projects-list .project-row"));
    let selectedRow = null;

    function selectProject(row) {
      if (!row) return;
      if (selectedRow) selectedRow.classList.remove("project-row--selected");
      selectedRow = row;
      selectedRow.classList.add("project-row--selected");

      const title = row.querySelector(".project-row__title")?.textContent.trim() || "Untitled";
      const status = (row.dataset.status || row.querySelector(".pill--status")?.textContent || "").trim().toLowerCase();
      const description = row.dataset.description || null;

      const detailTitleEl = document.querySelector(".project-detail__title");
      if (detailTitleEl) detailTitleEl.textContent = title;

      // Update description if provided via data-description
      const firstDetailRowValue = document.querySelector(".detail-row .detail-value");
      if (firstDetailRowValue && description) {
        firstDetailRowValue.textContent = description;
      }

      // Reflect 3-state status in the detail panel
      const statusContainer = document.getElementById("project-status");
      if (statusContainer) {
        const dots = statusContainer.querySelectorAll(".dot");
        dots.forEach((d) => d.classList.remove("dot--filled"));
        // order: 0 pending, 1 in-review, 2 approved
        if (status === "pending" && dots[0]) dots[0].classList.add("dot--filled");
        if ((status === "in review" || status === "in-review") && dots[1]) dots[1].classList.add("dot--filled");
        if (status === "approved" && dots[2]) dots[2].classList.add("dot--filled");
      }

      // Gate the Request review button based on status
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

    // Attach selection handlers and default to first
    projectRows.forEach((row) => {
      row.addEventListener("click", () => selectProject(row));
    });
    if (projectRows.length > 0) selectProject(projectRows[0]);

    // Project detail action buttons
    const actionButtons = document.querySelectorAll(".project-detail__actions .btn");
    const writeBtn = actionButtons[0];
    const editBtn = actionButtons[1];
    if (writeBtn) {
      writeBtn.addEventListener("click", () => {
        setButtonLoading(writeBtn, true, "Opening…");
        setTimeout(() => {
          setButtonLoading(writeBtn, false);
          alert("Journal composer coming soon!");
        }, 500);
      });
    }
    if (editBtn) {
      editBtn.addEventListener("click", () => {
        setButtonLoading(editBtn, true, "Editing…");
        setTimeout(() => {
          setButtonLoading(editBtn, false);
          alert("Edit mode coming soon!");
        }, 500);
      });
    }

    // Request review button
    const requestBtn = document.querySelector(".btn.btn--accent.btn--block");
    if (requestBtn) {
      requestBtn.addEventListener("click", () => {
        if (requestBtn.disabled) return;
        setButtonLoading(requestBtn, true, "Requesting…");
        setTimeout(() => {
          setButtonLoading(requestBtn, false);
          // Flip selected project's state to in-review
          if (selectedRow) {
            selectedRow.dataset.status = "in-review";
            const pill = selectedRow.querySelector(".pill--status");
            if (pill) pill.textContent = "in review";
          }
          // Update right panel UI
          requestBtn.textContent = "Requested";
          requestBtn.disabled = true;
          updateStatusToInReview();
        }, 700);
      });
    }

    function updateStatusToInReview() {
      const statusContainer = document.getElementById("project-status");
      if (!statusContainer) return;
      const dots = statusContainer.querySelectorAll(".dot");
      dots.forEach((d) => d.classList.remove("dot--filled"));
      if (dots[1]) dots[1].classList.add("dot--filled");
    }
  }

  // Public API for simple redirect in index.html
  window.RebootAuth = {
    getAuthUser,
    saveAuthUser,
    clearAuthUser,
  };

  document.addEventListener("DOMContentLoaded", () => {
    const page = document.body.getAttribute("data-page");
    if (page === "signin") initSignin();
    if (page === "projects") initProjects();
  });

  function setButtonLoading(buttonEl, isLoading, loadingText) {
    if (!buttonEl) return;
    if (isLoading) {
      buttonEl.setAttribute("aria-busy", "true");
      buttonEl.dataset.originalText = buttonEl.textContent || "";
      if (loadingText) buttonEl.textContent = loadingText;
      buttonEl.disabled = true;
    } else {
      buttonEl.removeAttribute("aria-busy");
      if (buttonEl.dataset.originalText) {
        buttonEl.textContent = buttonEl.dataset.originalText;
        delete buttonEl.dataset.originalText;
      }
    }
  }
})();


