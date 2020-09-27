class DocumentService::DocumentScanJob < SharedModules::ApplicationJob
  class ScanFailure < StandardError; end

  def clamby_is_ready?
    # This keeps running clamby safe till it returns true once
    @ready ||= Clamby.safe?(Rails.root.join('Gemfile').to_s)
  end

  def file_content_safe?(file)
    file_type = `file --b --mime-type #{file}`.strip
    file_type.in? DocumentService::Document::ACCEPTABLE_MIME_TYPES
  end

  def perform(document)
    if Rails.env.development?
      document.mark_as_clean!
      return
    end
    raise "Clamby is not ready!" unless clamby_is_ready?

    file = download_file(document)

    unless file_content_safe?(file)
      document.mark_as_infected!
    else
      case Clamby.safe?(file)
      when true then document.mark_as_clean!
      when false then document.mark_as_infected!
      else
        raise ScanFailure
      end
    end

    document.after_scan.constantize.perform_later(document) if document.after_scan && document.clean?
  end
end
