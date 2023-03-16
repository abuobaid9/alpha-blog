class Article < ApplicationRecord
    belongs_to :user
    has_many :article_categories
    has_many :categories, through: :article_categories
    validates :title, presence: true, length: { minimum: 6, maximum: 200 }
    validates :description, presence: true, length: { minimum: 10, maximum: 600 }
    
    filterrific(
      default_filter_params: { sorted_by: 'created_at_desc' },
      available_filters: [
        :sorted_by,
        :search_query,
        :with_category_id,
        :with_user_id
      ]
    )
    
    scope :sorted_by, ->(sort_option) {
      direction = sort_option =~ /desc$/ ? 'desc' : 'asc'
      case sort_option.to_s
      when /^created_at_/
        order("Articles.created_at #{direction}")
      when /^title_/
        order("Articles.title #{direction}")
      else
        raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
      end
    }
    
    scope :search_query, ->(query) {
      return nil if query.blank?
      terms = query.downcase.split(/\s+/)
      terms = terms.map { |e|
        ('%' + e.gsub('*', '%') + '%').gsub(/%+/, '%')
      }
      num_or_conds = 2
      where(
        terms.map { |term|
          "(LOWER(Articles.title) LIKE ? OR LOWER(Articles.description) LIKE ?)"
        }.join(' AND '),
        *terms.map { |e| [e] * num_or_conds }.flatten
      )
    }
    
    scope :with_category_id, ->(category_ids) {
      joins(:article_categories).where(article_categories: { category_id: [*category_ids] })
    }
    
    scope :with_user_id, ->(user_ids) {
      where(user_id: [*user_ids])
    }
    
    def self.options_for_sorted_by(sort_option = nil)
      [
        ['Article (A-Z)', 'title_asc'],
        ['Article (Z-A)', 'title_desc'],
        ['Created date (Newest first)', 'created_at_desc'],
        ['Created date (Oldest first)', 'created_at_asc']
      ]
    end

  end