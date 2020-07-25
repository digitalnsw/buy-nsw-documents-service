class DocumentService::Document < DocumentService::ApplicationRecord
  self.table_name = 'documents'
  include AASM
  extend Enumerize

  enumerize :scan_status, in: [:unscanned, :clean, :infected]

  mount_uploader :document, DocumentService::DocumentUploader

  after_commit :scan_file, on: :create

  validates :document, :scan_status, presence: true

  aasm column: :scan_status do
    state :unscanned, initial: true
    state :clean
    state :infected

    event :mark_as_clean do
      transitions from: :unscanned, to: :clean
    end

    event :mark_as_infected do
      transitions from: :unscanned, to: :infected
    end

    event :reset_scan_status do
      transitions from: [:clean, :infected], to: :unscanned
    end
  end

  def url
    document.url
  end

  def mime_type
    MIME::Types[content_type].first
  end

  def extension
    mime_type.preferred_extension.upcase
  end

  def size
    document.size
  end

  def rescan_file
    update_column(:scan_status, 'unscanned') unless unscanned?
    scan_file
  end

  def scan_file
    DocumentService::DocumentScanJob.perform_later(self)
  end
end
