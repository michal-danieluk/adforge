require "application_system_test_case"

class BrandsTest < ApplicationSystemTestCase
  setup do
    @brand = brands(:one)
  end

  test "visiting the index" do
    visit brands_url
    assert_selector "h1", text: "Brands"
  end

  test "should create brand" do
    visit brands_url
    click_on "New brand"

    fill_in "Name", with: @brand.name
    fill_in "Tone of voice", with: @brand.tone_of_voice
    click_on "Create Brand"

    assert_text "Brand was successfully created"
    click_on "Back"
  end

  test "should update Brand" do
    visit brand_url(@brand)
    click_on "Edit this brand", match: :first

    fill_in "Name", with: @brand.name
    fill_in "Tone of voice", with: @brand.tone_of_voice
    click_on "Update Brand"

    assert_text "Brand was successfully updated"
    click_on "Back"
  end

  test "should destroy Brand" do
    visit brand_url(@brand)
    accept_confirm { click_on "Destroy this brand", match: :first }

    assert_text "Brand was successfully destroyed"
  end
end
