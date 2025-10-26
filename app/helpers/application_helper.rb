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
    else
      "#{hours.round(1)}h"
    end
  end
end
