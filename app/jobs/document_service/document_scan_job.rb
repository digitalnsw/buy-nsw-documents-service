class DocumentService::DocumentScanJob < SharedModules::ApplicationJob
  class ScanFailure < StandardError; end

  def clamby_is_ready?
    # This keeps running clamby safe till it returns true once
    @ready ||= Clamby.safe?(Rails.root.join('Gemfile').to_s)
  end

  def perform(document)
    raise "Clamby is not ready!" unless clamby_is_ready?

    file = download_file(document)
    status = case Clamby.safe?(file)
             when true then document.mark_as_clean!
             when false then document.mark_as_infected!
             else
               raise ScanFailure
             end
    document.after_scan.constantize.perform_later(document) if document.after_scan && document.clean?
    status
  end
end
