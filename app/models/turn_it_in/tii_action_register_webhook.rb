# freeze_string_literal: true

# Fetch the eula version and html from turn it in
class TiiActionRegisterWebhook < TiiAction
  def description
    "Register webhooks"
  end

  private

  def run
    register_webhook if need_to_register_webhook?
  end

  def need_to_register_webhook?
    # Get all webhooks
    webhooks = list_all_webhooks

    # Check if we are registered
    webhooks.each do |webhook|
      return false if webhook.url == TurnItIn.webhook_url
    end

    # If we are not registered, return true
    true
  end

  def register_webhook
    data = TCAClient::WebhookWithSecret.new(
      signing_secret: ENV.fetch('TCA_SIGNING_KEY', nil),
      url: TurnItIn.webhook_url,
      event_types: %w[
        SIMILARITY_COMPLETE
        SUBMISSION_COMPLETE
        SIMILARITY_UPDATED
        PDF_STATUS
        GROUP_ATTACHMENT_COMPLETE
      ]
    ) # WebhookWithSecret |

    raise "TCA_SIGNING_KEY is not set" if data.signing_secret.nil?

    exec_tca_call 'register webhook' do
      TCAClient::WebhookApi.new.webhooks_post(
        TurnItIn.x_turnitin_integration_name,
        TurnItIn.x_turnitin_integration_version,
        data
      )
    end
  end

  # List all webhooks currently registered
  def list_all_webhooks
    exec_tca_call 'list all webhooks' do
      TCAClient::WebhookApi.new.webhooks_get(
        TurnItIn.x_turnitin_integration_name,
        TurnItIn.x_turnitin_integration_version
      )
    end
  end
end
