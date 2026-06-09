module Admin
  class SeriesController < Admin::ApplicationController
    # Standard Administrate CRUD is inherited from Admin::ApplicationController.
    # SeriesPolicy handles per-action authorization via Administrate::Punditize.
  end
end
