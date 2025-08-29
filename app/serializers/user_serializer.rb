# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  attributes :email

  belongs_to :department
  belongs_to :manager, record_type: :user
end
