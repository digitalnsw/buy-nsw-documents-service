class DocumentService::DocumentRescanJob < SharedModules::ApplicationJob
  class ScanFailure < StandardError; end

  def perform
    DocumentService::Document.unscanned.each(&:scan_file) if doc.updated_at < 15.minute.ago
  end
end
