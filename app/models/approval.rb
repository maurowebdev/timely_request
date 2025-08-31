class Approval < ApplicationRecord
  belongs_to :time_off_request
  belongs_to :approver, class_name: 'User'
end
