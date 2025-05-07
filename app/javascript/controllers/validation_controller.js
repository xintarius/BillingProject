import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = ['file', 'nip', 'name', 'invoice_nr', 'invoice_date', 'brutto', 'netto']

    connect() {
        this.constructor.targets.forEach(name => {
            const el = this[`${name}Target`]
            if (el) {
                el.addEventListener('input', () => this.validateField(el, name))
            }
        })
    }

    validate(event) {
        let valid = true

        this.constructor.targets.forEach(name => {
            const el = this[`${name}Target`]
            if (el && !this.validateField(el, name)) {
                valid = false
            }
        })

        if (!valid) event.preventDefault()
    }

    validateField(el, name) {
        let value = (el.type === 'file') ? el.files?.length : el.value;

        let isValid = true;

        // for number field
        if (el.type === 'number') {
            const numberValue = Number(value);
            if (isNaN(numberValue) || numberValue <= 0) {
                isValid = false;
                this.markError(el, "Wartość musi być liczbą większą niż 0.");
            } else {
                this.clearError(el);
            }
        }
        // for text field
        else if (name === 'nip') {
            const nipPattern = /^(PL)?\s?\d{3}[-\s]?\d{3}[-\s]?\d{2}[-\s]?\d{2}$/;
            isValid = nipPattern.test(value);
        } else if (name === 'file') {
            isValid = value > 0;
            if (!isValid) {
                this.markError(el, "Proszę wybrać plik");
            } else {
                this.clearError(el);
            }
        } else {
            isValid = String(value).trim() !== '';
        }

        if (name !== 'file' && name !== 'number') {
            isValid ? this.clearError(el) : this.markError(el);
        }

        return isValid;
    }


    markError(element, message = "Proszę uzupełnić to pole") {
        element.classList.add("field-error")

        if (element.nextElementSibling && element.nextElementSibling.classList.contains('error-message')) {
            element.nextElementSibling.remove()
        }

        const errorSpan = document.createElement('span')
        errorSpan.classList.add('error-message')
        errorSpan.innerText = message
        element.parentNode.insertBefore(errorSpan, element.nextSibling)
    }

    clearError(el) {
        el.classList.remove('field-error')
        if (el.nextElementSibling && el.nextElementSibling.classList.contains('error-message')) {
            el.nextElementSibling.remove()
        }
    }
}
