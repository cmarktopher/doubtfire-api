# frozen_string_literal: true

require 'grape'

RSpec.describe SaveTestAPI, type: :request do
  include TestHelpers::AuthHelper
  include TestHelpers::TestFileHelper

  # Constants
  let(:base_url) { "/savetests" }
  let(:test_attempt) { FactoryBot.create(:test_attempt) }

  # Authentication header helper
  def authenticated_header
    { "Authorization" => "YourAuthToken" }
  end

  # Test Suite for GET /savetests
  describe "GET /savetests" do
    before { FactoryBot.create_list(:test_attempt, 5) }

    it "returns all test results" do
      get base_url, headers: authenticated_header
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"].size).to eq(5)
    end
  end

  # Test Suite for GET /savetests/latest
  describe "GET /savetests/latest" do
    it "returns the latest test or creates a new one" do
      get "#{base_url}/latest", headers: authenticated_header
      expect(response).to have_http_status(:ok)
    end
  end

  # Test Suite for GET /savetests/completed-latest
  describe "GET /savetests/completed-latest" do
    context "when there are completed tests" do
      before { FactoryBot.create(:test_attempt, completed: true) }

      it "returns the latest completed test" do
        get "#{base_url}/completed-latest", headers: authenticated_header
        expect(response).to have_http_status(:ok)
      end
    end

    context "when there are no completed tests" do
      it "returns an error" do
        get "#{base_url}/completed-latest", headers: authenticated_header
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Test Suite for GET /savetests/:id
  describe "GET /savetests/:id" do
    it "returns the specified test result" do
      get "#{base_url}/#{test_attempt.id}", headers: authenticated_header
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(test_attempt.id)
    end
  end

  # Test Suite for POST /savetests
  describe "POST /savetests" do
    let(:valid_params) do
      {
        task_id: 1,
        name: "New Test",
        attempt_number: 1,
        pass_status: true,
        completed: false
      }
    end

    it "creates a new test result" do
      expect do
        post base_url, params: valid_params, headers: authenticated_header
      end.to change(TestAttempt, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  # Test Suite for PUT /savetests/:id
  describe "PUT /savetests/:id" do
    let(:valid_update_params) { { name: "Updated Test Name" } }

    it "updates a test result" do
      put "#{base_url}/#{test_attempt.id}", params: valid_update_params, headers: authenticated_header
      expect(response).to have_http_status(:ok)
      expect(test_attempt.reload.name).to eq("Updated Test Name")
    end
  end

  # Test Suite for DELETE /savetests/:id
  describe "DELETE /savetests/:id" do
    it "deletes a test result" do
      delete "#{base_url}/#{test_attempt.id}", headers: authenticated_header
      expect(response).to have_http_status(:ok)
      expect { test_attempt.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # Test Suite for PUT /savetests/:id/exam_data
  describe "PUT /savetests/:id/exam_data" do
    let(:valid_exam_data) { { exam_data: { question1: "answer", question2: "answer2" }.to_json } }

    it "updates exam data for a test result" do
      put "#{base_url}/#{test_attempt.id}/exam_data", params: valid_exam_data, headers: authenticated_header
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(test_attempt.reload.exam_data)).to eq(valid_exam_data[:exam_data])
    end
  end
end
