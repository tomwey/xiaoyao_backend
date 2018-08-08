# encoding: utf-8
require 'digest/md5'
require 'carrierwave/processing/mini_magick'
class AdContentsUploader < CarrierWave::Uploader::Base
  
  storage :qiniu
  # storage :file
  
  def extension_white_list
    %w(jpg jpeg gif png mp4 mov)
  end
  
  def filename
    if original_filename.present?
      # "#{SecureRandom.uuid}.#{file.extension}"
      # current_path 是 Carrierwave 上传过程临时创建的一个文件，有时间标记
      # 例如: /Users/jason/work/ruby-china/public/uploads/tmp/20131105-1057-46664-5614/_____2013-11-05___10.37.50.png
      @name ||= Digest::MD5.hexdigest(original_filename)
      "#{@name}.#{file.extension.downcase}"
    end
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

end
