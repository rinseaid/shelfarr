# frozen_string_literal: true

# Bulk-imports per-user book access rules from (username, work_id, book_type)
# entries. Entries are matched by user username and by Book work-id lookup.
class BookAccessImportService
  def self.call(entries:, granted_by: nil)
    imported = 0
    errors = []
    Array(entries).each do |entry|
      user = User.active.find_by(username: entry[:username].to_s.strip)
      book = Book.find_by_work_id(entry[:work_id], book_type: entry[:book_type].to_s)
      if user.nil? || book.nil?
        errors << "no match for #{entry.inspect}"
        next
      end
      rule = BookAccessRule.find_or_create_by!(user: user, book: book)
      rule.update!(granted_by: granted_by) if rule.granted_by_id.nil?
      imported += 1
    rescue ActiveRecord::RecordInvalid => e
      errors << e.message
    end
    { imported: imported, errors: errors }
  end
end
