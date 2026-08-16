# frozen_string_literal: true

# A per-user grant to see and request a specific book (work + format).
class BookAccessRule < ApplicationRecord
  belongs_to :user
  belongs_to :book
  belongs_to :granted_by, class_name: "User", optional: true
end
