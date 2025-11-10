class SwaggerYamlController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    content = File.read(Rails.root.join('swagger.yaml'))
    render plain: content, content_type: 'text/yaml; charset=utf-8'
  end
end

