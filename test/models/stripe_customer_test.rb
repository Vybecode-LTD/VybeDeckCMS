require "test_helper"

class StripeCustomerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "stripe-test-#{SecureRandom.hex(4)}@example.com",
      password:      "securepassword123",
      role:          :member
    )
  end

  test "valid with user and stripe_customer_id" do
    sc = StripeCustomer.new(user: @user, stripe_customer_id: "cus_test123")
    assert sc.valid?
  end

  test "invalid without stripe_customer_id" do
    sc = StripeCustomer.new(user: @user, stripe_customer_id: "")
    assert_not sc.valid?
    assert_includes sc.errors[:stripe_customer_id], "can't be blank"
  end

  test "stripe_customer_id must be unique" do
    StripeCustomer.create!(user: @user, stripe_customer_id: "cus_unique")
    user2 = User.create!(
      email_address: "stripe-test2-#{SecureRandom.hex(4)}@example.com",
      password:      "securepassword123",
      role:          :member
    )
    sc2 = StripeCustomer.new(user: user2, stripe_customer_id: "cus_unique")
    assert_not sc2.valid?
    assert_includes sc2.errors[:stripe_customer_id], "has already been taken"
  end

  test "belongs_to user" do
    sc = StripeCustomer.create!(user: @user, stripe_customer_id: "cus_abc")
    assert_equal @user, sc.user
  end
end
