// Reboot Frontend Application
// Minimal JS - most logic handled server-side via Rails forms
(function () {
  /**
   * Initializes signout button across all pages.
   * Creates a form to POST the signout request.
   */
  function initSignout() {
    const signoutBtn = document.getElementById("signout-btn");
    if (signoutBtn) {
      signoutBtn.addEventListener("click", (e) => {
        e.preventDefault();
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
  }

  /**
   * Initializes the create project modal.
   * Handles open/close via button clicks and keyboard.
   */
  function initProjectModal() {
    const modal = document.getElementById("create-project-modal");
    const createBtns = document.querySelectorAll("#create-project-btn");
    const closeBtn = modal?.querySelector(".modal__close");
    const backdrop = modal?.querySelector(".modal__backdrop");

    function openModal() {
      if (modal) {
        modal.classList.remove("modal--hidden");
        modal.querySelector("input")?.focus();
      }
    }

    function closeModal() {
      if (modal) {
        modal.classList.add("modal--hidden");
      }
    }

    createBtns.forEach((btn) => btn.addEventListener("click", openModal));
    closeBtn?.addEventListener("click", closeModal);
    backdrop?.addEventListener("click", closeModal);
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") closeModal();
    });
  }

  // Page initialization
  document.addEventListener("DOMContentLoaded", () => {
    initSignout();

    const page = document.body.dataset.page;
    if (page === "projects") {
      initProjectModal();
    }
  });
})();
