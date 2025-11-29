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

    def product_params
      params.require(:shop_product).permit(:name, :description, :price, :product_type, :interval, :icon, :badge, :badge_color, :features, :active, :position)
    end

    def credit_pack_params
      params.require(:credit_pack).permit(:amount, :bonus_percentage, :label, :is_popular, :is_best, :active, :position)
    end

    def vps_offer_params
      params.require(:vps_offer).permit(:name, :price, :specs, :description, :is_recommended, :active, :position)
    end

    def calculate_stats
      bot_sales = BotPurchase.count
      bot_revenue = BotPurchase.sum(:price_paid)
      product_sales = ProductPurchase.count rescue 0
      product_revenue = ProductPurchase.sum(:price_paid) rescue 0
      credit_revenue = Credit.where("reason LIKE ?", "Pack%").sum(:amount) rescue 0
      vps_revenue = Vps.sum(:monthly_price) rescue 0

      {
        total_products: TradingBot.count + ShopProduct.count + CreditPack.count + VpsOffer.count,
        active_products: TradingBot.where(is_active: true).count + ShopProduct.where(active: true).count + CreditPack.where(active: true).count + VpsOffer.where(active: true).count,
        total_sales: bot_sales + product_sales,
        total_revenue: bot_revenue + product_revenue + credit_revenue + vps_revenue
      }
    end

    def bot_to_hash(bot)
      { type: 'bot', name: bot.name, price: bot.price, is_active: bot.is_active }
    end

    def product_to_hash(product)
      { type: 'product', name: product.name, price: product.price, active: product.active }
    end

    def credit_pack_to_hash(pack)
      { type: 'credit_pack', amount: pack.amount, bonus_percentage: pack.bonus_percentage, active: pack.active }
    end

    def vps_offer_to_hash(offer)
      { type: 'vps_offer', name: offer.name, price: offer.price, active: offer.active }
    end

    def generate_csv
      require 'csv'
      CSV.generate(headers: true) do |csv|
        csv << ['Type', 'Nom', 'Prix', 'Actif']
        TradingBot.order(:name).each { |b| csv << ['Bot', b.name, b.price, b.is_active ? 'Oui' : 'Non'] }
        ShopProduct.order(:position).each { |p| csv << ['Produit', p.name, p.price, p.active ? 'Oui' : 'Non'] }
        CreditPack.ordered.each { |c| csv << ['Crédits', "Pack #{c.amount}€", c.amount, c.active ? 'Oui' : 'Non'] }
        VpsOffer.ordered.each { |v| csv << ['VPS', v.name, v.price, v.active ? 'Oui' : 'Non'] }
      end
    end

    def import_data(file)
      data = JSON.parse(file.read)
      
      data['bots']&.each do |d|
        bot = TradingBot.find_or_initialize_by(name: d['name'])
        bot.assign_attributes(d.except('type'))
        bot.save!
      end
      
      data['products']&.each do |d|
        product = ShopProduct.find_or_initialize_by(name: d['name'])
        product.assign_attributes(d.except('type'))
        product.save!
      end
      
      data['credit_packs']&.each do |d|
        pack = CreditPack.find_or_initialize_by(amount: d['amount'])
        pack.assign_attributes(d.except('type'))
        pack.save!
      end
      
      data['vps_offers']&.each do |d|
        offer = VpsOffer.find_or_initialize_by(name: d['name'])
        offer.assign_attributes(d.except('type'))
        offer.save!
      end
    end
  end
end
