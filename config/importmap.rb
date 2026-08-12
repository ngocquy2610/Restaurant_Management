# Pin npm packages by running ./bin/importmap

pin "application"
# Konva is loaded from the jsDelivr CDN (browser ESM build). Vendoring via
# `./bin/importmap pin konva` is not used here because this environment has no
# npm registry access; the ESM build is loaded from the CDN at runtime.
pin "konva", to: "https://cdn.jsdelivr.net/npm/konva@10.3.0/konva.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
