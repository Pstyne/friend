class User < ApplicationRecord
  require "open-uri"
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  attr_accessor :full_name

  before_save :capitalize_name

  validates :first_name, :last_name, presence: true

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: %i[facebook]

  has_one_attached :avatar
  validates :avatar, content_type: true, size_range: true, unless: :creating_user?
  has_many :photos, dependent: :destroy
  has_many :posts, foreign_key: :author_id, dependent: :destroy
  has_many :notifications, foreign_key: :receiver_id, dependent: :destroy
  has_many :friend_requests, dependent: :destroy
  has_many :accepted_requests, -> { where accepted: true }, class_name: "FriendRequest", dependent: :destroy
  has_many :friends, through: :accepted_requests, source: :receiver
  has_many :comments, foreign_key: :user_id, dependent: :destroy

  def creating_user?
    new_record?
  end

  def full_name
    name = []
    name << first_name << last_name
    name.join(" ")
  end

  def capitalize_name
    self.first_name = first_name.capitalize
    self.last_name = last_name.capitalize
  end

  def self.from_omniauth(auth)
    user = User.find_by(uid: auth.uid)
    name = auth.info.name.split(" ")
    file = open(auth.info.image)
    if user.present?
      user.first_name = name[0]
      user.last_name = name[1]
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.avatar.attach(io: file, filename: "#{auth.uid}.#{file.meta["content-type"].split("/").last}", content_type: file.meta["content-type"])
      user.save
      user
    else
      user = User.new(provider: auth.provider, uid: auth.uid)
      user.first_name = name[0]
      user.last_name = name[1]
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.avatar.attach(io: file, filename: "#{auth.uid}.#{file.meta["content-type"].split("/").last}", content_type: file.meta["content-type"])
      user.save
      UserMailer.welcome_email(user).deliver
      user
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
end
