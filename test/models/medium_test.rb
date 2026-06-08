require "test_helper"

class MediumTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "uploader-#{SecureRandom.hex(4)}@test.com",
      password: "password"
    )
  end

  # ── helpers ─────────────────────────────────────────────────────────────────

  def build_medium(overrides = {})
    Medium.new({ uploaded_by: @user, title: "Test image" }.merge(overrides))
  end

  def attach_png(medium, filename: "test.png")
    medium.file.attach(
      io:           StringIO.new("\x89PNG\r\n\x1a\n" + ("x" * 100)),
      filename:     filename,
      content_type: "image/png"
    )
  end

  # ── validations ─────────────────────────────────────────────────────────────

  test "valid with title, file, and uploaded_by" do
    m = build_medium
    attach_png(m)
    assert m.valid?, m.errors.full_messages.inspect
  end

  test "invalid without title" do
    m = build_medium(title: "")
    attach_png(m)
    assert_not m.valid?
    assert_includes m.errors[:title], "can't be blank"
  end

  test "invalid without file" do
    m = build_medium
    assert_not m.valid?
    assert_includes m.errors[:file], "must be attached"
  end

  test "invalid without uploaded_by" do
    m = Medium.new(title: "Test")
    attach_png(m)
    assert_not m.valid?
    assert m.errors[:uploaded_by].any?
  end

  test "rejects unsupported content type" do
    m = build_medium
    m.file.attach(io: StringIO.new("data"), filename: "bad.exe", content_type: "application/octet-stream")
    assert_not m.valid?
    assert m.errors[:file].any?
  end

  test "rejects file over 200 MB" do
    m = build_medium
    large = StringIO.new("x" * 10)
    m.file.attach(io: large, filename: "big.png", content_type: "image/png")
    # Directly set byte_size on the in-memory blob to simulate an oversized file
    m.file.blob.byte_size = 201.megabytes
    assert_not m.valid?
    assert m.errors[:file].any?
  end

  # ── enum ────────────────────────────────────────────────────────────────────

  test "defaults file_type to image" do
    m = build_medium
    assert_equal "image", m.file_type
  end

  test "all file_type values are defined" do
    assert_equal %w[image audio video document], Medium.file_types.keys
  end

  # ── .infer_type ─────────────────────────────────────────────────────────────

  test "infers image from image/jpeg" do
    assert_equal "image", Medium.infer_type("image/jpeg")
  end

  test "infers audio from audio/mpeg" do
    assert_equal "audio", Medium.infer_type("audio/mpeg")
  end

  test "infers video from video/mp4" do
    assert_equal "video", Medium.infer_type("video/mp4")
  end

  test "infers document from application/pdf" do
    assert_equal "document", Medium.infer_type("application/pdf")
  end

  test "returns nil for unknown type" do
    assert_nil Medium.infer_type("application/octet-stream")
  end

  # ── associations ─────────────────────────────────────────────────────────────

  test "owner is optional" do
    m = build_medium
    attach_png(m)
    assert m.valid?
    assert_nil m.owner
  end

  test "uploaded_by returns a User" do
    m = build_medium
    attach_png(m)
    assert_instance_of User, m.uploaded_by
  end
end
