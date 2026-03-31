require "test_helper"
require "webmock/minitest"

class BillingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
    WebMock.enable!
    WebMock.disable_net_connect!
  end

  teardown do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  # Stub the Mainlayer API verify_access endpoint
  def stub_mainlayer_access(resource_id:, user_id:, authorized:, plan: "free")
    stub_request(:post, "https://api.mainlayer.fr/v1/resources/#{resource_id}/verify")
      .with(body: hash_including("userId" => user_id))
      .to_return(
        status: 200,
        body: { authorized: authorized, metadata: { plan: plan } }.to_json,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_mainlayer_checkout(resource_id:)
    stub_request(:post, "https://api.mainlayer.fr/v1/checkout")
      .to_return(
        status: 200,
        body: { url: "https://checkout.mainlayer.fr/session_test_abc" }.to_json,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_mainlayer_portal
    stub_request(:post, "https://api.mainlayer.fr/v1/billing/portal")
      .to_return(
        status: 200,
        body: { url: "https://portal.mainlayer.fr/portal_test_xyz" }.to_json,
        headers: { "Content-Type" => "application/json" },
      )
  end

  test "GET /billing renders billing page" do
    stub_mainlayer_access(resource_id: "plan_enterprise", user_id: @user.id.to_s, authorized: false)
    stub_mainlayer_access(resource_id: "plan_pro",        user_id: @user.id.to_s, authorized: false)

    get billing_path
    assert_response :success
    assert_select "h1", text: /Billing/i
  end

  test "POST /billing/subscribe redirects to checkout for pro plan" do
    stub_mainlayer_checkout(resource_id: "plan_pro")

    post billing_subscribe_path, params: { plan: "pro" }
    assert_response :redirect
    assert_redirected_to "https://checkout.mainlayer.fr/session_test_abc"
  end

  test "POST /billing/subscribe rejects invalid plan" do
    post billing_subscribe_path, params: { plan: "invalid_plan" }
    assert_redirected_to billing_path
    assert_equal "Invalid plan.", flash[:alert]
  end

  test "POST /billing/portal redirects to billing portal" do
    stub_mainlayer_portal

    post billing_portal_path
    assert_response :redirect
    assert_redirected_to "https://portal.mainlayer.fr/portal_test_xyz"
  end

  test "GET /billing requires authentication" do
    sign_out @user
    get billing_path
    assert_redirected_to new_user_session_path
  end
end
