// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Full-screen loading screen shown during Turbo page navigations.
// The overlay lives in app/views/layouts/_loading_screen.html.erb and is
// marked with data-turbo-permanent so it survives Turbo body swaps.
//
// - Show it when a visit (page navigation) begins.
// - Hide it just before the new page renders, or on load / error as a fallback.
const loader = () => document.getElementById("loading-screen")

const showLoader = () => loader()?.classList.add("is-loading")
const hideLoader = () => loader()?.classList.remove("is-loading")

document.addEventListener("turbo:before-visit", showLoader)
document.addEventListener("turbo:before-render", hideLoader)
document.addEventListener("turbo:load", hideLoader)
document.addEventListener("turbo:fetch-request-error", hideLoader)
