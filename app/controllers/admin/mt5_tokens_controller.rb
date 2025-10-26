module Admin
  class Mt5TokensController < BaseController
    before_action :require_admin

    def index
      @tokens = Mt5Token.used.order(used_at: :desc).page(params[:page]).per(20)
    end

    def new
      # Générer directement le token sans formulaire
      @generated_token = User.generate_mt5_registration_token
      
      # Sauvegarder le token en session pour 1 heure
      session[:generated_mt5_token] = @generated_token
      session[:token_generated_at] = Time.current.to_i
      
      render :show_token
    end

    def create
      # Générer le token sans le sauvegarder
      @generated_token = User.generate_mt5_registration_token
      
      # Sauvegarder le token en session pour 1 heure
      session[:generated_mt5_token] = @generated_token
      session[:token_generated_at] = Time.current.to_i
      
      # Afficher la page avec le token généré
      render :show_token
    end

    def show_token
      # Récupérer le token depuis la session
      @generated_token = session[:generated_mt5_token]
      @token_generated_at = session[:token_generated_at]
      
      # Vérifier si le token existe et n'est pas expiré (1 heure)
      if @generated_token && @token_generated_at
        token_age = Time.current.to_i - @token_generated_at
        if token_age > 3600 # 1 heure = 3600 secondes
          # Token expiré, le supprimer de la session
          session.delete(:generated_mt5_token)
          session.delete(:token_generated_at)
          @generated_token = nil
          @token_expired = true
        end
      else
        @generated_token = nil
      end
    end

    def show
      @token = Mt5Token.find(params[:id])
    end

    def destroy
      @token = Mt5Token.find(params[:id])
      @token.destroy
      redirect_to admin_mt5_tokens_path, notice: 'Token supprimé avec succès!'
    end

    private

    def token_params
      params.require(:mt5_token).permit(:description, :client_name)
    end
  end
end
