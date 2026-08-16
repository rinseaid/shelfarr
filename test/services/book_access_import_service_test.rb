# frozen_string_literal: true

require "test_helper"

class BookAccessImportServiceTest < ActiveSupport::TestCase
  test "imports a single rule by work_id and book_type" do
    book = Book.create!(title: "Import Me", book_type: :ebook, open_library_work_id: "OL_IMPORT_ME")
    user = users(:one)
    result = BookAccessImportService.call(entries: [ { username: user.username, work_id: "OL_IMPORT_ME", book_type: "ebook" } ])
    assert result[:imported] == 1
    assert BookAccessRule.exists?(user: user, book: book)
  end

  test "matches by alternate work id columns and book_type" do
    book = Book.create!(title: "Alt Match", book_type: :audiobook, google_books_id: "gb-import-alt")
    user = users(:one)
    result = BookAccessImportService.call(entries: [ { username: user.username, work_id: "google_books:gb-import-alt", book_type: "audiobook" } ])
    assert result[:imported] == 1
    assert result[:errors].empty?
    assert BookAccessRule.exists?(user: user, book: book)
  end

  test "reports errors for unmatched users or books" do
    user = users(:one)
    result = BookAccessImportService.call(
      entries: [
        { username: "nobody", work_id: "OL_IMPORT_ME", book_type: "ebook" },
        { username: user.username, work_id: "OL_NOPE", book_type: "ebook" }
      ]
    )
    assert result[:imported] == 0
    assert_equal 2, result[:errors].length
  end

  test "does not duplicate an existing rule on reimport" do
    book = Book.create!(title: "Reimport", book_type: :ebook, open_library_work_id: "OL_REIMPORT")
    user = users(:one)
    BookAccessRule.create!(user: user, book: book)
    result = BookAccessImportService.call(entries: [ { username: user.username, work_id: "OL_REIMPORT", book_type: "ebook" } ])
    assert result[:imported] == 1
    assert_equal 1, BookAccessRule.where(user: user, book: book).count
  end
end
