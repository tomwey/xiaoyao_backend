require 'rest-client'
class GeocodeLocJob < ActiveJob::Base
  queue_as :scheduled_jobs

  def perform(loc_id)
    # @apartment = Apartment.find_by(id: id)
    # puts @apartment
    puts loc_id
    loc = WechatLocation.find_by(id: loc_id)
    # puts '开始执行...'
    # puts loc
    return if loc.blank?
    
    loc_arr = ParseLocation.geocode(loc.lat, loc.lng)
    
    # puts loc_arr
    
    if loc_arr
      loc.address = loc_arr[0]
      loc.formated_address = loc_arr[1]
    
      loc.save!
    end
  end
  
end
