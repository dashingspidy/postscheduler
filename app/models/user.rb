class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :slideshow_imports, dependent: :destroy
  has_many :video_creations, dependent: :destroy
  has_many :projects, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
