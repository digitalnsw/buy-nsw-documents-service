class DocumentService::DocumentRescanJob < SharedModules::ApplicationJob
  class ScanFailure < StandardError; end

  def perform
    DocumentService::Document.unscanned.each do |doc|
      doc.scan_file if doc.updated_at < 15.minute.ago
    end
  end
end
