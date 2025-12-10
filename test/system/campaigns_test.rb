require "application_system_test_case"

class CampaignsTest < ApplicationSystemTestCase
  setup do
    @campaign = campaigns(:one)
  end

  test "visiting the index" do
    visit campaigns_url
    assert_selector "h1", text: "Campaigns"
  end

  test "should create campaign" do
    visit campaigns_url
    click_on "New Campaign"

    select "Test Brand One", from: "Brand"
    fill_in "Product name", with: "Test Product"
    fill_in "Target audience", with: "Test Audience"
    fill_in "Description", with: "Test description for the campaign"
    click_on "Create Campaign"

    assert_text "Campaign was successfully created"
    assert_text "Test Product"
    assert_selector "div[style*='#{brands(:one).primary_color}']"
  end

  test "should update Campaign" do
    visit campaign_url(@campaign)
    click_on "Edit Campaign", match: :first

    fill_in "Product name", with: "Updated Product Name"
    fill_in "Target audience", with: "Updated Target Audience"
    click_on "Update Campaign"

    assert_text "Campaign was successfully updated"
    assert_text "Updated Product Name"
  end

  test "should destroy Campaign" do
    visit campaign_url(@campaign)
    accept_confirm { click_on "Delete Campaign", match: :first }

    assert_text "Campaign was successfully destroyed"
  end

  test "brand show page links to new campaign with brand pre-filled" do
    brand = brands(:one)
    visit brand_url(brand)

    click_on "New Campaign"

    # Check that the brand is pre-selected in the dropdown
    assert_selector "select#campaign_brand_id option[selected][value='#{brand.id}']"
  end

  test "campaigns index shows brand color and information" do
    visit campaigns_url

    assert_selector "h1", text: "Campaigns"
    assert_text @campaign.product_name
    assert_text @campaign.brand.name
    assert_selector "div[style*='#{@campaign.brand_primary_color}']"
  end
end
