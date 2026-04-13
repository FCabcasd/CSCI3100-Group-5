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

  def analytics
  end
end
