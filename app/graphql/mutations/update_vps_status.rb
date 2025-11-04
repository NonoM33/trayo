module Mutations
  class UpdateVpsStatus < BaseMutation
    description "Update VPS status (admin only)"

    argument :id, ID, required: true
    argument :status, String, required: true

    field :vps, Types::VpsType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(id:, status:)
      admin = context[:current_user]
      return { vps: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless admin&.is_admin?

      vps = Vps.find_by(id: id)
      return { vps: nil, errors: [{ field: "id", message: "VPS not found" }] } unless vps

      valid_statuses = %w[ordered configuring ready active suspended cancelled]
      unless valid_statuses.include?(status)
        return {
          vps: nil,
          errors: [{ field: "status", message: "Invalid status. Must be one of: #{valid_statuses.join(', ')}" }]
        }
      end

      vps.status = status
      vps.configured_at = Time.current if status == 'configuring'
      vps.ready_at = Time.current if status == 'ready'
      vps.activated_at = Time.current if status == 'active'

      if vps.save
        {
          vps: vps,
          errors: nil
        }
      else
        {
          vps: nil,
          errors: vps.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

