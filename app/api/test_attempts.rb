require 'grape'

class SaveTestAPI < Grape::API
  format :json

  # Assigning AuthenticationHelpers
  helpers AuthenticationHelpers

  # Handle common exceptions
  rescue_from :all do |e|
    error!({ error: e.message }, 500)
  end
  # Specific exception handler for record not found
  rescue_from ActiveRecord::RecordNotFound do |e|
    error!({ error: e.message }, 404)
  end
  # Handling validation errors from Grape
  rescue_from Grape::Exceptions::ValidationErrors do |e|
    error!({ errors: e.full_messages }, 400)
  end
  # Helper method for rendering successful responses
  helpers do
    def render_success(data, with_entity)
      present :data, data, with: with_entity
    end
  end
  # Main resource for test operations
  resources :savetests do
    before do
      authenticated?
    end
    # Fetch all test results
    desc 'Get all test results'
    get do
      tests = TestAttempt.order(id: :desc)
      render_success(tests, Entities::SaveTest)
    end
    # Get latest test or create new one based on completion status
    get 'latest' do
      test = TestAttempt.order(id: :desc).first

      if test.nil?
        test = TestAttempt.create!(
          name: "Default Test",
          attempt_number: 1,
          pass_status: false,
          exam_data: nil,
          completed: false,
          cmi_entry: 'ab-initio',
          task_id: params[:task_id]
        )
      elsif test.completed
        test = TestAttempt.create!(
          name: "Default Test",
          attempt_number: test.attempt_number + 1,
          pass_status: false,
          exam_data: nil,
          completed: false,
          cmi_entry: 'ab-initio',
          task_id: params[:task_id]
        )
      else
        test.update!(cmi_entry: 'resume')
      end

      logger.debug "Test attributes after update: #{test.attributes.inspect}"
      present :data, test, with: Entities::SaveTest
    end
    # Fetch the latest completed test result
    desc 'Get the latest completed test result'
    get 'completed-latest' do
      test = TestAttempt.where(completed: true).order(id: :desc).first

      if test.nil?
        error!({ message: 'No completed tests found' }, 404)
      else
        render_success(test, Entities::SaveTest)
      end
    end
    # Fetch a specific test result by ID
    desc 'Get a specific test result'
    params do
      requires :id, type: String, desc: 'ID of the test'
    end
    get ':id' do
      present TestAttempt.find(params[:id]), with: Entities::SaveTest
    end
    # Create a new test result entry
    desc 'Create a new test result'
    params do
      requires :task_id, type: Integer, desc: 'ID of the associated task'
      requires :name, type: String, desc: 'Name of the test'
      requires :attempt_number, type: Integer, desc: 'Number of attempts'
      requires :pass_status, type: Boolean, desc: 'Passing status'
      optional :exam_data, type: String, desc: 'Data related to the exam'
      requires :completed, type: Boolean, desc: 'Completion status'
      optional :cmi_entry, type: String, desc: 'CMI Entry', default: "ab-initio"
      optional :exam_result, type: String, desc: 'Result of the exam'
      optional :attempted_at, type: DateTime, desc: 'Timestamp of the test attempt'
    end
    post do
      test = TestAttempt.create!(declared(params))
      render_success(test, Entities::SaveTest)
    end
    # Update the details of a specific test result
    desc 'Update a test result'
    params do
      optional :name, type: String, desc: 'Name of the test'
      optional :attempt_number, type: Integer, desc: 'Number of attempts'
      optional :pass_status, type: Boolean, desc: 'Passing status'
      optional :exam_data, type: String, desc: 'Data related to the exam'
      optional :completed, type: Boolean, desc: 'Completion status'
      optional :cmi_entry, type: String, desc: 'CMI Entry'
      optional :task_id, type: Integer, desc: 'ID of the associated task'
    end
    put ':id' do
      test = TestAttempt.find(params[:id])
      test.update!(declared(params, include_missing: false))
      render_success(test, Entities::SaveTest)
    end
    # Delete a specific test result by ID
    desc 'Delete a test result'
    params do
      requires :id, type: String, desc: 'ID of the test'
    end
    delete ':id' do
      TestAttempt.find(params[:id]).destroy!
    end
    # Update the exam_data of a specific test result
    desc 'Update exam data for a test result'
    params do
      requires :id, type: String, desc: 'ID of the test'
    end
    put ':id/exam_data' do
      test = TestAttempt.find_by(id: params[:id])

      error!('Test not found', 404) unless test

      # Treat the entire params as the data to be saved
      exam_data = params.to_json

      # Log the exact contents
      logger.debug "Raw exam_data: #{exam_data.inspect}"

      begin
        JSON.parse(exam_data)
        test.update!(exam_data: exam_data)
        { message: 'Exam data updated successfully', test: test }
      rescue JSON::ParserError
        error!('Invalid JSON provided', 400)
      rescue StandardError => e
        error!(e.message, 500)
      end
    end
  end
end
