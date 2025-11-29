module Admin
  class ShopManagementController < BaseController
    before_action :require_admin

    def index
      @bots = TradingBot.order(:name)
      @products = ShopProduct.order(:position, :name)
      @credit_packs = CreditPack.ordered
      @vps_offers = VpsOffer.ordered
      
      @stats = calculate_stats
      @tab = params[:tab] || 'bots'
    end

    # === BOTS ===
    def toggle_bot
      @bot = TradingBot.find(params[:id])
      @bot.update(is_active: !@bot.is_active)
      redirect_to admin_shop_management_index_path(tab: 'bots'), notice: "#{@bot.name} #{@bot.is_active ? 'activé' : 'masqué'}"
    end

    def duplicate_bot
      original = TradingBot.find(params[:id])
      new_bot = original.dup
      new_bot.name = "#{original.name} (copie)"
      new_bot.is_active = false
      new_bot.save!
      redirect_to edit_admin_bot_path(new_bot), notice: "Bot dupliqué"
    end

    # === PRODUCTS ===
    def toggle_product
      @product = ShopProduct.find(params[:id])
      @product.update(active: !@product.active)
      redirect_to admin_shop_management_index_path(tab: 'products'), notice: "#{@product.name} #{@product.active ? 'activé' : 'désactivé'}"
    end

    def new_product
      @product = ShopProduct.new
    end

    def create_product
      @product = ShopProduct.new(product_params)
      if @product.save
        redirect_to admin_shop_management_index_path(tab: 'products'), notice: "Produit créé"
      else
        render :new_product, status: :unprocessable_entity
      end
    end

    def edit_product
      @product = ShopProduct.find(params[:id])
    end

    def update_product
      @product = ShopProduct.find(params[:id])
      if @product.update(product_params)
        redirect_to admin_shop_management_index_path(tab: 'products'), notice: "Produit mis à jour"
      else
        render :edit_product, status: :unprocessable_entity
      end
    end

    def destroy_product
      @product = ShopProduct.find(params[:id])
      @product.destroy
      redirect_to admin_shop_management_index_path(tab: 'products'), notice: "Produit supprimé"
    end

    # === CREDIT PACKS ===
    def new_credit_pack
      @credit_pack = CreditPack.new
    end

    def create_credit_pack
      @credit_pack = CreditPack.new(credit_pack_params)
      if @credit_pack.save
        redirect_to admin_shop_management_index_path(tab: 'credits'), notice: "Pack créé"
      else
        render :new_credit_pack, status: :unprocessable_entity
      end
    end

    def edit_credit_pack
      @credit_pack = CreditPack.find(params[:id])
    end

    def update_credit_pack
      @credit_pack = CreditPack.find(params[:id])
      if @credit_pack.update(credit_pack_params)
        redirect_to admin_shop_management_index_path(tab: 'credits'), notice: "Pack mis à jour"
      else
        render :edit_credit_pack, status: :unprocessable_entity
      end
    end

    def destroy_credit_pack
      CreditPack.find(params[:id]).destroy
      redirect_to admin_shop_management_index_path(tab: 'credits'), notice: "Pack supprimé"
    end

    def toggle_credit_pack
      pack = CreditPack.find(params[:id])
      pack.update(active: !pack.active)
      redirect_to admin_shop_management_index_path(tab: 'credits'), notice: "Pack #{pack.active ? 'activé' : 'désactivé'}"
    end

    # === VPS OFFERS ===
    def new_vps_offer
      @vps_offer = VpsOffer.new
    end

    def create_vps_offer
      @vps_offer = VpsOffer.new(vps_offer_params)
      if @vps_offer.save
        redirect_to admin_shop_management_index_path(tab: 'vps'), notice: "Offre VPS créée"
      else
        render :new_vps_offer, status: :unprocessable_entity
      end
    end

    def edit_vps_offer
      @vps_offer = VpsOffer.find(params[:id])
    end

    def update_vps_offer
      @vps_offer = VpsOffer.find(params[:id])
      if @vps_offer.update(vps_offer_params)
        redirect_to admin_shop_management_index_path(tab: 'vps'), notice: "Offre mise à jour"
      else
        render :edit_vps_offer, status: :unprocessable_entity
      end
    end

    def destroy_vps_offer
      VpsOffer.find(params[:id]).destroy
      redirect_to admin_shop_management_index_path(tab: 'vps'), notice: "Offre supprimée"
    end

    def toggle_vps_offer
      offer = VpsOffer.find(params[:id])
      offer.update(active: !offer.active)
      redirect_to admin_shop_management_index_path(tab: 'vps'), notice: "Offre #{offer.active ? 'activée' : 'désactivée'}"
    end

    # === EXPORT/IMPORT ===
    def export
      respond_to do |format|
        format.json do
          data = {
            bots: TradingBot.order(:name).map { |b| bot_to_hash(b) },
            products: ShopProduct.order(:position).map { |p| product_to_hash(p) },
            credit_packs: CreditPack.ordered.map { |c| credit_pack_to_hash(c) },
            vps_offers: VpsOffer.ordered.map { |v| vps_offer_to_hash(v) }
          }
          render json: data
        end
        format.csv do
          send_data generate_csv, filename: "catalogue_#{Date.current}.csv", type: 'text/csv'
        end
      end
    end

    def import
      if params[:file].blank?
        redirect_to admin_shop_management_index_path, alert: "Sélectionnez un fichier"
        return
      end

      begin
        import_data(params[:file])
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

