require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "validations" do
    subject { build(:invitation) }

    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
    
    it "validates email format when present" do
      invitation = build(:invitation, email: "invalid-email")
      expect(invitation).not_to be_valid
      
      invitation.email = "valid@email.com"
      expect(invitation).to be_valid
    end
  end

  describe "#is_valid?" do
    context "when pending and not expired" do
      let(:invitation) { create(:invitation, status: "pending", expires_at: 1.day.from_now) }

      it "returns true" do
        expect(invitation.is_valid?).to be true
      end
    end

    context "when completed" do
      let(:invitation) { create(:invitation, :completed) }

      it "returns false" do
        expect(invitation.is_valid?).to be false
      end
    end

    context "when expired" do
      let(:invitation) { create(:invitation, :expired) }

      it "returns false" do
        expect(invitation.is_valid?).to be false
      end
    end
  end

  describe "#complete!" do
    let(:invitation) { create(:invitation) }

    it "changes status to completed" do
      expect { invitation.complete! }.to change { invitation.status }.from("pending").to("completed")
    end
  end

  describe "#selected_bots_parsed" do
    context "with valid JSON array" do
      let(:invitation) { create(:invitation, selected_bots: '[1, 2, 3]') }

      it "returns parsed array" do
        expect(invitation.selected_bots_parsed).to eq([1, 2, 3])
      end
    end

    context "with nil" do
      let(:invitation) { create(:invitation, selected_bots: nil) }

      it "returns empty array" do
        expect(invitation.selected_bots_parsed).to eq([])
      end
    end

    context "with invalid JSON" do
      let(:invitation) { create(:invitation, selected_bots: "not valid json") }

      it "returns empty array" do
        expect(invitation.selected_bots_parsed).to eq([])
      end
    end
  end

  describe "#broker_data_parsed" do
    context "with valid JSON" do
      let(:invitation) { create(:invitation, :with_broker_data) }

      it "returns parsed hash" do
        result = invitation.broker_data_parsed
        expect(result).to be_a(Hash)
        expect(result["broker_name"]).to eq("IC Markets")
      end
    end

    context "with nil" do
      let(:invitation) { create(:invitation, broker_data: nil) }

      it "returns empty hash" do
        expect(invitation.broker_data_parsed).to eq({})
      end
    end
  end

  describe "#broker_credentials_parsed" do
    context "with valid JSON" do
      let(:invitation) { create(:invitation, :with_broker_data) }

      it "returns parsed hash with account details" do
        result = invitation.broker_credentials_parsed
        expect(result).to be_a(Hash)
        expect(result["account_id"]).to eq("123456789")
        expect(result["account_password"]).to eq("testpass123")
      end
    end
  end

  describe "#is_expired?" do
    it "returns true when expires_at is in the past" do
      invitation = create(:invitation, expires_at: 1.day.ago)
      expect(invitation.is_expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      invitation = create(:invitation, expires_at: 1.day.from_now)
      expect(invitation.is_expired?).to be false
    end
  end

  describe "#is_used?" do
    it "returns true when status is completed" do
      invitation = create(:invitation, :completed)
      expect(invitation.is_used?).to be true
    end

    it "returns true when used_at is set" do
      invitation = create(:invitation, used_at: Time.current)
      expect(invitation.is_used?).to be true
    end

    it "returns false when pending and not used" do
      invitation = create(:invitation)
      expect(invitation.is_used?).to be false
    end
  end

  describe ".generate_unique_code" do
    it "generates a unique code" do
      code = Invitation.generate_unique_code
      expect(code).to be_present
      expect(code.length).to eq(24)
    end

    it "generates different codes each time" do
      codes = 5.times.map { Invitation.generate_unique_code }
      expect(codes.uniq.length).to eq(5)
    end
  end
end
