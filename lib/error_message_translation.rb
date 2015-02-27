module ErrorMessageTranslation
  ERROR_CODE_AND_MESSAGE = /.*(\d{3})\s\-\s(.*)\s\/\/.*/
  FORBIDDEN_ERROR_CODE = "403"
  PAYMENT_REQUIRED_ERROR_CODE = "402"

  def self.from_github_error(error)
    matches = error.message.match(ERROR_CODE_AND_MESSAGE)

    if matches.present? && matches.captures[0] == FORBIDDEN_ERROR_CODE
      matches.captures[1]
    end
  end

  def self.from_stripe_error(error)
    if error.http_status == PAYMENT_REQUIRED_ERROR_CODE
      error.message
    end
  end
end
