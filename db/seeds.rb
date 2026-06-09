require "stringio"
require "zlib"

def png_chunk(type, data)
  [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N")
end

def sample_png(filename, colors)
  width = 960
  height = 540
  palette = colors.map { |hex| hex.delete_prefix("#").scan(/../).map { |part| part.to_i(16) } }
  rows = height.times.map do |y|
    stripe = palette[(y / 90) % palette.length]
    "\x00".b + stripe.pack("C*") * width
  end.join

  png = "\x89PNG\r\n\x1A\n".b
  png << png_chunk("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("NNCCCCC"))
  png << png_chunk("IDAT", Zlib::Deflate.deflate(rows))
  png << png_chunk("IEND", "")

  {
    io: StringIO.new(png),
    filename: filename,
    content_type: "image/png"
  }
end

def attach_once(record, attachment_name, attachable)
  attachment = record.public_send(attachment_name)
  attachment.attach(attachable) unless attachment.attached?
end

admin = User.find_or_initialize_by(email_address: "admin@vybedeck.test")
admin.assign_attributes(role: :admin, password: "password", display_name: "VybeDeck Admin")
# Seed admin is pre-verified; preserve existing verified_at if already set.
admin.email_verified_at ||= Time.current
admin.save!

# Site settings defaults (idempotent)
SiteSetting.find_or_create_by!(key: "invite_only") do |s|
  s.value       = "false"
  s.value_type  = "boolean"
  s.description = "When enabled, new user registration is disabled. Existing users can still sign in."
end

announcements = Category.find_or_create_by!(name: "Announcements")
field_notes = Category.find_or_create_by!(name: "Field Notes")

home = Page.find_or_initialize_by(slug: "home")
home.assign_attributes(
  title: "VybeDeck CMS",
  slug: "home",
  status: :published,
  published_at: 2.days.ago,
  show_in_nav: true,
  position: 1,
  meta_title: "VybeDeck CMS",
  meta_description: "A focused Rails 8 publishing system for public pages, editorial posts, and media-backed content."
)
home.body = <<~HTML
  <h1>Publish with a quiet, durable workflow.</h1>
  <p>VybeDeck CMS keeps public pages and dated posts separate, gives editors a clear admin surface, and serves content through fast Hotwire views.</p>
  <p>The public site is server-rendered, media-aware, and ready for the next editorial pass.</p>
HTML
home.save!
attach_once(home, :hero_image, sample_png("vybedeck-cms-hero.png", [ "#0a0a0a", "#e8440a", "#1d6f73" ]))

about = Page.find_or_initialize_by(slug: "about")
about.assign_attributes(
  title: "About",
  slug: "about",
  status: :published,
  published_at: 1.day.ago,
  show_in_nav: true,
  position: 2,
  meta_title: "About VybeDeck CMS",
  meta_description: "Editorial structure, public publishing, and admin controls in one Rails application."
)
about.body = <<~HTML
  <p>VybeDeck CMS is an island Rails app with its own database, own authentication, and a public surface that follows the VybeCod.ing design language.</p>
  <p>Pages handle durable site structure. Posts handle dated editorial publishing.</p>
HTML
about.save!

launch = Post.find_or_initialize_by(slug: "launch-notes")
launch.assign_attributes(
  title: "Launch Notes",
  slug: "launch-notes",
  author: admin,
  status: :published,
  published_at: 18.hours.ago,
  excerpt: "The first editorial baseline for VybeDeck CMS is live.",
  meta_title: "Launch Notes",
  meta_description: "A short note introducing the public publishing baseline."
)
launch.body = <<~HTML
  <p>The first public layer is now connected to the content model, with Hotwire-ready templates and media attachments.</p>
  <p>Editors can keep drafting privately while published content remains available to anonymous readers.</p>
HTML
launch.categories = [ announcements ]
launch.save!
attach_once(launch, :cover_image, sample_png("launch-notes-cover.png", [ "#151515", "#e8440a", "#2d8f95" ]))

workflow = Post.find_or_initialize_by(slug: "editorial-workflow")
workflow.assign_attributes(
  title: "Editorial Workflow",
  slug: "editorial-workflow",
  author: admin,
  status: :published,
  published_at: 8.hours.ago,
  excerpt: "Pages, posts, topics, and media now have a public path through the CMS.",
  meta_title: "Editorial Workflow",
  meta_description: "How the public CMS surface presents structured editorial content."
)
workflow.body = <<~HTML
  <p>Posts can be tagged by topic, sorted by publication date, and reviewed independently from persistent pages.</p>
  <p>Attached images enqueue preprocessed variants so requests do not perform expensive transformations inline.</p>
HTML
workflow.categories = [ field_notes ]
workflow.save!
attach_once(workflow, :cover_image, sample_png("editorial-workflow-cover.png", [ "#102123", "#67d4cf", "#e8440a" ]))

draft = Post.find_or_initialize_by(slug: "private-draft")
draft.assign_attributes(
  title: "Private Draft",
  slug: "private-draft",
  author: admin,
  status: :draft,
  excerpt: "This draft demonstrates private editorial visibility."
)
draft.body = "<p>This content is hidden from anonymous readers until published.</p>"
draft.categories = [ field_notes ]
draft.save!
