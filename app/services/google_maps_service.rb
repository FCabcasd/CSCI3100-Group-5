require "cgi"

class GoogleMapsService
  def self.map_url_for(venue)
    if venue.latitude.present? && venue.longitude.present?
      "https://www.google.com/maps?q=#{venue.latitude},#{venue.longitude}"
    elsif venue.location.present?
      query = CGI.escape(venue.location)
      "https://www.google.com/maps/search/?api=1&query=#{query}"
    else
      nil
    end
  end
end
