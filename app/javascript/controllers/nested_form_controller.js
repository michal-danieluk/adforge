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

    // If the record is persisted, mark it for deletion
    const destroyField = wrapper.querySelector('input[name*="_destroy"]')
    if (destroyField) {
      destroyField.value = '1'
    }

    // Hide the wrapper instead of removing it (so Rails can process the _destroy)
    wrapper.style.display = 'none'
  }
}
