# encoding: utf-8

class BannerImageUploader < BaseUploader

  storage :qiniu
  # storage :file

  version :big do
    process resize_to_fill: [1080, 504]
  end
  
  version :large do
    process resize_to_fill: [750, 350]
  end
  
  version :thumb do
    process resize_to_fill: [540, 252]
  end
  
  version :small do
    process resize_to_fill: [150, 70]
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
    %w(jpg jpeg png gif)
  end
  
  protected
    def secure_token
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
    end

end
