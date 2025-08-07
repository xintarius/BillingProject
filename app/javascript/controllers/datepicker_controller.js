import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
export default class extends Controller {
    connect() {
        const localeCode = this.data.get("locale") || "en"
        const locale = localeCode === "pl" ? flatpickr.l10ns.pl : undefined

        flatpickr(this.element, { wrap: true, locale })
    }
}

