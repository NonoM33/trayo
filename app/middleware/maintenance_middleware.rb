class MaintenanceMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = ActionDispatch::Request.new(env)
    
    Rails.logger.info "MaintenanceMiddleware: #{request.path} - Maintenance enabled: #{maintenance_enabled?} - Admin access: #{admin_access?(request)}"
    
    # Vérifier si la maintenance est activée
    if maintenance_enabled? && !admin_access?(request)
      Rails.logger.info "MaintenanceMiddleware: Showing maintenance page for #{request.path}"
      return maintenance_page
    end
    
    @app.call(env)
  end
  
  private
  
  def maintenance_enabled?
    # Utiliser le modèle Rails pour vérifier l'état de maintenance
    begin
      MaintenanceSetting.current.is_enabled?
    rescue => e
      Rails.logger.error "Erreur lors de la vérification de la maintenance: #{e.message}"
      false
    end
  end
  
  def admin_access?(request)
    # Permettre l'accès aux admins via URL spéciale
    return true if request.path.start_with?('/admin')
    return true if request.path.start_with?('/maintenance')
    
    # Permettre l'accès aux assets et fichiers statiques
    return true if request.path.start_with?('/assets')
    return true if request.path.start_with?('/images')
    return true if request.path.start_with?('/javascripts')
    return true if request.path.start_with?('/stylesheets')
    return true if request.path.start_with?('/favicon')
    return true if request.path.start_with?('/robots.txt')
    
    false
  end
  
  def maintenance_page
    # Utiliser les données du modèle MaintenanceSetting
    maintenance = MaintenanceSetting.current
    
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{maintenance.title || 'Maintenance'} - Trayo</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          
          body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a1a;
            color: #ffffff;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
          }
          
          .maintenance-container {
            text-align: center;
            max-width: 500px;
            padding: 40px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
          }
          
          .logo {
            width: 80px;
            height: 80px;
            margin: 0 auto 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            font-weight: bold;
            color: white;
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
          }
          
          .logo img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 20px;
          }
          
          h1 {
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 16px;
            color: #ffffff;
            letter-spacing: -0.5px;
          }
          
          h2 {
            font-size: 18px;
            font-weight: 400;
            margin-bottom: 24px;
            color: #a0a0a0;
            line-height: 1.4;
          }
          
          p {
            font-size: 16px;
            line-height: 1.6;
            color: #c0c0c0;
            margin-bottom: 32px;
          }
          
          .admin-link {
            display: inline-block;
            padding: 12px 24px;
            background: rgba(255, 255, 255, 0.1);
            color: #ffffff;
            text-decoration: none;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 500;
            border: 1px solid rgba(255, 255, 255, 0.2);
            transition: all 0.3s ease;
            backdrop-filter: blur(10px);
          }
          
          .admin-link:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
          }
          
          .status-indicator {
            display: inline-block;
            width: 8px;
            height: 8px;
            background: #ff6b6b;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
          }
          
          @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
          }
          
          .maintenance-text {
            font-size: 14px;
            color: #888;
            margin-top: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
          }
        </style>
      </head>
      <body>
        <div class="maintenance-container">
          <div class="logo">
            #{maintenance.logo_url.present? ? "<img src=\"#{maintenance.logo_url}\" alt=\"Trayo\">" : "T"}
          </div>
          
          <h1>#{maintenance.title || 'Maintenance'}</h1>
          
          #{maintenance.subtitle.present? ? "<h2>#{maintenance.subtitle}</h2>" : ""}
          
          #{maintenance.description.present? ? "<p>#{maintenance.description}</p>" : "<p>Nous travaillons actuellement sur des améliorations pour vous offrir une meilleure expérience.</p>"}
          
          <a href="/admin" class="admin-link">Accès Administrateur</a>
          
          <div class="maintenance-text">
            <span class="status-indicator"></span>
            Mode maintenance actif
          </div>
        </div>
      </body>
      </html>
    HTML
    
    [200, { 'Content-Type' => 'text/html' }, [html]]
  end
end
