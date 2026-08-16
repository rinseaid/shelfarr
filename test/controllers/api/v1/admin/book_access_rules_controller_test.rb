# frozen_string_literal: true

require "test_helper"

module API
  module V1
    module Admin
      class BookAccessRulesControllerTest < ActionDispatch::IntegrationTest
        setup do
          SettingsService.set(:api_token, "apitoken")
          @admin = users(:two)
          @user = users(:one)
          @book = Book.create!(title: "Rule Book", author: "Author", book_type: :ebook)
          @headers = { "Authorization" => "Bearer apitoken" }
        end

        test "grants book access to a user" do
          post api_v1_admin_user_book_access_index_path(user_id: @user.id),
            params: { book_id: @book.id }, headers: @headers
          assert_response :created
          assert BookAccessRule.exists?(user: @user, book: @book)
        end

        test "grants book access idempotently" do
          BookAccessRule.create!(user: @user, book: @book, granted_by: @admin)
          post api_v1_admin_user_book_access_index_path(user_id: @user.id),
            params: { book_id: @book.id }, headers: @headers
          assert_response :created
          assert_equal 1, BookAccessRule.where(user: @user, book: @book).count
        end

        test "lists book access rules for a user" do
          BookAccessRule.create!(user: @user, book: @book, granted_by: @admin)
          get api_v1_admin_user_book_access_index_path(user_id: @user.id), headers: @headers
          assert_response :ok
          body = JSON.parse(response.body)
          assert_equal 1, body.length
          assert_equal "Rule Book", body.first["title"]
        end

        test "revokes book access from a user" do
          BookAccessRule.create!(user: @user, book: @book, granted_by: @admin)
          delete api_v1_admin_user_book_access_path(user_id: @user.id, book_id: @book.id), headers: @headers
          assert_response :no_content
          assert_not BookAccessRule.exists?(user: @user, book: @book)
        end
      end
    end
  end
end
