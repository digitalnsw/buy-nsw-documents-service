require_dependency "document_service/application_controller"

module DocumentService
  class UploadController < DocumentService::ApplicationController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    skip_before_action :verify_authenticity_token, raise: false
    before_action :authenticate_basic, except: [:download, :upload]
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

    def import_later after_scan
      doc = DocumentService::Document.create!({
        original_filename: params['file'].original_filename,
        content_type: params['file'].content_type,
        document: params['file'].tempfile,
        after_scan: after_scan
      })

      render json: { document: doc.id }, status: :created
    end

    # Public upload endpoint for feedback widget
    def upload
      doc = DocumentService::Document.create!({
        original_filename: params["original_filename"],
        content_type: params["file"].content_type,
        document: params['file'].tempfile,
        public: true
      })
      render json: {id: doc.id}, status: :created
    end

    def upload_suppliers
      import_later "SellerService::SellersImportJob"
    end

    def upload_tenders
      import_later "TenderService::TendersImportJob"
    end

    def upload_registered_users
      import_later "UserService::UsersImportJob"
    end

    def upload_schemes
      import_later "SellerService::SchemesImportJob"
    end

    def upload_scheme_memberships
      import_later "SellerService::SchemeMembershipsImportJob"
    end
  end
end
