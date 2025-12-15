require "test_helper"

class BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = brands(:one)
    login_as(@brand.user)
  end

  test "should get index" do
    get brands_url
    assert_response :success
    assert_select "h1", "Marki"
  end

  test "should get new" do
    get new_brand_url
    assert_response :success
  end

  test "should show brand" do
    get brand_url(@brand)
    assert_response :success
    assert_select "p", text: /#{@brand.name}/
  end

  test "should get edit" do
    get edit_brand_url(@brand)
    assert_response :success
  end

  test "should update brand" do
    patch brand_url(@brand), params: { brand: { name: "Updated Name" } }
    assert_redirected_to brand_url(@brand)
    @brand.reload
    assert_equal "Updated Name", @brand.name
  end

  test "should destroy brand" do
    assert_difference("Brand.count", -1) do
      delete brand_url(@brand)
    end

    assert_redirected_to brands_url
  end
end
