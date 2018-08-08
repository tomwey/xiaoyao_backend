# encoding: utf-8
class AppPackageUploader < CarrierWave::Uploader::Base
  
  # storage :qiniu
  storage :file
  
  def extension_white_list
    %w(apk ipa)
  end
  
  def filename
    if super.present?
      "#{secure_token}.#{file.extension}"
    end
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  
  protected
    def secure_token
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid.gsub('-', ''))
    end

end
