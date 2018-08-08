require 'rest-client'
module API
  module V1
    class Welcome < Grape::API
      get :ping do
        { pong: 'ok' }
      end
      get :server do
        {
          cname: 'jgqp.cdn.cn',
          ip: '123.34.23.200',
          ports: '9050,9051,9052,9053,9054'
        }
      end
      resource :hi, desc: '测试' do
        get :foo do
          result = RestClient.get 'http://apis.map.qq.com/ws/place/v1/suggestion/?region=%E6%88%90%E9%83%BD&keyword=%E8%A5%BF%E5%A4%A7%E8%A1%97&key=EJZBZ-VCM34-QJ4UU-XUWNV-3G2HJ-DWBNJ'
          JSON.parse(result)
        end
      end
    end
  end
end