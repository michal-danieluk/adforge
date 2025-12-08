import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="color-picker"
export default class extends Controller {
  static targets = ["picker", "input"]

  connect() {
    // Sync picker with input on load if input has a value
    if (this.inputTarget.value) {
      this.pickerTarget.value = this.inputTarget.value.toLowerCase()
    } else {
      // If no value, set default from picker
      this.inputTarget.value = this.pickerTarget.value.toUpperCase()
    }
  }

  // When color picker changes, update the text input
  updateInput(event) {
    this.inputTarget.value = event.target.value.toUpperCase()
    // Trigger change event so Rails knows the field changed
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  // When text input changes, update the color picker
  updatePicker(event) {
    let hexValue = event.target.value.trim()

    // Auto-add # if user forgot it
    if (hexValue && !hexValue.startsWith('#')) {
      hexValue = '#' + hexValue
      this.inputTarget.value = hexValue.toUpperCase()
    }

    // Convert to uppercase
    if (hexValue) {
      this.inputTarget.value = hexValue.toUpperCase()
    }

    // Only update picker if it's a valid hex color
    if (/^#[0-9A-F]{6}$/i.test(hexValue)) {
      this.pickerTarget.value = hexValue.toLowerCase()
    }
  }
}
