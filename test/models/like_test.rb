require "test_helper"

class LikeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address:     "like-user-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @other = User.create!(
      email_address:     "like-other-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @forum  = Forum.create!(name: "Like Test Forum", visibility: :open, position: 99)
    @thread = ForumThread.new(title: "Thread", forum: @forum, author: @user)
    @thread.body = "Thread body."
    @thread.save!
    @reply = ForumReply.new(forum_thread: @thread, author: @other)
    @reply.body = "A reply."
    @reply.save!
  end

  test "creates a like successfully" do
    like = Like.create!(user: @user, likeable: @reply)
    assert like.persisted?
  end

  test "enforces one like per user per likeable" do
    Like.create!(user: @user, likeable: @reply)
    duplicate = Like.new(user: @user, likeable: @reply)
    assert_not duplicate.valid?
    assert_match "has already liked this", duplicate.errors[:user_id].join
  end

  test "different users can like the same reply" do
    Like.create!(user: @user,  likeable: @reply)
    Like.create!(user: @other, likeable: @reply)
    assert_equal 2, @reply.likes.count
  end

  test "creating a like increments likes_count on the reply" do
    assert_difference -> { @reply.reload.likes_count }, +1 do
      Like.create!(user: @user, likeable: @reply)
    end
  end

  test "destroying a like decrements likes_count on the reply" do
    like = Like.create!(user: @user, likeable: @reply)
    assert_difference -> { @reply.reload.likes_count }, -1 do
      like.destroy
    end
  end

  test "like? and unlike! helpers toggle state" do
    assert_not @reply.liked_by?(@user)
    @reply.like!(@user)
    assert @reply.liked_by?(@user)
    @reply.unlike!(@user)
    assert_not @reply.liked_by?(@user)
  end

  test "liked_by? returns false for nil user" do
    assert_not @reply.liked_by?(nil)
  end

  test "like! is idempotent — second call does not raise" do
    @reply.like!(@user)
    assert_nothing_raised { @reply.like!(@user) }
    assert_equal 1, @reply.likes.where(user: @user).count
  end
end
