// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// Full-screen loading screen shown during Turbo page navigations.
// The overlay lives in app/views/layouts/_loading_screen.html.erb and is
// marked with data-turbo-permanent so it survives Turbo body swaps.
//
// - Show it when a visit (page navigation) begins.
// - Hide it just before the new page renders, or on load / error as a fallback.
const loader = () => document.getElementById("loading-screen");

const showLoader = () => loader()?.classList.add("is-loading");
const hideLoader = () => loader()?.classList.remove("is-loading");

// Track the pending toast timer so rapid successive notifications only
// trigger one toast (for the latest notification) instead of stacking.
let pendingToastTimer = null;

document.addEventListener("turbo:before-visit", showLoader);
document.addEventListener("turbo:before-render", hideLoader);
document.addEventListener("turbo:load", hideLoader);
document.addEventListener("turbo:fetch-request-error", hideLoader);
document.addEventListener(
  "turbo:before-stream-render",
  (event) => {
    // Event phóng trên <turbo-stream> element, chứa detail.newStream
    const stream = event.detail?.newStream || event.target;
    if (!stream || stream.tagName !== "TURBO-STREAM") return;

    const action = stream.dataset.action; // "prepend"
    const target = stream.dataset.target; // "notifications-list"

    if (action === "prepend" && target === "notifications-list") {
      const titleMatch = stream.innerHTML.match(/<h2[^>]*>([^<]+)<\/h2>/);
      const bodyMatch = stream.innerHTML.match(
        /<p[^>]*class="mt-1\.5[^"]*">([^<]+)<\/p>/,
      );

      const text =
        (titleMatch ? titleMatch[1].trim() : "") +
        (bodyMatch ? " — " + bodyMatch[1].trim() : "");

      if (titleMatch || bodyMatch) {
        // Show a toast 5 seconds AFTER the new notification is prepended to
        // the notifications list. Clear any earlier pending toast so rapid
        // notifications only trigger one toast (for the latest one) instead
        // of stacking multiple toasts on top of each other.
        if (pendingToastTimer) {
          clearTimeout(pendingToastTimer);
        }
        pendingToastTimer = setTimeout(() => {
          Toastify({
            text,
            className: "toastify-toast",
            duration: 5000,
            gravity: "top",
            position: "right",
            stopOnFocus: true,
            close: true,
          }).showToast();
          pendingToastTimer = null;
        }, 5000);
      }
    }
  },
  true,
);
