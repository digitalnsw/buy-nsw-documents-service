class DocumentService::Document < DocumentService::ApplicationRecord
  self.table_name = 'documents'
  include AASM
  extend Enumerize

  ACCEPTABLE_MIME_TYPES = [ 'image/jpeg',
                            'image/png',
                            'application/pdf',
                            'application/xml',
                            'text/xml',
                            'application/csv',
                            'text/csv',
                          ]

  enumerize :scan_status, in: [:unscanned, :clean, :infected]

  mount_uploader :document, DocumentService::DocumentUploader

  after_commit :scan_file, on: :create

  before_validation :remove_invalid_chars_from_name

  def remove_invalid_chars_from_name
    original_filename.gsub!(/[^A-Za-z0-9 .,+~\-_|()]/, '_')
  end

  validates :document, :scan_status, presence: true
  validates :original_filename, format: { with: /\A[A-Za-z0-9 .,+~\-_|()]+\z/ }
  validates :content_type, inclusion: { in: DocumentService::Document::ACCEPTABLE_MIME_TYPES }

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
