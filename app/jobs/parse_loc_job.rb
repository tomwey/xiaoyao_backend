require 'rest-client'
class ParseLocJob < ActiveJob::Base
  queue_as :scheduled_jobs

  def perform(target)
    # @apartment = Apartment.find_by(id: id)
    # puts @apartment
    return if target.blank? or target.address.blank?
    
    result = RestClient.get 'http://apis.map.qq.com/ws/geocoder/v1/', 
      {:params => {:address => target.address, :key => SiteConfig.qq_lbs_api_key}}
    json = JSON.parse(result)
    loc = json['result']['location'] unless json['result'].blank?
    unless loc.blank?
      lng = loc['lng']
      lat = loc['lat']
      
      target.location = "POINT(#{lng} #{lat})"
      target.save
    end
  end
  
end
