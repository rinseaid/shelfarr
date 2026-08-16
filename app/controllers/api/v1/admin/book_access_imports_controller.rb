# frozen_string_literal: true

module API
  module V1
    module Admin
      class BookAccessImportsController < API::V1::ApplicationController
        before_action :ensure_admin

        def create
          entries = params.permit(rules: [ :username, :work_id, :book_type ])
            .to_h[:rules].to_a
            .map(&:symbolize_keys)
          result = BookAccessImportService.call(entries: entries, granted_by: Current.api_user)
          render json: { imported: result[:imported], errors: result[:errors] }, status: :created
        end

        private

        def ensure_admin
          head :forbidden unless Current.api_admin?
        end
      end
    end
  end
end
