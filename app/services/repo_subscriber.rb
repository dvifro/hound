class RepoSubscriber
  attr_reader :errors

  def initialize(repo, user, card_token)
    @repo = repo
    @user = user
    @card_token = card_token
    @errors = []
  end

  def self.subscribe(repo, user, card_token)
    new(repo, user, card_token).subscribe
  end

  def self.unsubscribe(repo, user)
    new(repo, user, nil).unsubscribe
  end

  def subscribe
    customer = if user.stripe_customer_id.present?
      payment_gateway_customer
    else
      create_stripe_customer
    end

    stripe_subscription = customer.subscriptions.create(
      plan: repo.plan_type,
      metadata: { repo_id: repo.id }
    )

    repo.create_subscription!(
      user_id: user.id,
      stripe_subscription_id: stripe_subscription.id,
      price: repo.plan_price
    )
  rescue => error
    add_error(error)
    report_exception(error)
    stripe_subscription.try(:delete)
    nil
  end

  def unsubscribe
    stripe_subscription = payment_gateway_customer.subscriptions.retrieve(
      repo.subscription.stripe_subscription_id
    )
    stripe_subscription.delete

    repo.subscription.destroy
  rescue => error
    report_exception(error)
    nil
  end

  private

  attr_reader :user, :repo, :card_token

  def report_exception(error)
    Raven.capture_exception(
      error,
      extra: { user_id: user.id, repo_id: repo.id }
    )
  end

  def payment_gateway_customer
    @payment_gateway_customer ||= PaymentGatewayCustomer.new(user).customer
  end

  def create_stripe_customer
    stripe_customer = Stripe::Customer.create(
      email: user.email_address,
      metadata: { user_id: user.id },
      card: card_token
    )

    user.update(stripe_customer_id: stripe_customer.id)

    stripe_customer
  end

  def add_error(error)
    if error.is_a?(Stripe::StripeError)
      error_message = ErrorMessageTranslation.from_stripe_error(error)
      errors.push(error_message).compact!
    end
  end
end
