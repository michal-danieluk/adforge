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
    click_on "New campaign"

    fill_in "Brand", with: @campaign.brand_id
    fill_in "Description", with: @campaign.description
    fill_in "Product name", with: @campaign.product_name
    fill_in "Target audience", with: @campaign.target_audience
    click_on "Create Campaign"

    assert_text "Campaign was successfully created"
    click_on "Back"
  end

  test "should update Campaign" do
    visit campaign_url(@campaign)
    click_on "Edit this campaign", match: :first

    fill_in "Brand", with: @campaign.brand_id
    fill_in "Description", with: @campaign.description
    fill_in "Product name", with: @campaign.product_name
    fill_in "Target audience", with: @campaign.target_audience
    click_on "Update Campaign"

    assert_text "Campaign was successfully updated"
    click_on "Back"
  end

  test "should destroy Campaign" do
    visit campaign_url(@campaign)
    accept_confirm { click_on "Destroy this campaign", match: :first }

    assert_text "Campaign was successfully destroyed"
  end
end
