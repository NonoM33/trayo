module EncodingSafe
  extend ActiveSupport::Concern

  included do
    before_action :sanitize_params_encoding
    rescue_from ActionController::BadRequest, with: :handle_bad_request
    rescue_from Encoding::InvalidByteSequenceError, with: :handle_encoding_error
    rescue_from Encoding::UndefinedConversionError, with: :handle_encoding_error
  end

  private

  def sanitize_params_encoding
    deep_sanitize_params(request.query_parameters)
    deep_sanitize_params(request.request_parameters)
    sanitize_hash(params)
  rescue => e
    Rails.logger.warn "EncodingSafe: Failed to sanitize params - #{e.message}"
  end

  def deep_sanitize_params(hash)
    return hash unless hash.respond_to?(:each)
    
    hash.each do |key, value|
      sanitized_key = key.is_a?(String) ? force_valid_encoding(key) : key
      
      case value
      when String
        hash[sanitized_key] = force_valid_encoding(value)
      when Hash
        deep_sanitize_params(value)
      when Array
        hash[sanitized_key] = value.map { |v| v.is_a?(String) ? force_valid_encoding(v) : v }
      end
    end
    
    hash
  end

  def sanitize_hash(hash)
    return hash unless hash.respond_to?(:each)
    
    hash.each do |key, value|
      case value
      when String
        hash[key] = force_valid_encoding(value)
      when Hash, ActionController::Parameters
        sanitize_hash(value)
      when Array
        hash[key] = value.map { |v| v.is_a?(String) ? force_valid_encoding(v) : v }
      end
    end
    
    hash
  end

  def force_valid_encoding(str)
    return str if str.nil?
    return str if str.valid_encoding?
    
    str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
    Rails.logger.warn "EncodingSafe: Encoding error for string - #{e.message}"
    str.bytes.pack('C*').force_encoding('UTF-8').chars.select(&:valid_encoding?).join
  rescue => e
    Rails.logger.warn "EncodingSafe: Unexpected error - #{e.message}"
    ""
  end

  def handle_bad_request(exception)
    Rails.logger.warn "EncodingSafe: BadRequest handled - #{exception.message}"
    
    respond_with_encoding_error("Erreur de requête - paramètres invalides. Veuillez réessayer.")
  end

  def handle_encoding_error(exception)
    Rails.logger.warn "EncodingSafe: Encoding error handled - #{exception.message}"
    
    respond_with_encoding_error("Erreur d'encodage - caractères invalides détectés. Veuillez réessayer.")
  end

  def respond_with_encoding_error(message)
    if request.format.html?
      flash[:alert] = message
      fallback = encoding_safe_fallback_location
      redirect_to fallback, allow_other_host: false
    else
      render json: { error: "Invalid request parameters" }, status: :bad_request
    end
  end

  def encoding_safe_fallback_location
    controller_path_parts = controller_path.split('/')
    
    if controller_path_parts.first == 'admin'
      send("admin_#{controller_name}_path") rescue admin_root_path rescue root_path
    else
      root_path
    end
  rescue
    root_path
  end
end

