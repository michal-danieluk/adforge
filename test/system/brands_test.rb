require "application_system_test_case"

class BrandsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit brands_url
    assert_selector "h1", text: "Brands"
  end

  test "should create brand with multiple colors and logo" do
    visit brands_url
    click_on "New brand"

    # Fill in brand details
    fill_in "Name", with: "Test Brand"
    select "professional", from: "Tone of voice"

    # Upload logo
    attach_file "Logo (PNG, JPEG, or SVG, max 5MB)", Rails.root.join("test/fixtures/files/sample_logo.png")

    # Fill in first color (already present from controller)
    first_hex_field = all("input[type='text'][placeholder='#FF5733']").first
    first_hex_field.fill_in with: "#FF5733"

    # Mark first color as primary
    first("input[type='checkbox'][id*='primary']").check

    # Add second color
    click_on "+ Add Color"
    sleep 0.1 # Brief pause for JS to execute

    # Fill in second color
    hex_fields = all("input[type='text'][placeholder='#FF5733']")
    hex_fields[1].fill_in with: "#33FF57"

    # Add third color
    click_on "+ Add Color"
    sleep 0.1

    # Fill in third color
    hex_fields = all("input[type='text'][placeholder='#FF5733']")
    hex_fields[2].fill_in with: "#3357FF"

    # Submit form
    click_on "Create Brand"

    # Verify success
    assert_text "Brand was successfully created"
    assert_text "Test Brand"
    assert_text "professional"

    # Verify colors are displayed
    assert_text "#FF5733"
    assert_text "#33FF57"
    assert_text "#3357FF"

    # Verify primary badge is shown
    assert_selector "span", text: "PRIMARY"

    # Verify logo is displayed
    assert_selector "img[src*='sample_logo']"
  end

  test "should show validation error when no colors provided" do
    visit new_brand_url

    fill_in "Name", with: "Test Brand"
    select "casual", from: "Tone of voice"

    # Remove the default color
    click_on "Remove"

    click_on "Create Brand"

    # Should show validation error
    assert_text "must have at least one brand color"
  end

  test "should show validation error when no primary color selected" do
    visit new_brand_url

    fill_in "Name", with: "Test Brand"
    select "friendly", from: "Tone of voice"

    # Fill in a color but don't mark as primary
    first("input[type='text'][placeholder='#FF5733']").fill_in with: "#FF5733"

    click_on "Create Brand"

    # Should show validation error
    assert_text "must have exactly one primary color"
  end

  test "should update brand" do
    # First create a brand
    brand = Brand.create!(
      name: "Original Brand",
      tone_of_voice: "professional",
      brand_colors_attributes: [
        { hex_value: "#FF0000", primary: true }
      ]
    )

    visit brand_url(brand)
    click_on "Edit this brand"

    fill_in "Name", with: "Updated Brand"
    select "casual", from: "Tone of voice"

    click_on "Update Brand"

    assert_text "Brand was successfully updated"
    assert_text "Updated Brand"
    assert_text "casual"
  end

  test "should destroy brand" do
    brand = Brand.create!(
      name: "Brand to Delete",
      tone_of_voice: "professional",
      brand_colors_attributes: [
        { hex_value: "#FF0000", primary: true }
      ]
    )

    visit brand_url(brand)
    accept_confirm { click_on "Destroy this brand" }

    assert_text "Brand was successfully destroyed"
  end
end
