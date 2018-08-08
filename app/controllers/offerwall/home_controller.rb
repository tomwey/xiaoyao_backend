class Offerwall::HomeController < Offerwall::ApplicationController
  def callback
    # puts params
    # puts params
    # {"cid"=>"868271", "order"=>"YM170905io8dNAc0fb", "app"=>"8c6c635842931ac8", "ad"=>"红包天气", "pkg"=>"com.fenghe.android.weather", "user"=>"oMc3D0uyihKH_5IOtO2ZgQntM69M", "chn"=>"0", "points"=>"37", "price"=>"0", "time"=>"1504618295", "device"=>"863127032206531", "adid"=>"18672", "trade_type"=>"1", "sig"=>"214ac4bd", "controller"=>"offerwall/home", "action"=>"callback"}
    channel = OfferwallChannel.find_by(uniq_id: params[:cid])
    if channel.blank?
      render text: '403'
      return
    end
    
    params.delete(:controller)
    params.delete(:action)
    
    # 计算签名参数
    if Offerwall.send(channel.resp_sig_method.to_sym, channel.server_secret, params)
      if OfferwallChannelCallback.where(order: params[:order]).count > 0
        render text: channel.failure_return
      else
        # TODO: 写任务回调日志，然后告诉用户获得的收益
        profile = WechatProfile.find_by(openid: params[:user])
        if profile.present?
          OfferwallChannelCallback.create!(
                                           offerwall_channel_id: channel.id,
                                           user_id: profile.user.id,
                                           order: params[:order],
                                           ad_name: params[:ad],
                                           price: params[:price],
                                           points: params[:points],
                                           order_time: params[:time],
                                           callback_params: params
                                           )
        end
        render text: channel.success_return
      end
    else
      # 通知用户签名不正确
      puts '签名不正确'
      render text: channel.failure_return
    end
  end
  
end
