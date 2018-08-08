# encoding: utf-8

class AppFileUploader < BaseUploader

  storage :qiniu
  
  def md5
    @md5 ||= Digest::MD5.hexdigest model.send(mounted_as).read.to_s
  end
  
  def filename
    if super.present?
      "#{secure_token}.#{file.extension}"
    end
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  
  def extension_white_list
    %w(zip rar)
  end
  
  protected
    def secure_token
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
    end

end
