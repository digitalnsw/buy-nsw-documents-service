class DocumentService::DocumentScanJob < SharedModules::ApplicationJob
  class ScanFailure < StandardError; end

  def perform(document)
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
