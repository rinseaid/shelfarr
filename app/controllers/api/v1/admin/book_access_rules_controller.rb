# frozen_string_literal: true

module API
  module V1
    module Admin
      class BookAccessRulesController < API::V1::ApplicationController
        before_action :ensure_admin
        before_action :set_user

        def index
          rules = @user.book_access_rules.includes(:book).order(:created_at)
          render json: rules.map { |rule| { id: rule.id, book_id: rule.book_id, title: rule.book.title } }
        end

        def create
          book = Book.find(params[:book_id])
          rule = @user.book_access_rules.find_or_create_by!(book: book)
          rule.update!(granted_by: Current.api_user) if rule.granted_by_id.nil?
          render json: { id: rule.id, book_id: rule.book_id }, status: :created
        end

        def destroy
          @user.book_access_rules.find_by!(book_id: params[:book_id]).destroy!
          head :no_content
        end

        private

        def ensure_admin
          head :forbidden unless Current.api_admin?
        end

        def set_user
          @user = User.find(params[:user_id])
        end
      end
    end
  end
end
