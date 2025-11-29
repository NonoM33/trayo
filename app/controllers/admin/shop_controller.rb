module Admin
  class ShopController < BaseController
    def index
      @bots = TradingBot.available.where(status: 'active').order(:name)
      @my_bot_ids = current_user.bot_purchases.where(status: 'active').pluck(:trading_bot_id)
      @products = ShopProduct.active.ordered
      @my_product_ids = current_user.product_purchases.active.pluck(:shop_product_id)
    end

    def show
      @bot = TradingBot.find(params[:id])
      @already_owned = current_user.bot_purchases.exists?(trading_bot_id: @bot.id, status: 'active')
    end

    def show_product
      @product = ShopProduct.find(params[:id])
      @already_owned = current_user.product_purchases.active.exists?(shop_product_id: @product.id)
    end

    def purchase
      @bot = TradingBot.find(params[:id])
      
      if current_user.bot_purchases.exists?(trading_bot_id: @bot.id, status: "active")
        redirect_to admin_shop_index_path, alert: "Vous possédez déjà ce bot"
        return
      end

      purchase = nil
      ActiveRecord::Base.transaction do
        purchase = current_user.bot_purchases.create!(
          trading_bot: @bot,
          price_paid: @bot.price,
          status: "active",
          is_running: false
        )

        Invoices::Builder.new(
          user: current_user,
          source: "shop",
          metadata: { bot_id: @bot.id },
          deactivate_bots: true
        ).build_from_selection(
          bot_purchases: [purchase],
          vps_list: []
        )
      end
      
      redirect_to admin_my_bots_path, notice: "🎉 Bot réservé ! Facture créée, statut en attente de règlement."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_shop_path(@bot), alert: "Erreur lors de l'achat: #{e.message}"
    end

    def buy_credits
      amount = params[:amount].to_i
      bonus = params[:bonus].to_i
      
      valid_packs = { 500 => 5, 1000 => 6, 1500 => 7, 2000 => 8, 5000 => 10 }
      
      unless valid_packs[amount] == bonus
        redirect_to admin_shop_index_path, alert: "Pack invalide"
        return
      end

      bonus_amount = (amount * bonus / 100.0).round
      total_credit = amount + bonus_amount

      session = Stripe::Checkout::Session.create(
        customer_email: current_user.email,
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'eur',
            product_data: {
              name: "Pack Crédits #{amount}€",
              description: "#{total_credit}€ de crédits (dont #{bonus_amount}€ de bonus)"
            },
            unit_amount: amount * 100
          },
          quantity: 1
        }],
        mode: 'payment',
        success_url: credits_success_admin_shop_index_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: admin_shop_index_url + "?canceled=true",
        metadata: {
          user_id: current_user.id,
          type: 'credit_pack',
          amount: amount,
          bonus: bonus,
          total_credit: total_credit
        }
      )

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      redirect_to admin_shop_index_path, alert: "Erreur Stripe: #{e.message}"
    end

    def credits_success
      stripe_session = Stripe::Checkout::Session.retrieve(params[:session_id])
      
      if stripe_session.payment_status == 'paid' && stripe_session.metadata['type'] == 'credit_pack'
        total_credit = stripe_session.metadata['total_credit'].to_d
        amount = stripe_session.metadata['amount'].to_i
        bonus = stripe_session.metadata['bonus'].to_i
        
        current_user.credits.create!(
          amount: total_credit,
          reason: "Pack #{amount}€ (+#{bonus}% bonus)"
        )
        
        redirect_to admin_shop_index_path, notice: "🎉 #{total_credit}€ de crédits ajoutés à votre compte !"
      else
        redirect_to admin_shop_index_path, alert: "Le paiement n'a pas été complété"
      end
    rescue Stripe::StripeError => e
      redirect_to admin_shop_index_path, alert: "Erreur: #{e.message}"
    end

    def purchase_product
      @product = ShopProduct.find(params[:id])
      
      if current_user.product_purchases.active.exists?(shop_product_id: @product.id)
        redirect_to admin_shop_index_path, alert: "Vous possédez déjà ce produit"
        return
      end

      @product.create_stripe_product! if @product.stripe_price_id.blank?

      if @product.subscription?
        session = Stripe::Checkout::Session.create(
          customer_email: current_user.email,
          payment_method_types: ['card'],
          line_items: [{
            price: @product.stripe_price_id,
            quantity: 1
          }],
          mode: 'subscription',
          success_url: admin_shop_index_url + "?success=true&product_id=#{@product.id}",
          cancel_url: admin_shop_product_url(@product) + "?canceled=true",
          metadata: {
            user_id: current_user.id,
            product_id: @product.id
          }
        )
      else
        session = Stripe::Checkout::Session.create(
          customer_email: current_user.email,
          payment_method_types: ['card'],
          line_items: [{
            price: @product.stripe_price_id,
            quantity: 1
          }],
          mode: 'payment',
          success_url: admin_shop_index_url + "?success=true&product_id=#{@product.id}",
          cancel_url: admin_shop_product_url(@product) + "?canceled=true",
          metadata: {
            user_id: current_user.id,
            product_id: @product.id
          }
        )
      end

      current_user.product_purchases.create!(
        shop_product: @product,
        price_paid: @product.price,
        status: 'pending'
      )

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      redirect_to admin_shop_product_path(@product), alert: "Erreur Stripe: #{e.message}"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_shop_product_path(@product), alert: "Erreur: #{e.message}"
    end
  end
end

