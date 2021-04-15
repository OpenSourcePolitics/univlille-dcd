# frozen_string_literal: true

module Decidim
  # A form object used to handle user registrations
  class RegistrationForm < Form
    mimic :user

    STATUSES = [
        { value: "student"},{ value: "teacher"},{ value: "personal"},{ value: "partner", hidden: true}
    ]

    attribute :name, String
    attribute :nickname, String
    attribute :email, String
    attribute :password, String
    attribute :password_confirmation, String
    attribute :newsletter, Boolean
    attribute :tos_agreement, Boolean
    attribute :current_locale, String
    attribute :status, String
    attribute :provenance, String

    validates :name, presence: true
    validates :status, :provenance, presence: true
    validates :nickname, presence: true, format: /\A[\w\-]+\z/, length: { maximum: Decidim::User.nickname_max_length }
    validates :email, presence: true, 'valid_email_2/email': { disposable: true }
    validates :password, confirmation: true
    validates :password, password: { name: :name, email: :email, username: :nickname }
    validates :password_confirmation, presence: true
    validates :tos_agreement, allow_nil: false, acceptance: true

    validate :email_unique_in_organization
    validate :nickname_unique_in_organization
    validate :no_pending_invitations_exist

    def newsletter_at
      return nil unless newsletter?

      Time.current
    end

    def statuses
      STATUSES
    end

    private

    def email_unique_in_organization
      errors.add :email, :taken if User.no_active_invitation.find_by(email: email, organization: current_organization).present?
    end

    def nickname_unique_in_organization
      errors.add :nickname, :taken if User.no_active_invitation.find_by(nickname: nickname, organization: current_organization).present?
    end

    def no_pending_invitations_exist
      errors.add :base, I18n.t("devise.failure.invited") if User.has_pending_invitations?(current_organization.id, email)
    end

    def in_restricted_list?(value)
      in_list = false
      STATUSES.each do |status|
        next if in_list

        in_list = true if status[:value] == value && status[:hidden]
      end

      in_list
    end
  end
end