require "fast_spec_helper"
require "lib/error_message_translation"

describe ErrorMessageTranslation do
  describe ".from_github_error" do
    context "when error status is 403" do
      it "returns error message" do
        error = double("error", message: octokit_403_error_message)
        expected_message = "You must be an admin to add a team membership."

        result = ErrorMessageTranslation.from_github_error(error)

        expect(result).to eq expected_message
      end
    end

    context "when error status is not 403" do
      it "returns nil" do
        error = double("error", message: octokit_400_error_message)

        result = ErrorMessageTranslation.from_github_error(error)

        expect(result).to be_nil
      end
    end

    context "when error does not adhere to expected formatting" do
      it "returns nil" do
        message = "error"
        error = double("error", message: message)

        result = ErrorMessageTranslation.from_github_error(error)

        expect(result).to be_nil
      end
    end
  end

  describe ".from_stripe_error" do
    context "when error HTTP status is 402" do
      it "returns error message" do
        message = "Your credit card was declined"
        error = double("error", http_status: "402", message: message)

        result = ErrorMessageTranslation.from_stripe_error(error)

        expect(result).to eq message
      end
    end
  end

  context "when error HTTP status is not 402" do
    it "returns nil" do
      error = double("error", http_status: "403")

      result = ErrorMessageTranslation.from_stripe_error(error)

      expect(result).to be_nil
    end
  end

  private

  def octokit_403_error_message
    "PUT https://api.github.com/teams/3675/memberships/houndci: 403 - You must be an admin to add a team membership. // See: https://developer.github.com/v3"
  end

  def octokit_400_error_message
    "PUT https://api.github.com/teams/3675/memberships/houndci: 400 - Problems parsing JSON. // See: https://developer.github.com/v3"
  end
end
