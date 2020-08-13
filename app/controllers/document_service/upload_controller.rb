require_dependency "document_service/application_controller"

module DocumentService
  class UploadController < DocumentService::ApplicationController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    skip_before_action :verify_authenticity_token, raise: false
    before_action :authenticate_basic, except: [:download]
    before_action :authenticate_service_or_admin, only: [:download]

    def download
      id = params[:id].to_i
      document = DocumentService::Document.find id
      if document.clean?
        redirect_to document.url
      else
        render json: { error: "Document is not clean!" }
      end
    end

    def upload after_scan
      doc = DocumentService::Document.create!({
        original_filename: params['file'].original_filename,
        content_type: params['file'].content_type,
        document: params['file'].tempfile,
        after_scan: after_scan
      })

      render json: { document: doc.id }, status: :created
    end

    def upload_suppliers
      upload "SellerService::SellersImportJob"
    end

    def upload_tenders
      upload "TenderService::TendersImportJob"
    end
  end
end
