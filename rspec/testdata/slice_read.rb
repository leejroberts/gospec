require 'rails_helper'
require_relative 'scheduled_triggered_email_sender_shared'

describe AbandonedCartScheduledTriggeredEmailSender do
  before do
    Time.zone = 'UTC'
    Timecop.freeze(DateTime.new(2015, 1, 15, 12))
  end

  include_context 'triggered_email setup'

  let(:cart_purchased) { false }
  let(:time_til_send) { 3.hours }
  let(:type) { 'AbandonedCartEmail' }

  let(:triggerable) do
    build(:cart,
          customer_email: customer.email,
          store_id: store.id,
          purchased: cart_purchased,
          products: products)
  end

  let(:email_send_conditions) { subject.send(:email_send_conditions) }

  before do
    allow_any_instance_of(Cart).to receive(:store) { store }
  end
end