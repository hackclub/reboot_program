// Reboot Frontend Application
// Auth is handled server-side via sessions, JS only handles UI interactions
(function () {
  // Initialize projects page
  function initProjects() {
    const signoutBtn = document.getElementById("signout-btn");
    if (signoutBtn) {
      signoutBtn.addEventListener("click", (e) => {
        e.preventDefault();
        // Create a form to POST the signout (DELETE method)
        const form = document.createElement("form");
        form.method = "POST";
        form.action = "/signout";
        
        const methodInput = document.createElement("input");
        methodInput.type = "hidden";
        methodInput.name = "_method";
        methodInput.value = "delete";
        form.appendChild(methodInput);

        const csrfToken = document.querySelector('meta[name="csrf-token"]');
        if (csrfToken) {
          const tokenInput = document.createElement("input");
          tokenInput.type = "hidden";
          tokenInput.name = "authenticity_token";
          tokenInput.value = csrfToken.content;
          form.appendChild(tokenInput);
        }

        document.body.appendChild(form);
        form.submit();
      });
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
        row.dataset.status || ""
      ).trim().toLowerCase();
      const description = row.dataset.description || "No description";

      const detailTitleEl = document.querySelector(".project-detail__title");
      if (detailTitleEl) detailTitleEl.textContent = title;

      const firstDetailRowValue = document.querySelector(
        ".detail-row .detail-value"
      );
      if (firstDetailRowValue) {
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
        } else if (status === "rejected") {
          requestBtn.disabled = true;
          requestBtn.textContent = "Rejected";
        }
      }
    }

    projectRows.forEach((row) => {
      row.addEventListener("click", () => selectProject(row));
    });
    if (projectRows.length > 0) selectProject(projectRows[0]);
  }

  // Page initialization
  document.addEventListener("DOMContentLoaded", () => {
    const page = document.body.dataset.page;
    if (page === "projects") initProjects();
  });
})();
