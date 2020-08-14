require_dependency "document_service/application_controller"

module DocumentService
  class AvatarsController < DocumentService::ApplicationController
    before_action :authenticate_user, only: [:create]

    def uploaded_by_me? document
      session_user && session_user.id == document.uploaded_by_id
    end

    def serialize document
      result = document.attributes.slice(
        'id',
        'scan_status',
        'content_type',
        'original_filename',
        'created_at',
        'uploaded_by_id').
        merge(scan_status_text: document.scan_status_text, extension: document.extension, size: document.size)
      result.merge!(url: document.url) if uploaded_by_me?(document) && !document.infected? || document.clean?
      result
    end

    def create
      doc = DocumentService::Document.create!({
        uploaded_by_id: session_user.id,
        original_filename: params["original_filename"],
        content_type: params["file"].content_type,
        document: params['file'].tempfile,
        public: true
      })
      render json: {id: doc.id}, status: :created
    end

    def show
      doc = DocumentService::Document.where(public: true).find(params[:id])
      render json: { avatar: serialize(doc) }
    end
  end
end
