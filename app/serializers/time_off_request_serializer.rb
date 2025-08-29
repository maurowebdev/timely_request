class TimeOffRequestSerializer
  include JSONAPI::Serializer

  attributes :start_date, :end_date, :reason, :status
end
