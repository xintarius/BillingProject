# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/ujs", to: "rails-ujs.js"
pin "flatpickr", to: "flatpickr.js", preload: true
pin "flatpickr/l10n/pl", to: "flatpickr/dist/l10n/pl.js"

pin_all_from "app/javascript/controllers", under: "controllers"