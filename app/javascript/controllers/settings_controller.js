import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    connect() {
        this.boundClose = this.closeIfClickedOutside.bind(this)
        document.addEventListener("click", this.boundClose)
    }

    disconnect() {
        document.removeEventListener("click", this.boundClose)
    }

    toggle(event) {
        event.stopPropagation()
        this.menuTarget.classList.toggle("hidden")
    }

    closeIfClickedOutside(event) {
        if (!this.element.contains(event.target)) {
            this.menuTarget.classList.add("hidden")
        }
    }
}
