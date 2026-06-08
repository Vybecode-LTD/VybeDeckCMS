module Admin
  # Provides a server-side embed URL preview for the admin embed picker.
  # GET /admin/embeds/preview?url=URL — returns rendered _embed partial or 422.
  class EmbedsController < Admin::ApplicationController
    def preview
      url   = params[:url].to_s.strip
      embed = EmbedParser.parse(url)

      if embed
        render partial: "shared/embed", locals: { embed: embed }
      else
        render plain: "Unrecognised embed URL.", status: :unprocessable_entity
      end
    end
  end
end
