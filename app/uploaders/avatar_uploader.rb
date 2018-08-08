# encoding: utf-8

class AvatarUploader < BaseUploader

  storage :qiniu
  
  version :normal do
    process resize_to_fill: [48, 48]
  end

  version :small do
    process resize_to_fill: [16, 16]
  end

  version :large do
    process resize_to_fill: [64, 64]
  end

  version :big do
    process resize_to_fill: [120, 120]
  end

  def filename
    if super.present?
      "#{secure_token}.#{file.extension}"
    end
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end
  
  def extension_white_list
    %w(jpg jpeg png)
  end
  
  protected
    def secure_token
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
    end

end
