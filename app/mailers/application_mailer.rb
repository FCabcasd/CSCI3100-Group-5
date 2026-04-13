class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", "CUHK Booking <onboarding@resend.dev>")
  layout "mailer"

  rescue_from StandardError do |exception|
    Rails.logger.error "Email delivery failed: #{exception.message}"
  end
end
