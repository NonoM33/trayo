module IconHelper
  # Icônes pour la navigation principale
  NAVIGATION_ICONS = {
    dashboard: 'fa-chart-line',
    profile: 'fa-user',
    shop: 'fa-shopping-cart',
    my_bots: 'fa-robot',
    my_trades: 'fa-chart-bar',
    bonus_program: 'fa-gift',
    my_vps: 'fa-desktop',
    clients: 'fa-users',
    payments: 'fa-credit-card',
    withdrawals: 'fa-money-bill-wave',
    deposits: 'fa-plus-circle',
    mt5_tokens: 'fa-key',
    trades: 'fa-exchange-alt',
    campaigns: 'fa-bullhorn',
    maintenance: 'fa-screwdriver-wrench'
  }.freeze

  # Icônes pour les statistiques et métriques
  STATS_ICONS = {
    profit: 'fa-chart-line',
    loss: 'fa-chart-line-down',
    trades: 'fa-exchange-alt',
    balance: 'fa-wallet',
    commission: 'fa-percent',
    drawdown: 'fa-arrow-down',
    win_rate: 'fa-trophy',
    volume: 'fa-chart-area',
    symbols: 'fa-coins',
    bots: 'fa-robot',
    users: 'fa-users',
    accounts: 'fa-id-card',
    performance: 'fa-star',
    projection: 'fa-crystal-ball',
    monthly: 'fa-calendar-days',
    yearly: 'fa-calendar',
    total: 'fa-calculator',
    average: 'fa-chart-pie',
    max: 'fa-arrow-up',
    min: 'fa-arrow-down'
  }.freeze

  # Icônes pour les actions et boutons
  ACTION_ICONS = {
    edit: 'fa-pen-to-square',
    delete: 'fa-trash',
    view: 'fa-eye',
    add: 'fa-plus',
    save: 'fa-floppy-disk',
    cancel: 'fa-xmark',
    refresh: 'fa-arrows-rotate',
    download: 'fa-download',
    upload: 'fa-upload',
    search: 'fa-magnifying-glass',
    filter: 'fa-filter',
    sort: 'fa-sort',
    export: 'fa-file-export',
    import: 'fa-file-import',
    generate: 'fa-wand-magic-sparkles',
    copy: 'fa-copy',
    share: 'fa-share',
    print: 'fa-print',
    send: 'fa-paper-plane',
    receive: 'fa-inbox',
    approve: 'fa-check',
    reject: 'fa-xmark',
    activate: 'fa-power-off',
    deactivate: 'fa-ban',
    enable: 'fa-toggle-on',
    disable: 'fa-toggle-off'
  }.freeze

  # Icônes pour les statuts
  STATUS_ICONS = {
    active: 'fa-circle',
    inactive: 'fa-circle',
    pending: 'fa-clock',
    completed: 'fa-circle-check',
    failed: 'fa-circle-xmark',
    success: 'fa-circle-check',
    error: 'fa-circle-exclamation',
    warning: 'fa-triangle-exclamation',
    info: 'fa-circle-info',
    loading: 'fa-spinner',
    online: 'fa-wifi',
    offline: 'fa-wifi-slash',
    connected: 'fa-link',
    disconnected: 'fa-unlink',
    enabled: 'fa-toggle-on',
    disabled: 'fa-toggle-off',
    open: 'fa-unlock',
    closed: 'fa-lock',
    public: 'fa-globe',
    private: 'fa-lock'
  }.freeze

  # Icônes pour les types de trades
  TRADE_ICONS = {
    buy: 'fa-arrow-up',
    sell: 'fa-arrow-down',
    long: 'fa-arrow-up',
    short: 'fa-arrow-down',
    open: 'fa-play',
    close: 'fa-stop',
    pending: 'fa-clock',
    executed: 'fa-check',
    cancelled: 'fa-xmark',
    gold: 'fa-coins',
    oil: 'fa-oil-can',
    forex: 'fa-exchange-alt',
    crypto: 'fa-bitcoin',
    stock: 'fa-chart-line',
    index: 'fa-chart-area'
  }.freeze

  # Méthode principale pour obtenir une icône
  def icon(name, type: :navigation, size: 'md', color: nil, css_class: nil)
    Rails.logger.info "=== ICON HELPER DEBUG ==="
    Rails.logger.info "Icon name: #{name}"
    Rails.logger.info "Type: #{type}"
    Rails.logger.info "Size: #{size}"
    Rails.logger.info "Color: #{color}"
    Rails.logger.info "CSS class: #{css_class}"
    
    icon_map = case type
               when :navigation then NAVIGATION_ICONS
               when :stats then STATS_ICONS
               when :action then ACTION_ICONS
               when :status then STATUS_ICONS
               when :trade then TRADE_ICONS
               else NAVIGATION_ICONS
               end

    icon_class = icon_map[name.to_sym] || 'fa-question-circle'
    Rails.logger.info "Icon class found: #{icon_class}"
    
    size_class = case size
                 when 'xs' then 'fa-xs'
                 when 'sm' then 'fa-sm'
                 when 'md' then 'fa-md'
                 when 'lg' then 'fa-lg'
                 when 'xl' then 'fa-xl'
                 else 'fa-md'
                 end

    css_classes = ["fa-solid", icon_class, size_class]
    css_classes << "text-#{color}" if color
    css_classes << css_class if css_class
    
    Rails.logger.info "Final CSS classes: #{css_classes.join(' ')}"
    Rails.logger.info "=== END ICON HELPER DEBUG ==="

    content_tag(:i, '', class: css_classes.join(' '))
  end

  # Méthodes de convenance pour les types courants
  def nav_icon(name, **options)
    icon(name, type: :navigation, css_class: 'sidebar-menu-icon', **options)
  end

  def stat_icon(name, **options)
    icon(name, type: :stats, **options)
  end

  def action_icon(name, **options)
    icon(name, type: :action, **options)
  end

  def status_icon(name, **options)
    icon(name, type: :status, **options)
  end

  def trade_icon(name, **options)
    icon(name, type: :trade, **options)
  end

  # Méthodes spécialisées pour les éléments courants
  def profit_icon(amount)
    amount > 0 ? stat_icon(:profit, color: 'success') : stat_icon(:loss, color: 'danger')
  end

  def trade_type_icon(trade_type)
    case trade_type&.upcase
    when 'BUY' then trade_icon(:buy, color: 'success')
    when 'SELL' then trade_icon(:sell, color: 'danger')
    else trade_icon(:pending, color: 'warning')
    end
  end

  def status_badge_icon(status)
    case status&.downcase
    when 'active', 'success', 'completed' then status_icon(:success, color: 'success')
    when 'inactive', 'failed', 'error' then status_icon(:error, color: 'danger')
    when 'pending' then status_icon(:pending, color: 'warning')
    else status_icon(:info, color: 'info')
    end
  end

  # Méthode pour créer un élément avec icône et texte
  def icon_text(icon_name, text, type: :navigation, **options)
    content_tag(:span, class: 'icon-text') do
      icon(icon_name, type: type, **options) + content_tag(:span, text, class: 'icon-text-label')
    end
  end

  # Méthode pour créer un bouton avec icône
  def icon_button(icon_name, text = nil, url: '#', type: :action, **options)
    link_to url, class: "btn btn-icon #{options[:class]}" do
      content = icon(icon_name, type: type, **options)
      content += content_tag(:span, text) if text
      content
    end
  end
end
