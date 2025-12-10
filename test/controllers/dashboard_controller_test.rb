require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    login_as(@user)
  end

  test "should get dashboard" do
    get dashboard_url
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "should show brands count" do
    get dashboard_url
    assert_response :success
    assert_select ".text-3xl", text: /\d+/  # Check for count numbers
  end
end
