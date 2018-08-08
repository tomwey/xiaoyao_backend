require 'grape-swagger'
module API
  class Dispatch < Grape::API
    use ActionDispatch::RemoteIp
    
    default_error_formatter :json
    format :json
    content_type :json, 'application/json;charset=utf-8'
    
    # 异常处理
    rescue_from :all do |e|
      case e
      when ActiveRecord::RecordNotFound
        Rack::Response.new(['数据不存在'], 404, {}).finish
      when Grape::Exceptions::ValidationErrors
        Rack::Response.new([{
          error: "参数不符合要求，请检查参数是否按照 API 要求传输。",
          validation_errors: e.errors
        }.to_json], 400, {}).finish
      else
        Rails.logger.error "API Error: #{e}\n#{e.backtrace.join("\n")}"
        Rack::Response.new([{ error: "API 接口异常: #{e}"}.to_json], 500, {}).finish
      end
    end # end rescue_from
    
    before do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
      header['Access-Control-Allow-Headers'] = 'Authorization' # fixed angular 2 isTrusted: true bug
      header 'X-Robots-Tag', 'noindex'
    end # end before
    
    mount API::V1::Root
    
    route :any, '*path' do
      status 404
      { error: 'Page Not Found.' }
    end # end route :any
    
  end
end