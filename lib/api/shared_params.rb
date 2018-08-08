module API
  module SharedParams
    extend Grape::API::Helpers
    # 分页参数
    # 使用例子：
    #   params do
    #     use :pagination
    #   end
    params :pagination do
      optional :page, type: Integer, desc: "当前页"
      optional :size, type: Integer, desc: "分页大小，默认值为：15"
    end # end pagination params
    
    # 设备信息相关的参数
    params :device_info do
      requires :udid,    type: String, desc: '设备ID'
      requires :m,       type: String, desc: "设备名，例如：iPhone8,1或HUAWEI honor 8"
      requires :pl,      type: String, desc: "设备平台，iOS或Android"
      requires :osv,     type: String, desc: "系统版本, 例如：9.3.2"
      requires :bv,      type: String, desc: "当前app版本号"
      requires :sr,      type: String, desc: "设备屏幕分辨率，例如：1080x1920"
      requires :cl,      type: String, desc: "国家语言码，例如：zh_CN"
      requires :nt,      type: String, desc: "网络类型，例如：WIFI或者3G或者4G"
      requires :bb,      type: Integer, desc: "是否越狱，例如：0或1，0表示设备没有越狱，1表示设备越狱"
    end
    
    # API访问参数
    params :api_access do
      requires :ak, type: String, desc: 'API访问Key'
      requires :i,  type: String, desc: '时间戳'
    end
    
  end
end