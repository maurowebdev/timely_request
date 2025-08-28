class TimeOffRequest < ApplicationRecord
  belongs_to :user
  belongs_to :time_off_type
end
