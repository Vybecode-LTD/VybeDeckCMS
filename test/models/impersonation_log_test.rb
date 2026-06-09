require "test_helper"

class ImpersonationLogTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(
      email_address: "log-admin-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :admin
    )
    @member = User.create!(
      email_address: "log-member-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :member
    )
  end

  test "active? returns true when ended_at is nil" do
    log = ImpersonationLog.create!(
      impersonator: @admin,
      impersonated: @member,
      started_at:   Time.current
    )
    assert log.active?
  end

  test "active? returns false when ended_at is set" do
    log = ImpersonationLog.create!(
      impersonator: @admin,
      impersonated: @member,
      started_at:   1.hour.ago,
      ended_at:     Time.current
    )
    assert_not log.active?
  end

  test "end! stamps ended_at" do
    log = ImpersonationLog.create!(
      impersonator: @admin,
      impersonated: @member,
      started_at:   Time.current
    )
    assert log.active?
    log.end!
    assert_not log.reload.active?
    assert_not_nil log.ended_at
  end

  test "active scope returns only open entries" do
    open_log = ImpersonationLog.create!(
      impersonator: @admin, impersonated: @member, started_at: 30.minutes.ago
    )
    closed_log = ImpersonationLog.create!(
      impersonator: @admin, impersonated: @member,
      started_at: 2.hours.ago, ended_at: 1.hour.ago
    )

    active_ids = ImpersonationLog.active.pluck(:id)
    assert_includes     active_ids, open_log.id
    assert_not_includes active_ids, closed_log.id
  end
end
