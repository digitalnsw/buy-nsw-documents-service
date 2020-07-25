class DocumentService::DocumentScanJob < DocumentService::ApplicationJob
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

  private

  def download_file(document)
    if remote_file?
      directory = Rails.root.join('tmp', 'scan', document.to_param)
      FileUtils.mkdir_p(directory)

      path = directory.join("FILE_CONTENT")
      File.open(path, 'w+') do |f|
        f.write(open(document.document.url).read.force_encoding('UTF-8'))
      end

      path.to_s
    else
      document.document.file.path
    end
  end

  def remote_file?
    CarrierWave::Uploader::Base.storage != CarrierWave::Storage::File
  end
end
