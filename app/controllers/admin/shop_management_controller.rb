module Admin
  class ShopManagementController < BaseController
    before_action :require_admin

    def index
      @bots = TradingBot.order(:name)
      @products = ShopProduct.order(:name) if defined?(ShopProduct)
      @products ||= []
      
      @stats = {
        total_bots: @bots.count,
        active_bots: @bots.where(is_active: true).count,
        total_sales: BotPurchase.count,
        total_revenue: BotPurchase.sum(:price_paid)
      }
    end

    def update_bot
      @bot = TradingBot.find(params[:id])
      
      if @bot.update(bot_params)
        respond_to do |format|
          format.html { redirect_to admin_shop_management_index_path, notice: "Bot mis à jour" }
          format.json { render json: { success: true, bot: @bot } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_shop_management_index_path, alert: @bot.errors.full_messages.join(", ") }
          format.json { render json: { success: false, errors: @bot.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def toggle_bot
      @bot = TradingBot.find(params[:id])
      @bot.update(is_active: !@bot.is_active)
      
      status = @bot.is_active ? "activé" : "désactivé"
      redirect_to admin_shop_management_index_path, notice: "#{@bot.name} #{status}"
    end

    def bulk_update
      params[:bots]&.each do |id, bot_params|
        bot = TradingBot.find_by(id: id)
        bot&.update(price: bot_params[:price]) if bot_params[:price].present?
      end
      
      redirect_to admin_shop_management_index_path, notice: "Prix mis à jour"
    end

    def duplicate_bot
      original = TradingBot.find(params[:id])
      
      new_bot = original.dup
      new_bot.name = "#{original.name} (copie)"
      new_bot.is_active = false
      new_bot.save!
      
      redirect_to edit_admin_bot_path(new_bot), notice: "Bot dupliqué. Modifiez-le maintenant."
    end

    def export
      @bots = TradingBot.order(:name)
      
      respond_to do |format|
        format.json do
          render json: @bots.map { |bot| bot_to_hash(bot) }
        end
        format.csv do
          send_data generate_csv(@bots), filename: "boutique_export_#{Date.current}.csv", type: 'text/csv'
        end
      end
    end

    def import
      if params[:file].blank?
        redirect_to admin_shop_management_index_path, alert: "Sélectionnez un fichier"
        return
      end

      file = params[:file]
      extension = File.extname(file.original_filename).downcase

      begin
        case extension
        when '.json'
          import_from_json(file)
        when '.csv'
          import_from_csv(file)
        else
          redirect_to admin_shop_management_index_path, alert: "Format non supporté (JSON ou CSV)"
          return
        end
        
        redirect_to admin_shop_management_index_path, notice: "Import réussi !"
      rescue => e
        redirect_to admin_shop_management_index_path, alert: "Erreur: #{e.message}"
      end
    end

    private

    def bot_params
      params.require(:trading_bot).permit(
        :name, :description, :price, :status, :is_active,
        :projection_monthly_min, :projection_monthly_max, :projection_yearly,
        :win_rate, :max_drawdown_limit, :risk_level, :symbol, :magic_number_prefix
      )
    end

    def bot_to_hash(bot)
      {
        name: bot.name,
        description: bot.description,
        price: bot.price,
        status: bot.status,
        is_active: bot.is_active,
        symbol: bot.symbol,
        magic_number_prefix: bot.magic_number_prefix,
        projection_monthly_min: bot.projection_monthly_min,
        projection_monthly_max: bot.projection_monthly_max,
        projection_yearly: bot.projection_yearly,
        win_rate: bot.win_rate,
        max_drawdown_limit: bot.max_drawdown_limit,
        risk_level: bot.risk_level,
        strategy_description: bot.strategy_description,
        features: bot.features_list
      }
    end

    def generate_csv(bots)
      require 'csv'
      CSV.generate(headers: true) do |csv|
        csv << ['Nom', 'Prix', 'Statut', 'Actif', 'Symbol', 'Win Rate', 'Risque', 'Ventes', 'Revenus']
        
        bots.each do |bot|
          sales = bot.bot_purchases.count
          revenue = bot.bot_purchases.sum(:price_paid)
          csv << [
            bot.name,
            bot.price,
            bot.status,
            bot.is_active ? 'Oui' : 'Non',
            bot.symbol,
            bot.win_rate,
            bot.risk_level,
            sales,
            revenue
          ]
        end
      end
    end

    def import_from_json(file)
      data = JSON.parse(file.read)
      
      data.each do |bot_data|
        bot = TradingBot.find_or_initialize_by(name: bot_data['name'])
        bot.assign_attributes(
          description: bot_data['description'],
          price: bot_data['price'],
          status: bot_data['status'] || 'active',
          is_active: bot_data['is_active'],
          symbol: bot_data['symbol'],
          magic_number_prefix: bot_data['magic_number_prefix'],
          projection_monthly_min: bot_data['projection_monthly_min'],
          projection_monthly_max: bot_data['projection_monthly_max'],
          projection_yearly: bot_data['projection_yearly'],
          win_rate: bot_data['win_rate'],
          max_drawdown_limit: bot_data['max_drawdown_limit'],
          risk_level: bot_data['risk_level'],
          strategy_description: bot_data['strategy_description'],
          features: bot_data['features']
        )
        bot.save!
      end
    end

    def import_from_csv(file)
      require 'csv'
      csv = CSV.parse(file.read, headers: true)
      
      csv.each do |row|
        bot = TradingBot.find_or_initialize_by(name: row['Nom'])
        bot.assign_attributes(
          price: row['Prix'].to_f,
          status: row['Statut'] || 'active',
          is_active: row['Actif'] == 'Oui',
          symbol: row['Symbol'],
          win_rate: row['Win Rate']&.to_f,
          risk_level: row['Risque']
        )
        bot.save!
      end
    end
  end
end

