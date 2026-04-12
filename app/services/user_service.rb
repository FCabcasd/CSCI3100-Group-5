class UserService
  def self.suspend_user(user:, hours: 24, reason: "Excessive late cancellations")
    user.update!(
      is_active: false,
      suspension_until: Time.current + hours.hours
    )

    BookingMailer.account_suspension(user, reason, hours).deliver_later
    user
  end

  def self.suspended?(user)
    user.suspension_until.present? && Time.current < user.suspension_until
  end
end
