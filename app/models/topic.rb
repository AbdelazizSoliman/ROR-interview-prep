class Topic < ApplicationRecord
  has_many :questions, -> { order(:position, :id) }, dependent: :restrict_with_exception

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  attr_readonly :slug

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }
end
