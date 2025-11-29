module Admin
  class CartController < BaseController
    before_action :initialize_cart

    def show
      load_cart_items
    end

    def add_bot
      bot = TradingBot.find(params[:id])
      
      if current_user.bot_purchases.exists?(trading_bot_id: bot.id, status: 'active')
        redirect_back fallback_location: admin_shop_index_path, alert: "Vous possédez déjà ce bot"
        return
      end

      if cart_has_bot?(bot.id)
        redirect_back fallback_location: admin_shop_index_path, alert: "Ce bot est déjà dans votre panier"
        return
      end

      session[:cart]['bots'] << bot.id
      redirect_back fallback_location: admin_shop_index_path, notice: "#{bot.name} ajouté au panier"
    end

    def add_product
      product = ShopProduct.find(params[:id])
      
      if current_user.product_purchases.active.exists?(shop_product_id: product.id)
        redirect_back fallback_location: admin_shop_index_path, alert: "Vous possédez déjà ce produit"
        return
      end

      if cart_has_product?(product.id)
        redirect_back fallback_location: admin_shop_index_path, alert: "Ce produit est déjà dans votre panier"
        return
      end

      session[:cart]['products'] << product.id
      redirect_back fallback_location: admin_shop_index_path, notice: "#{product.name} ajouté au panier"
    end

    def remove_bot
      session[:cart]['bots'].delete(params[:id].to_i)
      redirect_to admin_cart_path, notice: "Bot retiré du panier"
    end

    def remove_product
      session[:cart]['products'].delete(params[:id].to_i)
      redirect_to admin_cart_path, notice: "Produit retiré du panier"
    end

    def clear
      session[:cart] = { 'bots' => [], 'products' => [] }
      redirect_to admin_shop_index_path, notice: "Panier vidé"
    end

    def checkout
      load_cart_items

      if @cart_bots.empty? && @cart_products.empty?
        redirect_to admin_cart_path, alert: "Votre panier est vide"
        return
      end

      line_items = []

      @cart_bots.each do |bot|
        stripe_price = get_or_create_bot_stripe_price(bot)
        line_items << { price: stripe_price, quantity: 1 }
      end

      @cart_products.each do |product|
        product.create_stripe_product! if product.stripe_price_id.blank?
        line_items << { price: product.stripe_price_id, quantity: 1 }
      end

      has_subscription = @cart_products.any?(&:subscription?)

      session_params = {
        customer_email: current_user.email,
        payment_method_types: ['card'],
        line_items: line_items,
        mode: has_subscription ? 'subscription' : 'payment',
        success_url: success_admin_cart_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: admin_cart_url + "?canceled=true",
        metadata: {
          user_id: current_user.id,
          bot_ids: session[:cart]['bots'].join(','),
          product_ids: session[:cart]['products'].join(','),
          source: 'cart'
        }
      }

      stripe_session = Stripe::Checkout::Session.create(session_params)
      redirect_to stripe_session.url, allow_other_host: true

    rescue Stripe::StripeError => e
      redirect_to admin_cart_path, alert: "Erreur Stripe: #{e.message}"
    end

    def success
      stripe_session = Stripe::Checkout::Session.retrieve(params[:session_id])
      
      if stripe_session.payment_status == 'paid' || stripe_session.status == 'complete'
        bot_ids = stripe_session.metadata['bot_ids'].to_s.split(',').map(&:to_i).reject(&:zero?)
        product_ids = stripe_session.metadata['product_ids'].to_s.split(',').map(&:to_i).reject(&:zero?)

        ActiveRecord::Base.transaction do
          bot_ids.each do |bot_id|
            bot = TradingBot.find(bot_id)
            next if current_user.bot_purchases.exists?(trading_bot_id: bot_id, status: 'active')
            
            current_user.bot_purchases.create!(
              trading_bot: bot,
              price_paid: bot.price,
              status: 'active',
              is_running: false,
              billing_status: 'paid'
            )
          end

          product_ids.each do |product_id|
            product = ShopProduct.find(product_id)
            next if current_user.product_purchases.active.exists?(shop_product_id: product_id)
            
            current_user.product_purchases.create!(
              shop_product: product,
              price_paid: product.price,
              status: 'active'
            )
          end

          create_invoice_for_cart(bot_ids, product_ids, stripe_session)
        end

        session[:cart] = { 'bots' => [], 'products' => [] }
        
        @purchased_bots = TradingBot.where(id: bot_ids)
        @purchased_products = ShopProduct.where(id: product_ids)
        @total = @purchased_bots.sum(:price) + @purchased_products.sum(:price)
      else
        redirect_to admin_cart_path, alert: "Le paiement n'a pas été complété"
      end
    rescue Stripe::StripeError => e
      redirect_to admin_cart_path, alert: "Erreur: #{e.message}"
    end

    private

    def initialize_cart
      session[:cart] ||= { 'bots' => [], 'products' => [] }
      session[:cart]['bots'] ||= []
      session[:cart]['products'] ||= []
    end

    def load_cart_items
      @cart_bots = TradingBot.where(id: session[:cart]['bots'])
      @cart_products = ShopProduct.where(id: session[:cart]['products'])
      @cart_total = @cart_bots.sum(:price) + @cart_products.sum(:price)
      @cart_count = @cart_bots.count + @cart_products.count
    end

    def cart_has_bot?(bot_id)
      session[:cart]['bots'].include?(bot_id.to_i)
    end

    def cart_has_product?(product_id)
      session[:cart]['products'].include?(product_id.to_i)
    end

    def get_or_create_bot_stripe_price(bot)
      cache_key = "bot_stripe_price_#{bot.id}"
      
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        product = Stripe::Product.create(
          name: "Bot #{bot.name}",
          description: bot.marketing_tagline.to_s.truncate(200),
          metadata: { bot_id: bot.id, type: 'bot' }
        )

        price = Stripe::Price.create(
          product: product.id,
          unit_amount: (bot.price * 100).to_i,
          currency: 'eur'
        )

        price.id
      end
    end

    def create_invoice_for_cart(bot_ids, product_ids, stripe_session)
      invoice = current_user.invoices.create!(
        reference: "SHOP-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
        total_amount: 0,
        balance_due: 0,
        due_date: Date.current,
        status: 'paid',
        stripe_payment_intent_id: stripe_session.payment_intent,
        stripe_customer_id: stripe_session.customer
      )

      total = 0

      bot_ids.each do |bot_id|
        bot = TradingBot.find(bot_id)
        invoice.invoice_items.create!(
          label: "Bot #{bot.name}",
          quantity: 1,
          unit_price: bot.price,
          total_price: bot.price
        )
        total += bot.price
      end

      product_ids.each do |product_id|
        product = ShopProduct.find(product_id)
        invoice.invoice_items.create!(
          label: product.name,
          quantity: 1,
          unit_price: product.price,
          total_price: product.price
        )
        total += product.price
      end

      invoice.update!(total_amount: total, balance_due: 0)
      
      invoice.register_payment!(
        amount: total,
        payment_method: 'stripe',
        paid_at: Time.current,
        notes: "Paiement Stripe via checkout"
      )
    end
  end
end

