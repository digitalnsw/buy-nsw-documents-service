class DocumentService::DocumentUploader < CarrierWave::Uploader::Base
  # This number should be the same as the guidance in the content:
  # app/views/sellers/applications/_documents_form.html.erb
  def size_range
    1..10.megabytes
  end

  def store_dir
    "uploads/document/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(jpg jpeg pdf png xml csv)
  end

  def content_type_whitelist
    DocumentService::Document::ACCEPTABLE_MIME_TYPES
  end

  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
