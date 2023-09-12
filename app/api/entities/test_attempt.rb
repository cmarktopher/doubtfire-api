module Entities
  class SaveTest < Grape::Entity
    expose :id
    expose :name
    expose :attempt_number
    expose :pass_status
    expose :exam_data
    expose :completed
    expose :cmi_entry
    expose :task_id
  end
end
