class TimeOffRequestSerializer
  include JSONAPI::Serializer

  attributes :start_date, :end_date, :reason, :status, :created_at, :time_off_type_name, :user_name, :user_id, :manager_name, :manager_id

  attribute :time_off_type_name do |object|
    object.time_off_type.name
  end

  attribute :user_name do |object|
    object.user.name
  end

  attribute :user_id do |object|
    object.user.id
  end

  attribute :manager_name do |object|
    object.user.manager&.name
  end

  attribute :manager_id do |object|
    object.user.manager&.id
  end
end
