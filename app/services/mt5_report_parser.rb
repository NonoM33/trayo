require 'roo'

class Mt5ReportParser
  def self.parse(file_path)
    return nil unless File.exist?(file_path)
    
    Rails.logger.info "=" * 80
    Rails.logger.info "📊 PARSING FICHIER EXCEL MT5: #{file_path}"
    Rails.logger.info "=" * 80
    
    begin
      xlsx = Roo::Spreadsheet.open(file_path)
      data = initialize_data
      
      sheet = xlsx.sheet(0)
      Rails.logger.info "Feuille trouvée: #{sheet.last_row} lignes"
      
      # Parcourir toutes les lignes
      (1..sheet.last_row).each do |row_num|
        row = sheet.row(row_num)
        
        # Chercher des patterns dans chaque cellule
        row.each_with_index do |cell, idx|
          next if cell.nil?
          
          cell_str = cell.to_s.strip
          
          # Extraire les dates
          if cell_str.match?(/\d{4}\.\d{2}\.\d{2}/) && !data[:start_date]
            dates = cell_str.scan(/(\d{4})\.(\d{2})\.(\d{2})/)
            if dates.length >= 2
              data[:start_date] = parse_date(dates[0])
              data[:end_date] = parse_date(dates[1])
              Rails.logger.info "📅 Dates extraites: #{data[:start_date]} - #{data[:end_date]}"
            end
          end
          
          # Extraire Profit Total Net - colonne 3
          if cell_str == "Profit Total Net:" && row[3]
            profit_value = extract_number(row[3])
            if profit_value != 0
              data[:total_profit] = profit_value
              Rails.logger.info "💰 Profit Total Net: #{profit_value}"
            end
          end
          
          # Extraire Profit brut - colonne 3
          if cell_str == "Profit brut:" && row[3]
            profit_value = extract_number(row[3])
            if profit_value != 0
              data[:gross_profit] = profit_value
              Rails.logger.info "✅ Profit brut: #{profit_value}"
            end
          end
          
          # Extraire Perte brut - colonne 3
          if cell_str == "Perte brut:" && row[3]
            loss_value = extract_number(row[3])
            if loss_value != 0
              data[:gross_loss] = loss_value.abs
              Rails.logger.info "❌ Perte brute: #{loss_value.abs}"
            end
          end
          
          # Extraire Drawdown Maximal - colonne 11
          if cell_str == "Fond Drawdown Maximal:" && row[11]
            drawdown_str = row[11].to_s
            # Extraire le nombre avant les parenthèses
            match = drawdown_str.match(/^([\d\s\.\,]+)/)
            if match
              data[:max_drawdown] = extract_number(match[1])
              Rails.logger.info "📉 Drawdown Max: #{data[:max_drawdown]}"
            end
          end
          
          # Extraire Nombre de trades - colonne 3
          if cell_str == "Nb trades:" && row[3]
            trades_count = extract_number(row[3])
            if trades_count > 0
              data[:total_trades] = trades_count.to_i
              Rails.logger.info "🎯 Total Trades: #{data[:total_trades]}"
            end
          end
          
          # Extraire Positions gagnantes - colonne 7
          if cell_str == "Positions gagnantes (% du total):" && row[7]
            matches = row[7].to_s.match(/^(\d+)/)
            if matches
              data[:winning_trades] = matches[1].to_i
              Rails.logger.info "🟢 Trades gagnants: #{data[:winning_trades]}"
            end
          end
          
          # Extraire Positions perdantes - colonne 11
          if cell_str == "Positions perdantes (% du total):" && row[11]
            matches = row[11].to_s.match(/^(\d+)/)
            if matches
              data[:losing_trades] = matches[1].to_i
              Rails.logger.info "🔴 Trades perdants: #{data[:losing_trades]}"
            end
          end
        end
      end
      
      # Calculer win_rate si on a les données
      if data[:winning_trades] && data[:total_trades] && data[:total_trades] > 0
        data[:win_rate] = (data[:winning_trades].to_f / data[:total_trades] * 100).round(2)
      end
      
      # Calculer average_profit
      if data[:total_profit] && data[:total_trades] && data[:total_trades] > 0
        data[:average_profit] = (data[:total_profit] / data[:total_trades]).round(2)
      end
      
      # Calculer losing_trades si pas trouvé
      if data[:winning_trades] && data[:total_trades] && !data[:losing_trades]
        data[:losing_trades] = data[:total_trades] - data[:winning_trades]
      end
      
      xlsx.close
      
      Rails.logger.info "=" * 80
      Rails.logger.info "📊 RÉSULTAT DU PARSING:"
      Rails.logger.info "=" * 80
      Rails.logger.info "Dates: #{data[:start_date]} → #{data[:end_date]}"
      Rails.logger.info "Trades: Total=#{data[:total_trades]}, Gagnants=#{data[:winning_trades]}, Perdants=#{data[:losing_trades]}"
      Rails.logger.info "Profit Total: #{data[:total_profit]}"
      Rails.logger.info "Drawdown: #{data[:max_drawdown]}"
      Rails.logger.info "Win Rate: #{data[:win_rate]}%"
      Rails.logger.info "=" * 80
      
      data
    rescue => e
      Rails.logger.error "Erreur parsing Excel: #{e.message}"
      nil
    end
  end
  
  private
  
  def self.initialize_data
    {
      start_date: nil,
      end_date: nil,
      total_trades: nil,
      winning_trades: nil,
      losing_trades: nil,
      total_profit: nil,
      gross_profit: nil,
      gross_loss: nil,
      max_drawdown: nil,
      win_rate: nil,
      average_profit: nil
    }
  end
  
  def self.parse_date(date_array)
    return nil unless date_array && date_array.length == 3
    
    year = date_array[0].to_i
    month = date_array[1].to_i
    day = date_array[2].to_i
    
    Date.new(year, month, day)
  rescue
    nil
  end
  
  def self.extract_number(cell_value)
    return 0 if cell_value.nil?
    
    cell_str = cell_value.to_s.strip
      .gsub(/\s/, '')      # Enlever espaces
      .gsub(',', '.')      # Remplacer virgule par point
      .gsub(/[^\d.-]/, '') # Garder seulement chiffres et décimales
    
    cell_str.to_f
  rescue
    0
  end
end
