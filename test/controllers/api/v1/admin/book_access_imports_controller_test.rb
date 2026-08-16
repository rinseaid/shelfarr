# frozen_string_literal: true

require "test_helper"

module API
  module V1
    module Admin
      class BookAccessImportsControllerTest < ActionDispatch::IntegrationTest
        setup do
          SettingsService.set(:api_token, "apitoken")
          @user = users(:one)
          @book = Book.create!(title: "Import Book", book_type: :ebook, open_library_work_id: "OL_IMPORT_API")
          @headers = { "Authorization" => "Bearer apitoken" }
        end

        test "imports book access rules in bulk" do
          post api_v1_admin_book_access_import_path,
            params: { rules: [ { username: @user.username, work_id: "OL_IMPORT_API", book_type: "ebook" } ] },
            headers: @headers
          assert_response :created
          body = JSON.parse(response.body)
          assert_equal 1, body["imported"]
          assert_empty body["errors"]
          assert BookAccessRule.exists?(user: @user, book: @book)
        end

        test "reports import errors in bulk" do
          post api_v1_admin_book_access_import_path,
            params: { rules: [ { username: "nobody", work_id: "OL_IMPORT_API", book_type: "ebook" } ] },
            headers: @headers
          assert_response :created
          body = JSON.parse(response.body)
          assert_equal 0, body["imported"]
          assert_equal 1, body["errors"].length
        end
      end
    end
  end
end
