// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import { Turbo } from "@hotwired/turbo-rails";

// <turbo-stream action="toast" ...> broadcast by Notification after create.
Turbo.StreamActions.toast = function () {
  const id = this.getAttribute("notification-id");
  const url = this.getAttribute("url");
  const node = document.createElement("div");
  node.style.display = "contents";
  node.innerHTML = `
    <svg class="toast-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
    <div><strong class="toast-title"></strong><div class="toast-body"></div></div>`;
  node.querySelector(".toast-title").textContent = this.getAttribute("title");
  node.querySelector(".toast-body").textContent = this.getAttribute("body");

  Toastify({
    node,
    selector: "toast-root", // permanent element survives Turbo body swaps
    className: "toastify-toast",
    duration: 6000,
    gravity: "top",
    position: "right",
    offset: { x: 16, y: 112 }, // 112px = pt-28, clears the fixed header
    stopOnFocus: true,
    close: true,
    onClick: async () => {
      const token = document.querySelector("meta[name='csrf-token']")?.content;
      await fetch(`/notifications/${id}/mark_read`, {
        method: "PATCH",
        headers: { "X-CSRF-Token": token },
        credentials: "same-origin",
      }).catch(() => {});
      if (url) Turbo.visit(url);
    },
  }).showToast();
};

// Full-screen loading screen shown during Turbo page navigations.
// The overlay lives in app/views/layouts/_loading_screen.html.erb and is
// marked with data-turbo-permanent so it survives Turbo body swaps.
//
// - Show it when a visit (page navigation) begins.
// - Hide it just before the new page renders, or on load / error as a fallback.
const loader = () => document.getElementById("loading-screen");

const showLoader = () => loader()?.classList.add("is-loading");
const hideLoader = () => loader()?.classList.remove("is-loading");

document.addEventListener("turbo:before-visit", showLoader);
document.addEventListener("turbo:before-render", hideLoader);
document.addEventListener("turbo:load", hideLoader);
document.addEventListener("turbo:fetch-request-error", hideLoader);

const csrfToken = document.querySelector('[name="_csrf_token"]')?.value;
// hoặc đọc từ cookie
fetch("/login", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": csrfToken,
  },
  body: JSON.stringify({ email, password }),
});
