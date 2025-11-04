class ApiDocumentationController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    @swagger_json_path = "/api-docs/swagger.yaml"
  end
end

