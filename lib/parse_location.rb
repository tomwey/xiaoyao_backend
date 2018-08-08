require 'rest-client'
class ParseLocation
  def self.start(address)
    return nil if address.blank?
    result = RestClient.get 'http://apis.map.qq.com/ws/geocoder/v1/', 
      {:params => {:address => address, :key => SiteConfig.qq_lbs_api_key}}
    json = JSON.parse(result)
    puts result
    if json['result'].blank?
      return nil
    end
    
    loc = json['result']['location']
    if loc.blank?
      return nil
    end
    
    lng = loc['lng']
    lat = loc['lat']
    
    return "POINT(#{lng} #{lat})"
    
  end
  
  def self.geocode(lat, lng)
    result = RestClient.get 'http://apis.map.qq.com/ws/geocoder/v1/', 
      {:params => {:location => "#{lat},#{lng}", :key => SiteConfig.qq_lbs_api_key}}
    json = JSON.parse(result)
    # puts result
    if json['result'].blank?
      return nil
    end
    
    addr = json['result']['address']
    
    addr2 = nil
    if json['result']['address_reference']
      if json['result']['address_reference']['landmark_l2'] && json['result']['address_reference']['landmark_l2']['title']
        addr2 = json['result']['address_reference']['landmark_l2']['title']
      elsif json['result']['address_reference']['landmark_l1'] && json['result']['address_reference']['landmark_l1']['title']
        addr2 = json['result']['address_reference']['landmark_l1']['title']
      else
        addr2 = ''
      end
    else
      addr2 = ''
    end
    
    return [addr, addr2]
  end
  
  def self.calc_distance(loc1, loc2)
    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    rm * c # Delta in meters
  end
  
end