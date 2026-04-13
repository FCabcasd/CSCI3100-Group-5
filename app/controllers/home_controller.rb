class HomeController < ApplicationController
  def index
  end

  def menu
    if request.referer.nil? || URI(request.referer).host != request.host
      redirect_to root_path, alert: "Please use the links on the page to navigate."
    end
  end

  def admin_users
  end

  def catalog
  end

  def equipment
  end

  def user_bookings
  end

  def venue_bookings
  end

  def admin_panel
  end

  def analytics
  end

  def profile
  end
end
