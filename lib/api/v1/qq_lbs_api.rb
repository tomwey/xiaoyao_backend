require 'rest-client'
module API
  module V1
    class QQLbsAPI < Grape::API
      resource :qq, desc: 'QQ LBS WebService接口封装' do
        params do
          requires :city, type: String, desc: '城市中文名称'
          requires :keyword, type: String, desc: '关键字'
        end
        get :suggestion do
          json_params = {
            region: params[:city],
            keyword: params[:keyword],
            key: 'EJZBZ-VCM34-QJ4UU-XUWNV-3G2HJ-DWBNJ'
          }
          # puts json_params
          url = "http://apis.map.qq.com/ws/place/v1/suggestion/"
          # puts url
          result = RestClient.get url, {params: json_params}
          # puts result
          json = JSON.parse(result)
          if json['status'].to_i == 0
            json['code'] = 0
            json
          else
            { code: -1, message: '查询失败' }
          end
          
        end # end get suggestion
        
        desc '解析用户位置坐标到一个地址'
        params do
          requires :lat, type: String, desc: '纬度'
          requires :lng, type: String, desc: '经度'
        end
        get :geocode do
          json_params = {
            location: "#{params[:lat]},#{params[:lng]}",
            key: 'EJZBZ-VCM34-QJ4UU-XUWNV-3G2HJ-DWBNJ',
            get_poi: 1
          }
          
          url = "http://apis.map.qq.com/ws/geocoder/v1/"
          
          result = RestClient.get url, {params: json_params}
          # puts result
          json = JSON.parse(result)
          if json['status'].to_i == 0
            info = json['result']
            
            address_2 = ''
            if info['address_reference']
              if info['address_reference']['landmark_l2']
                address_2 = info['address_reference']['landmark_l2']['title']
              elsif info['address_reference']['landmark_l1']
                address_1 = info['address_reference']['landmark_l1']['title']
              end
            end
            
            address = {
              lat: info['location']['lat'],
              lnt: info['location']['lng'],
              country: info['address_component']['nation'],
              province: info['address_component']['province'],
              city: info['address_component']['city'],
              district: info['address_component']['district'],
              address_1: info['formatted_addresses']['recommend'],
              address_2: address_2
            }
            
            { code: 0, message: 'ok', data: address }
          else
            { code: -1, message: '位置解析失败' }
          end
        end # end get geocode
        
      end # end resource
    end # end class 
  end # end v1 
end # end module API