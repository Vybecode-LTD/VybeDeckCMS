class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("ACTION_MAILER_FROM", "noreply@vybedeck.test")
  layout "mailer"
end
