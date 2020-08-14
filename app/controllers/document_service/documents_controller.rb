require_dependency "document_service/application_controller"

module DocumentService
  class DocumentsController < DocumentService::ApplicationController
    before_action :authenticate_user, only: [:create]
    before_action :authenticate_service_or_user, only: [:show, :index, :can_attach]

    def can_download_document? document
      session_user && session_user.can_buy?
    end

    def my_document? document
      seller_id = session_user && session_user.is_seller? &&
        session_user.seller_id && session_user.seller_id == document.seller_id
    end

    def serialize document
      if service_auth? || my_document?(document) || can_download_document?(document)
        result = document.attributes.slice(
            'id',
            'scan_status',
            'content_type',
            'original_filename',
            'created_at',
            'uploaded_by_id',
            'seller_id').
            merge(scan_status_text: document.scan_status_text, extension: document.extension, size: document.size)
        result.merge!(url: document.url) if document.clean?
        result
      elsif document.public
        document.attributes.slice(
          'id',
          'content_type',
          'original_filename',
        ).merge(extension: document.extension, size: document.size)
      else
        {}
      end
    end

    def create
      doc = DocumentService::Document.create!({
        seller_id: session_user&.seller_id,
        uploaded_by_id: session_user&.id,
        original_filename: html_escape_once(params["original_filename"]),
        content_type: params["file"].content_type,
        document: params['file'].tempfile,
        public: session_user.blank?
      })
      render json: {id: doc.id}, status: :created
    end

    def show
      doc = DocumentService::Document.find(params[:id])
      render json: { document: serialize(doc) }
    end

    def index
      ids = params[:ids].map(&:to_i)
      docs = DocumentService::Document.where(id: params[:ids]).to_a.sort_by{|d| ids.index(d.id)}
      render json: { documents: docs.map{|doc|serialize(doc)} }
    end

    def can_attach
      ids = params[:document_ids].map(&:to_i)
      seller_ids = DocumentService::Document.where(id: ids).pluck(:seller_id)
      if seller_ids.uniq == [params[:seller_id].to_i]
        render json: { document: {} }
      else
        raise SharedModules::AccessForbidden
      end
    end
  end
end
