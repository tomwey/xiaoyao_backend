require 'rest-client'

class ShortUrl
  def self.baidu(url)
    r = RestClient.post 'http://dwz.cn/create.php', { url: "#{url}" }, { accept: :json }
    puts r
  end
  
  def self.sina(url)
    sina_url = "http://api.t.sina.com.cn/short_url/shorten.json?source=#{SiteConfig.sina_shorten_api_key}&url_long=#{url}"
    r = RestClient.get sina_url, { content_type: :json, accept: :json }
    res = JSON.parse(r)
    if res and res.count > 0 
      item = res[0]
      return item['url_short'] || url
    else
      return url
    end
  end
end

# ShortUrl.sina('http://afterwind.cn')