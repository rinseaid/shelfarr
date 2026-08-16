# frozen_string_literal: true

module Admin
  module Users
    class BookAccessController < BaseController
      before_action :set_user

      def create
        book = Book.find(params[:book_id])
        rule = @user.book_access_rules.find_or_create_by!(book: book)
        rule.update!(granted_by: Current.user) if rule.granted_by_id.nil?
        redirect_to admin_user_path(@user), notice: "Access granted"
      end

      def destroy
        @user.book_access_rules.find_by!(book_id: params[:id]).destroy!
        redirect_to admin_user_path(@user), notice: "Access revoked"
      end

      private

      def set_user
        @user = User.find(params[:user_id])
      end
    end
  end
end
