import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="color-picker"
export default class extends Controller {
  static targets = ["picker", "input"]

  connect() {
    // Sync picker with input on load if input has a value
    if (this.inputTarget.value) {
      this.pickerTarget.value = this.inputTarget.value
    }
  }

  // When color picker changes, update the text input
  updateInput(event) {
    this.inputTarget.value = event.target.value.toUpperCase()
  }

  // When text input changes, update the color picker
  updatePicker(event) {
    const hexValue = event.target.value
    // Only update if it's a valid hex color
    if (/^#[0-9A-F]{6}$/i.test(hexValue)) {
      this.pickerTarget.value = hexValue
    }
  }
}
