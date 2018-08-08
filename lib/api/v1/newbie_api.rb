require 'rest-client'
module API
  module V1
    class NewbieAPI < Grape::API
      
      resource :projects, desc: '项目相关接口' do
        desc "获取某个项目的下载地址或下载二维码图片地址"
        get '/:id/download_urls' do
          project = Project.find_by(uniq_id: params[:id])
          if project.blank?
            return render_error(4004, '项目不存在')
          end
          
          { code: 0, message: 'ok', data: project.download_urls }
        end
      end # end resource
      
      resource :rom, desc: '数据相关接口' do
        desc "生成返回一条改机数据"
        post :create_packet do
          carrier_id = ROMUtils.create_carrier_id
          
          os_info = ROMUtils.create_os_info
          ver,sdk = os_info.split(',')
          
          screen,dpi = ROMUtils.create_screen_size
          
          device_info = DeviceInfo.order("RANDOM()").first
          
          @packet = Packet.create!(
            serial: ROMUtils.create_serial,
            android_id: ROMUtils.create_android_id,
            imei: ROMUtils.create_imei,
            sim_serial: ROMUtils.create_sim_serial,
            imsi: ROMUtils.create_imsi_for(carrier_id),
            sim_country: ROMUtils.create_sim_country,
            phone_number: ROMUtils.create_tel_number,
            carrier_id: carrier_id,
            carrier_name: ROMUtils.create_carrier_name_for(carrier_id),
            network_type: ROMUtils.create_network_type,
            phone_type: ROMUtils.create_phone_type,
            sim_state: ROMUtils.create_sim_state,
            mac_addr: ROMUtils.create_mac_addr,
            bluetooth_mac: ROMUtils.create_bluetooth_mac,
            wifi_mac: ROMUtils.create_wifi_mac,
            wifi_name: ROMUtils.create_wifi_name,
            os_version: ver,
            sdk_value: sdk,
            sdk_int: sdk,
            screen_size: screen,
            screen_dpi: dpi,
            device_info_id: device_info.try(:uniq_id)
          )
          
          render_json(@packet, API::V1::Entities::Packet)
        end # end create
        
        desc "上传刷单日志"
        params do
          
        end
        post :upload_log do
        end # end upload_log
        
        desc "获取一条某个项目的留存改机数据"
        params do
        end
        get :remain_packet do
        end # end remain_packet
        
      end # end resource
      
    end
  end
end