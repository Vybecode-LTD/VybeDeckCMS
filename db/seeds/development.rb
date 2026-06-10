# Development / staging sample content.
# Loaded by db/seeds.rb in non-production environments only.

require "stringio"
require "zlib"

def png_chunk(type, data)
  [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N")
end

def sample_png(filename, colors)
  width  = 960
  height = 540
  palette = colors.map { |hex| hex.delete_prefix("#").scan(/../).map { |c| c.to_i(16) } }
  rows = height.times.map do |y|
    stripe = palette[(y / 90) % palette.length]
    "\x00".b + stripe.pack("C*") * width
  end.join

  png = "\x89PNG\r\n\x1A\n".b
  png << png_chunk("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("NNCCCCC"))
  png << png_chunk("IDAT", Zlib::Deflate.deflate(rows))
  png << png_chunk("IEND", "")
  { io: StringIO.new(png), filename: filename, content_type: "image/png" }
end

def attach_once(record, attachment_name, attachable)
  att = record.public_send(attachment_name)
  att.attach(attachable) unless att.attached?
end

admin         = User.find_by!(email_address: ENV.fetch("ADMIN_EMAIL", "admin@vybedeck.test"))
announcements = Category.find_by!(name: "Announcements")
field_notes   = Category.find_by!(name: "Field Notes")
home          = Page.find_by!(slug: "home")
about         = Page.find_by!(slug: "about")

attach_once(home,  :hero_image,  sample_png("vybedeck-cms-hero.png",  [ "#0a0a0a", "#e8440a", "#1d6f73" ]))
attach_once(about, :hero_image,  sample_png("vybedeck-about-hero.png", [ "#1d6f73", "#0a0a0a", "#e8440a" ]))

launch = Post.find_or_initialize_by(slug: "launch-notes")
launch.assign_attributes(
  title:        "Launch Notes",
  author:       admin,
  status:       :published,
  published_at: launch.published_at || 18.hours.ago,
  excerpt:      "The first editorial baseline for VybeDeck CMS is live.",
  meta_title:   "Launch Notes",
  meta_description: "A short note introducing the public publishing baseline."
)
launch.categories = [ announcements ]
launch.save!
launch.body = <<~HTML if launch.body.to_plain_text.blank?
  <p>The first public layer is now connected to the content model, with Hotwire-ready templates and media attachments.</p>
  <p>Editors can keep drafting privately while published content remains available to anonymous readers.</p>
HTML
attach_once(launch, :cover_image, sample_png("launch-notes-cover.png", [ "#151515", "#e8440a", "#2d8f95" ]))

workflow = Post.find_or_initialize_by(slug: "editorial-workflow")
workflow.assign_attributes(
  title:        "Editorial Workflow",
  author:       admin,
  status:       :published,
  published_at: workflow.published_at || 8.hours.ago,
  excerpt:      "Pages, posts, topics, and media now have a public path through the CMS.",
  meta_title:   "Editorial Workflow",
  meta_description: "How the public CMS surface presents structured editorial content."
)
workflow.categories = [ field_notes ]
workflow.save!
workflow.body = <<~HTML if workflow.body.to_plain_text.blank?
  <p>Posts can be tagged by topic, sorted by publication date, and reviewed independently from persistent pages.</p>
  <p>Attached images enqueue preprocessed variants so requests do not perform expensive transformations inline.</p>
HTML
attach_once(workflow, :cover_image, sample_png("editorial-workflow-cover.png", [ "#102123", "#67d4cf", "#e8440a" ]))

draft = Post.find_or_initialize_by(slug: "private-draft")
draft.assign_attributes(
  title:   "Private Draft",
  author:  admin,
  status:  :draft,
  excerpt: "This draft demonstrates private editorial visibility."
)
draft.body = "<p>This content is hidden from anonymous readers until published.</p>"
draft.categories = [ field_notes ]
draft.save!
