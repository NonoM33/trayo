class VpsOffer < ApplicationRecord
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, price: :asc) }

  def specs_list
    return [] if specs.blank?
    specs.split(',').map(&:strip)
  end

  def formatted_price
    "#{price.to_i}€/an"
  end

  def self.seed_defaults!
    [
      { 
        name: "VPS Standard", 
        price: 399.99, 
        specs: "2 vCPU, 4GB RAM, 50GB SSD",
        description: "Parfait pour débuter avec 1-2 bots",
        position: 1
      },
      { 
        name: "VPS Pro", 
        price: 599.99, 
        specs: "4 vCPU, 8GB RAM, 100GB SSD",
        description: "Idéal pour 3-5 bots avec performances optimales",
        is_recommended: true,
        position: 2
      },
      { 
        name: "VPS Enterprise", 
        price: 999.99, 
        specs: "8 vCPU, 16GB RAM, 200GB SSD",
        description: "Pour les traders professionnels avec de nombreux bots",
        position: 3
      }
    ].each do |offer_data|
      find_or_create_by!(name: offer_data[:name]) do |offer|
        offer.assign_attributes(offer_data.merge(active: true))
      end
    end
  end
end
