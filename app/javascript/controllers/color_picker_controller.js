import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="color-picker"
export default class extends Controller {
  static targets = ["picker", "input"]

  connect() {
    // Ensure values are synced on load
    this.syncFromInput()
  }

  // When color picker changes, update the text input
  updateInput(event) {
    this.inputTarget.value = event.target.value.toUpperCase()
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

    this.syncFromInput()
  }

  syncFromInput() {
    const hexValue = this.inputTarget.value
    // Only update picker if it's a valid hex color
    if (/^#[0-9A-F]{6}$/i.test(hexValue)) {
      this.pickerTarget.value = hexValue.toLowerCase()
    }
  }
}
