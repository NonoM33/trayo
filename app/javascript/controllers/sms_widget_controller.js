import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "typeLabel", "typeInput", "messageArea", "charCount", "preview", "sendButton"]

  static templates = {
    relance_commission: {
      label: "📢 Relance Commission",
      message: "TRAYO: Bonjour {prenom}, votre commission de {commission}€ est en attente de règlement. Merci de régulariser votre situation."
    },
    rappel_paiement: {
      label: "💰 Rappel Paiement",
      message: "TRAYO: Bonjour {prenom}, un paiement de {commission}€ est en attente sur votre compte. Réglez-le pour éviter la suspension de vos bots."
    },
    promotion: {
      label: "🎉 Promotion",
      message: "TRAYO: Offre exclusive! Profitez de -20% sur votre prochain bot. Code: PROMO20. Valable 48h."
    },
    activation_bot: {
      label: "🤖 Activation Bot",
      message: "TRAYO: Bonjour {prenom}, votre bot est maintenant actif! Solde actuel: {solde}€. Bon trading!"
    },
    alerte_compte: {
      label: "⚠️ Alerte Compte",
      message: "TRAYO: Attention {prenom}, une action est requise sur votre compte. Connectez-vous pour plus de détails."
    },
    performance: {
      label: "📊 Performance",
      message: "TRAYO: Bonjour {prenom}! Votre performance ce mois: +{solde}€. Continuez comme ça! 🚀"
    },
    maintenance: {
      label: "🔧 Maintenance",
      message: "TRAYO: Maintenance prévue ce soir de 23h à 2h. Vos bots seront temporairement suspendus. Merci de votre compréhension."
    },
    bienvenue: {
      label: "✨ Bienvenue",
      message: "TRAYO: Bienvenue {prenom}! Votre compte est prêt. Vos bots vont commencer à trader. L'équipe TRAYO."
    },
    personnalise: {
      label: "📝 Personnalisé",
      message: ""
    }
  }

  connect() {
    this.updateCharCount()
  }

  typeChanged(event) {
    const type = event.target.value
    
    if (type && this.constructor.templates[type]) {
      const template = this.constructor.templates[type]
      
      if (this.hasTypeLabelTarget) {
        this.typeLabelTarget.textContent = template.label
      }
      if (this.hasTypeInputTarget) {
        this.typeInputTarget.value = type
      }
      if (this.hasMessageAreaTarget) {
        this.messageAreaTarget.value = template.message
        this.updateCharCount()
        this.updatePreview()
      }
      if (this.hasSendButtonTarget) {
        this.sendButtonTarget.disabled = false
      }
    } else {
      if (this.hasSendButtonTarget) {
        this.sendButtonTarget.disabled = true
      }
    }
  }

  updateCharCount() {
    if (this.hasMessageAreaTarget && this.hasCharCountTarget) {
      const count = this.messageAreaTarget.value.length
      this.charCountTarget.textContent = count
      
      if (count > 160) {
        this.charCountTarget.classList.add('text-amber-400')
      } else {
        this.charCountTarget.classList.remove('text-amber-400')
      }
    }
  }

  updatePreview() {
    if (this.hasMessageAreaTarget && this.hasPreviewTarget) {
      let message = this.messageAreaTarget.value
      
      // Replace variables with actual values from data attributes
      const clientData = this.element.dataset
      message = message.replace(/{prenom}/g, clientData.clientFirstname || '{prenom}')
      message = message.replace(/{nom}/g, clientData.clientLastname || '{nom}')
      message = message.replace(/{solde}/g, clientData.clientBalance || '{solde}')
      message = message.replace(/{commission}/g, clientData.clientCommission || '{commission}')
      
      this.previewTarget.textContent = message || 'Le message apparaîtra ici...'
    }
  }

  messageChanged() {
    this.updateCharCount()
    this.updatePreview()
  }
}

