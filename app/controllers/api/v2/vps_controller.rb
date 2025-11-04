module Api
  module V2
    class VpsController < BaseController
      before_action :set_vps, only: [:show]

      def index
        vps_list = current_user.vps
        paginated = paginate_with_cursor(vps_list, cursor_field: :id)

        render_success({
          data: paginated[:data].map { |v| vps_serializer(v) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ vps: vps_serializer(@vps) })
      end

      private

      def set_vps
        @vps = current_user.vps.find_by(id: params[:id])
        render_error("VPS not found", status: :not_found) unless @vps
      end

      def vps_serializer(vps)
        {
          id: vps.id,
          name: vps.name,
          server_location: vps.server_location,
          status: vps.status,
          monthly_price: vps.monthly_price,
          renewal_date: vps.renewal_date,
          ip_address: vps.ip_address,
          username: current_user.is_admin? ? vps.username : nil,
          password: current_user.is_admin? ? vps.password : nil,
          ordered_at: vps.ordered_at,
          configured_at: vps.configured_at,
          ready_at: vps.ready_at,
          activated_at: vps.activated_at,
          created_at: vps.created_at,
          updated_at: vps.updated_at
        }
      end
    end
  end
end

