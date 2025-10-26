module Admin
  class TestController < BaseController
    # Pas de before_action pour éviter les conflits
    
    def client_dropdowns
      # Page de test pour les dropdowns de la page client
      render 'admin/test_client_dropdowns'
    end
    
    def debug
      # Page de debug pour l'accès aux clients
      render 'admin/client_access_debug'
    end
    
    def routes_test
      # Page de test pour vérifier que les routes fonctionnent
      render 'admin/routes_test'
    end
    
    def routes_and_drawdown_test
      # Page de test pour les routes et le drawdown
      render 'admin/routes_and_drawdown_test'
    end
    
    def drawdown_percentage_test
      # Page de test pour les drawdowns en pourcentage
      render 'admin/drawdown_percentage_test'
    end
  end
end
