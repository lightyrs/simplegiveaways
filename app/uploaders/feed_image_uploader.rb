# encoding: utf-8

class FeedImageUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick
  include CarrierWave::Compatibility::Paperclip

  storage :fog

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  version :feed do
    process resize_to_limit: [90, 90]
    process quality: 70
    process :strip
  end

  version :thumb do
    process resize_to_fill: [111, 74]
    process quality: 75
    process :strip
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end
end
