class Page < ActiveRecord::Base
  validates :title, :slug, :body, presence: true
end
