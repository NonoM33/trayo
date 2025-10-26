module Api
  module V1
    class Mt5DataController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :verify_api_key

      def sync
        # Chercher d'abord par token MT5
        user = User.find_by(mt5_api_token: sync_params[:mt5_api_token])
        
        # Si pas trouvé par token, chercher par email
        unless user
          user = User.find_by(email: sync_params[:client_email])
        end
        
        # Si l'utilisateur existe déjà mais n'a pas de token, mettre à jour le token
        if user && user.mt5_api_token.blank?
          user.update(mt5_api_token: sync_params[:mt5_api_token])
          Rails.logger.info "Token MT5 mis à jour pour l'utilisateur: #{user.email}"
        end
        
        # Si l'utilisateur n'existe toujours pas, le créer automatiquement
        unless user
          begin
            user = User.create_from_mt5_data(sync_params)
            Rails.logger.info "Utilisateur auto-créé avec le token MT5: #{sync_params[:mt5_api_token]}"
          rescue => e
            Rails.logger.error "Erreur lors de la création automatique de l'utilisateur: #{e.message}"
            render json: { error: "Failed to create user automatically: #{e.message}" }, status: :unprocessable_entity
            return
          end
        end

        mt5_account = Mt5Account.find_or_initialize_by(mt5_id: sync_params[:mt5_id])
        
        # Vérifier si une synchronisation complète est requise
        # FORCER LA SYNCHRO COMPLÈTE SI LE COMPTE A PEU DE TRADES
        trades_count = mt5_account.persisted? ? mt5_account.trades.count : 0
        
        if !user.init_mt5 || (trades_count > 0 && trades_count < 50)
          # Demandons la synchro complète si init_mt5 est false OU si on a très peu de trades
          if trades_count < 50 && trades_count > 0
            Rails.logger.warn "Compte #{sync_params[:mt5_id]}: seulement #{trades_count} trades détectés. Forcer la synchro complète."
          end
          
          render json: { 
            init_required: true, 
            send_all_history: true,
            message: "Complete history synchronization required"
          }, status: :ok
          return
        end
        
        # Assigner l'utilisateur si nécessaire
        if mt5_account.new_record? || mt5_account.user.nil?
          mt5_account.user = user
          mt5_account.save! # Sauvegarder immédiatement après assignation
        end

        old_balance = mt5_account.balance
        new_balance = sync_params[:balance].to_f

        detect_withdrawal(mt5_account, old_balance, new_balance)

        mt5_account.update_from_mt5_data(
          account_name: sync_params[:account_name],
          balance: new_balance
        )

        sync_trades(mt5_account, sync_params[:trades]) if sync_params[:trades].present?
        sync_open_positions(mt5_account, sync_params[:open_positions]) if sync_params[:open_positions].present?
        sync_withdrawals(mt5_account, sync_params[:withdrawals]) if sync_params[:withdrawals].present?
        sync_deposits(mt5_account, sync_params[:deposits]) if sync_params[:deposits].present?
        
        # Détecter et assigner automatiquement les bots basés sur les magic numbers
        user.auto_detect_and_assign_bots
        
        sync_bot_performances(mt5_account.user)

        render json: {
          message: "Data synchronized successfully",
          mt5_account: {
            id: mt5_account.id,
            mt5_id: mt5_account.mt5_id,
            account_name: mt5_account.account_name,
            balance: mt5_account.balance,
            last_sync_at: mt5_account.last_sync_at,
            high_watermark: mt5_account.high_watermark,
            total_withdrawals: mt5_account.total_withdrawals,
            total_deposits: mt5_account.total_deposits
          },
          trades_synced: sync_params[:trades]&.count || 0,
          withdrawals_synced: sync_params[:withdrawals]&.count || 0,
          deposits_synced: sync_params[:deposits]&.count || 0
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def sync_complete_history
        user = User.find_by(mt5_api_token: sync_params[:mt5_api_token])
        
        # Si l'utilisateur n'existe pas, le créer automatiquement
        unless user
          begin
            user = User.create_from_mt5_data(sync_params)
            Rails.logger.info "Utilisateur auto-créé avec le token MT5: #{sync_params[:mt5_api_token]}"
          rescue => e
            Rails.logger.error "Erreur lors de la création automatique de l'utilisateur: #{e.message}"
            render json: { error: "Failed to create user automatically: #{e.message}" }, status: :unprocessable_entity
            return
          end
        end

        mt5_account = Mt5Account.find_or_initialize_by(mt5_id: sync_params[:mt5_id])
        
        # Assigner l'utilisateur si nécessaire
        if mt5_account.new_record? || mt5_account.user.nil?
          mt5_account.user = user
          # S'assurer que les champs requis sont présents pour un nouveau compte
          if mt5_account.new_record?
            mt5_account.account_name = sync_params[:account_name] if sync_params[:account_name].present?
            mt5_account.balance = sync_params[:balance].to_f if sync_params[:balance].present?
          end
          mt5_account.save! # Sauvegarder immédiatement après assignation
        end

        # Mettre à jour les informations du compte
        mt5_account.update_from_mt5_data(
          account_name: sync_params[:account_name],
          balance: sync_params[:balance].to_f
        )

        # Synchroniser tout l'historique
        sync_trades(mt5_account, sync_params[:trades]) if sync_params[:trades].present?
        sync_withdrawals(mt5_account, sync_params[:withdrawals]) if sync_params[:withdrawals].present?
        sync_deposits(mt5_account, sync_params[:deposits]) if sync_params[:deposits].present?

        # Détecter et assigner automatiquement les bots basés sur les magic numbers
        user.auto_detect_and_assign_bots

        # Calculer automatiquement le capital initial
        calculated_initial = mt5_account.calculate_initial_balance_from_history

        # Marquer comme initialisé
        user.update!(init_mt5: true)

        sync_bot_performances(mt5_account.user)

        render json: {
          message: "Complete history synchronized successfully",
          mt5_account: {
            id: mt5_account.id,
            mt5_id: mt5_account.mt5_id,
            account_name: mt5_account.account_name,
            balance: mt5_account.balance,
            calculated_initial_balance: calculated_initial,
            auto_calculated_initial_balance: mt5_account.auto_calculated_initial_balance,
            last_sync_at: mt5_account.last_sync_at
          },
          trades_synced: sync_params[:trades]&.count || 0,
          withdrawals_synced: sync_params[:withdrawals]&.count || 0,
          deposits_synced: sync_params[:deposits]&.count || 0,
          init_completed: true
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Sync complete history error: #{e.message}"
        Rails.logger.error "Mt5Account: #{mt5_account.inspect}" if defined?(mt5_account)
        render json: { error: e.message, details: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue => e
        Rails.logger.error "Unexpected error in sync_complete_history: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error: #{e.message}" }, status: :internal_server_error
      end

      private

      def verify_api_key
        api_key = request.headers["X-API-Key"]
        expected_key = ENV["MT5_API_KEY"] || "mt5_secret_key_change_in_production"
        
        unless api_key == expected_key
          render json: { error: "Invalid API key" }, status: :unauthorized
        end
      end

      def sync_params
        params.require(:mt5_data).permit(
          :mt5_id,
          :mt5_api_token,
          :account_name,
          :client_email,
          :balance,
          :equity,
          trades: [
            :trade_id,
            :symbol,
            :trade_type,
            :volume,
            :open_price,
            :close_price,
            :profit,
            :commission,
            :swap,
            :open_time,
            :close_time,
            :status,
            :magic_number,
            :comment
          ],
          open_positions: [
            :trade_id,
            :symbol,
            :trade_type,
            :volume,
            :open_price,
            :close_price,
            :profit,
            :commission,
            :swap,
            :open_time,
            :close_time,
            :status,
            :magic_number,
            :comment
          ],
          withdrawals: [
            :transaction_id,
            :amount,
            :transaction_date,
            :description
          ],
          deposits: [
            :transaction_id,
            :amount,
            :transaction_date,
            :description
          ]
        )
      end

      def sync_trades(mt5_account, trades_data)
        trades_data.each do |trade_data|
          Trade.create_or_update_from_mt5(mt5_account, trade_data.to_h.symbolize_keys)
        end
      end

      def sync_open_positions(mt5_account, open_positions_data)
        open_positions_data.each do |position_data|
          Trade.create_or_update_from_mt5(mt5_account, position_data.to_h.symbolize_keys)
        end
      end

      def sync_withdrawals(mt5_account, withdrawals_data)
        withdrawals_data.each do |withdrawal_data|
          withdrawal = mt5_account.withdrawals.find_or_initialize_by(
            transaction_id: withdrawal_data[:transaction_id]
          )
          
          withdrawal.assign_attributes(
            amount: withdrawal_data[:amount].to_f,
            withdrawal_date: DateTime.parse(withdrawal_data[:transaction_date]),
            notes: withdrawal_data[:description]
          )
          
          withdrawal.save! if withdrawal.changed?
        end
      end

      def sync_deposits(mt5_account, deposits_data)
        deposits_data.each do |deposit_data|
          deposit = mt5_account.deposits.find_or_initialize_by(
            transaction_id: deposit_data[:transaction_id]
          )
          
          deposit.assign_attributes(
            amount: deposit_data[:amount].to_f,
            deposit_date: DateTime.parse(deposit_data[:transaction_date]),
            notes: deposit_data[:description]
          )
          
          deposit.save! if deposit.changed?
        end
      end

      def detect_withdrawal(mt5_account, old_balance, new_balance)
        return if mt5_account.new_record?
        return if old_balance >= new_balance

        balance_decrease = old_balance - new_balance
        return if balance_decrease <= 0

        recent_losses = mt5_account.trades
          .where("close_time >= ?", 1.hour.ago)
          .where("profit < ?", 0)
          .sum(:profit)
          .abs

        if balance_decrease > (recent_losses + 10)
          Withdrawal.create!(
            mt5_account: mt5_account,
            amount: balance_decrease,
            withdrawal_date: Time.current
          )
        end
      end
      
      def sync_bot_performances(user)
        user.bot_purchases.each do |purchase|
          purchase.sync_performance_from_trades
        end
      end
    end
  end
end

