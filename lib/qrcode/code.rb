require 'rqrcode_png'
require 'chunky_png'
module Qrcode
  class Code
    def initialize(text, code_size = 152, logo_size = 36)
      @text = text
      @code_size = code_size
      @logo_size = logo_size
    end
    
    def generate(dest_path, composed_file = '')
      qr = RQRCode::QRCode.new(@text, size: 8, level: :h)
      
      code_image = qr.to_img.resize(@code_size, @code_size)
      
      # 添加logo图片到二维码上
      if not composed_file.blank?
        if @code_size >= @logo_size
          logo_image = ChunkyPNG::Image.from_file(composed_file).resize(@logo_size, @logo_size)
          offset_x = ( @code_size - @logo_size ) / 2
          code_image.compose!(logo_image, offset_x, offset_x)
        end
      end
      
      # 保存二维码图片
      code_image.save(dest_path) unless dest_path.blank?
    end
  end
end