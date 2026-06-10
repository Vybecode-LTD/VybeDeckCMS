class RobotsController < ApplicationController
  allow_unauthenticated_access

  def show
    @custom_rules = SiteSetting.get("robots_txt_custom")
    respond_to do |format|
      format.text { render layout: false }
    end
  end
end
