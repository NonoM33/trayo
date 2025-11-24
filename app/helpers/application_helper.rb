module ApplicationHelper
  def format_duration(total_minutes)
    return "<span style='color: var(--text-muted);'>-</span>".html_safe if total_minutes.nil? || total_minutes == 0
    
    total_minutes = total_minutes.to_f
    
    if total_minutes >= 1440
      days = (total_minutes / 1440.0).round(1)
      "#{days} #{days > 1 ? 'jours' : 'jour'}"
    elsif total_minutes >= 60
      hours = (total_minutes / 60.0).round(1)
      "#{hours}h"
    else
      "#{total_minutes.round(0)} min"
    end
  end
  
  def format_duration_from_hours(hours)
    return "<span style='color: var(--text-muted);'>-</span>".html_safe if hours.nil? || hours == 0
    
    hours = hours.to_f
    
    if hours >= 24
      days = hours.round(1)
      "#{days} #{days > 1 ? 'jours' : 'jour'}"
    end
  end
  
  def format_cost_with_sign(amount)
    return "0,00 €" if amount.nil? || amount == 0
    
    if amount > 0
      "+#{number_to_currency(amount, unit: "€", format: "%n %u")}"
    else
      number_to_currency(amount, unit: "€", format: "%n %u")
    end
  end
  
  def svg_tag(name, size: "24", **options)
    svgs = {
      'arrow-up-right' => '<path d="M7 17L17 7M17 7H7M17 7V17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
      'wallet' => '<path d="M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/><path d="M9 12H15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M12 9L12 15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
      'trending-up' => '<path d="M3 17L9 11L13 15L21 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/><path d="M21 7H15V13" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
      'percent' => '<path d="M19 5L5 19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M8 7C8 8.65685 6.65685 10 5 10C3.34315 10 2 8.65685 2 7C2 5.34315 3.34315 4 5 4C6.65685 4 8 5.34315 8 7Z" fill="currentColor"/><path d="M22 17C22 18.6569 20.6569 20 19 20C17.3431 20 16 18.6569 16 17C16 15.3431 17.3431 14 19 14C20.6569 14 22 15.3431 22 17Z" fill="currentColor"/>',
      'alert-circle' => '<path d="M12 8V12M12 16H12.01M22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none"/>',
      'layers' => '<path d="M12 2L3 7L12 12L21 7L12 2Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round" fill="none"/><path d="M3 17L12 22L21 17" stroke="currentColor" stroke-width="2" stroke-linejoin="round" fill="none"/><path d="M3 12L12 17L21 12" stroke="currentColor" stroke-width="2" stroke-linejoin="round" fill="none"/>',
      'bar-chart' => '<path d="M3 3V21H21" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M7 17L7 13M12 17L12 8M17 17L17 10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
      'calendar' => '<path d="M3 10H21M7 3V7M17 3V7M7 15H17M10 18H14M3 7H21C22.1046 7 23 7.89543 23 9V19C23 20.1046 22.1046 21 21 21H3C1.89543 21 1 20.1046 1 19V9C1 7.89543 1.89543 7 3 7Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none"/>',
      'robot' => '<path d="M12 2C8.68629 2 6 4.68629 6 8V16C6 19.3137 8.68629 22 12 22C15.3137 22 18 19.3137 18 16V8C18 4.68629 15.3137 2 12 2Z" stroke="currentColor" stroke-width="2" fill="none"/><circle cx="9" cy="12" r="1" fill="currentColor"/><circle cx="15" cy="12" r="1" fill="currentColor"/><path d="M9 16C9 17.1046 10.3431 18 12 18C13.6569 18 15 17.1046 15 16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
      'user' => '<circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="2" fill="none"/><path d="M20 20C20 16.6863 16.3137 14 12 14C7.68629 14 4 16.6863 4 20" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
      'activity' => '<path d="M22 12H18L15 21L9 3L6 12H2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
      'clock' => '<circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none"/><path d="M12 6V12L16 14" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
      'target' => '<circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none"/><circle cx="12" cy="12" r="6" stroke="currentColor" stroke-width="2" fill="none"/><circle cx="12" cy="12" r="2" fill="currentColor"/>'
    }
    
    svg = svgs[name.to_s] || svgs['user']
    width = size
    height = size
    
    content_tag(:svg, svg.html_safe, { width: width, height: height, viewBox: "0 0 24 24", fill: "none", xmlns: "http://www.w3.org/2000/svg" }.merge(options))
  end
  
  def humanize_error_message(message)
    translations = {
      /api.*key.*error/i => "Connexion impossible avec votre plateforme. Vérifiez votre clé API dans les paramètres.",
      /connection.*failed/i => "La connexion au serveur a échoué. Vérifiez votre connexion internet.",
      /timeout/i => "La requête a pris trop de temps. Veuillez réessayer.",
      /not found/i => "La ressource demandée est introuvable.",
      /unauthorized/i => "Vous n'avez pas les permissions nécessaires pour effectuer cette action.",
      /validation failed/i => "Certaines informations sont incorrectes. Veuillez vérifier les champs en erreur.",
      /can't be blank/i => "Ce champ est obligatoire.",
      /has already been taken/i => "Cette valeur est déjà utilisée. Veuillez en choisir une autre.",
      /is invalid/i => "Cette valeur n'est pas valide.",
      /too short/i => "Cette valeur est trop courte.",
      /too long/i => "Cette valeur est trop longue.",
      /must be greater than/i => "Cette valeur doit être supérieure.",
      /must be less than/i => "Cette valeur doit être inférieure.",
      /email/i => "L'adresse email n'est pas valide.",
      /password/i => "Le mot de passe ne respecte pas les critères requis.",
      /commission/i => "Le taux de commission doit être entre 0 et 100%."
    }
    
    translations.each do |pattern, translation|
      return translation if message.match?(pattern)
    end
    
    message
  end
  
  def friendly_error_messages(errors)
    return [] if errors.empty?
    
    errors.full_messages.map { |msg| humanize_error_message(msg) }
  end
end
