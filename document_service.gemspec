$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "document_service/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "document_service"
  s.version     = DocumentService::VERSION
  s.authors     = ["Arman"]
  s.email       = ["arman.zrb@gmail.com"]
  s.homepage    = ""
  s.summary     = "Summary of DocumentService."
  s.description = "Description of DocumentService."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
end
