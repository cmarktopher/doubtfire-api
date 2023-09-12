class AddFieldsToTaskDefinitions < ActiveRecord::Migration[7.0]
  def change
    add_column :task_definitions, :has_test, :boolean, default: false
    add_column :task_definitions, :restrict_attempts, :boolean, default: false
    add_column :task_definitions, :delay_restart_minutes, :integer
    add_column :task_definitions, :retake_on_resubmit, :boolean, default: false
  end
end
