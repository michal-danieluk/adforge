import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-form"
export default class extends Controller {
  static targets = ["container", "template"]

  add(event) {
    event.preventDefault()

    // Get the template and create a new unique ID
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())

    // Insert the new fields before the "Add Color" button
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest('.nested-fields')

    // Check if this is a persisted record (has an ID field)
    const idField = wrapper.querySelector('input[name*="[id]"]')

    if (idField && idField.value) {
      // Persisted record - mark for deletion and hide
      const destroyField = wrapper.querySelector('input[name*="_destroy"]')
      if (destroyField) {
        destroyField.value = '1'
      }
      // Use visibility instead of display to keep it in form submission
      wrapper.style.visibility = 'hidden'
      wrapper.style.position = 'absolute'
      wrapper.style.height = '0'
      wrapper.style.overflow = 'hidden'
    } else {
      // New record - just remove it from DOM
      wrapper.remove()
    }
  }
}
