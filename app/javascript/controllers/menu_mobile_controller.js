import {Controller} from '@hotwired/stimulus'

export default class extends Controller {
    static targets = ['nav', 'overlay']

    toggle() {
        const isOpen = this.navTarget.classList.contains('hidden')
        isOpen ? this.open() : this.close()
    }

    open() {
        this.navTarget.classList.remove('hidden')
        this.navTarget.classList.add('active')

        this.overlayTarget.classList.remove('hidden')
        this.overlayTarget.classList.add('active')

        document.body.style.overflow = 'hidden' // zablokuj scroll
    }

    close() {
        this.navTarget.classList.add('hidden')
        this.navTarget.classList.remove('active')

        this.overlayTarget.classList.add('hidden')
        this.overlayTarget.classList.remove('active')

        document.body.style.overflow = ''
    }

    closeButton() {
        this.navTarget.classList.remove('active');
        this.navTarget.classList.add('hidden');

        this.overlayTarget.classList.remove('active');
        this.overlayTarget.classList.add('hidden');
    }
}
