import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["gross", "vat", "net"];

    calculateNet() {
        const gross = parseFloat(this.grossTarget.value) || 0;
        const vat = parseFloat(this.vatTarget.value) || 0;

        const net = gross / (1 + vat / 100);

        this.netTarget.value = net.toFixed(2);
    }
}
