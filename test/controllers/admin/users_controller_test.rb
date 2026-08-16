# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:two)
    @user = users(:one)
    sign_in_as(@admin)
  end

  test "index requires admin" do
    sign_out
    sign_in_as(@user)

    get admin_users_url

    assert_redirected_to root_path
    assert_equal "You must be an admin to access this area.", flash[:alert]
  end

  test "index lists active users" do
    get admin_users_url

    assert_response :success
    assert_select "h1", "Users"
    assert_select "td", @admin.username
    assert_select "td", @user.username
  end

  test "show displays user details" do
    get admin_user_url(@user)

    assert_response :success
    assert_select "h1", @user.name
    assert_select "dd", @user.username
    assert_select "span", @user.role.titleize
    assert_select "a[href='#{edit_admin_user_path(@user)}']", "Edit"
  end

  test "new renders form" do
    get new_admin_user_url

    assert_response :success
    assert_select "form[action='#{admin_users_path}']"
  end

  test "create persists valid user" do
    assert_difference -> { User.count } do
      post admin_users_url, params: {
        user: {
          name: "Reader Three",
          username: "reader_three",
          password: "Password123!",
          password_confirmation: "Password123!",
          role: "user"
        }
      }
    end

    assert_redirected_to admin_users_path
    assert_equal "User was successfully created.", flash[:notice]
    assert User.find_by(username: "reader_three").user?
  end

  test "create renders errors for invalid user" do
    assert_no_difference -> { User.count } do
      post admin_users_url, params: {
        user: {
          name: "",
          username: "invalid user",
          password: "short",
          password_confirmation: "short",
          role: "user"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action='#{admin_users_path}']"
  end

  test "edit renders form" do
    get edit_admin_user_url(@user)

    assert_response :success
    assert_select "form[action='#{admin_user_path(@user)}']"
  end

  test "update ignores blank password" do
    patch admin_user_url(@user), params: {
      user: {
        name: "Renamed User",
        username: @user.username,
        password: "",
        password_confirmation: "",
        role: "admin"
      }
    }

    assert_redirected_to admin_users_path
    assert_equal "Renamed User", @user.reload.name
    assert @user.admin?
    assert @user.authenticate("Password123!")
  end

  test "update renders errors for invalid data" do
    patch admin_user_url(@user), params: {
      user: {
        name: "",
        username: "bad username",
        role: "user"
      }
    }

    assert_response :unprocessable_entity
    assert_select "form[action='#{admin_user_path(@user)}']"
  end

  test "destroy soft deletes another user" do
    assert_no_difference -> { User.count } do
      delete admin_user_url(@user)
    end

    assert_redirected_to admin_users_path
    assert_equal "User was successfully deleted.", flash[:notice]
    assert @user.reload.deleted_at.present?
  end

  test "destroy refuses current user" do
    delete admin_user_url(@admin)

    assert_redirected_to admin_users_path
    assert_equal "You cannot delete yourself.", flash[:alert]
    assert_nil @admin.reload.deleted_at
  end

  test "admin grants book access from the admin UI" do
    book = Book.create!(title: "UI Grant", book_type: :ebook)
    user = users(:one)
    post admin_user_book_access_index_path(user_id: user.id), params: { book_id: book.id }
    assert_redirected_to admin_user_path(user)
    assert BookAccessRule.exists?(user: user, book: book)
  end

  test "admin revokes book access from the admin UI" do
    book = Book.create!(title: "UI Revoke", book_type: :ebook)
    user = users(:one)
    BookAccessRule.create!(user: user, book: book)
    delete admin_user_book_access_path(user_id: user.id, id: book.id)
    assert_redirected_to admin_user_path(user)
    assert_not BookAccessRule.exists?(user: user, book: book)
  end
end
