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

  it_behaves_like 'a sender' # 1

  subject { described_class.new(scheduled_triggered_email) }

  before do
    stub_request(:get, /http.*/).to_return(status: 200, body: '', headers: {})
  end

  describe '#check_send_conditions' do
    context 'when failing multiple conditions' do
      let(:triggerable) { Purchase.new }

      before { customer.email = nil }

      it 'should return the cart specific, not the triggered email one' do # 2
        expect(subject.send :check_send_conditions).to eq(
          email_send_conditions.fetch(:email_is_blank?)
        )
      end
    end
  end

  describe '#should_send_email?' do
    context 'everything is cool' do
      xit 'should send the email' do # 3
        expect(subject.should_send_email?).to be true
      end

      it 'should get no error message' do # 4
        expect(subject.send :check_send_conditions).to eq nil
      end
    end

    context '#cart_is_empty?' do
      before do
        allow(triggerable).to receive(:line_items).and_return([])
      end

      it 'returns false' do # 5
        expect(subject.should_send_email?).to be false
      end

      context 'when configuration can skip empty cart check' do
        before do
          subject.config.skip_empty_cart_check = true
        end

        xit 'returns true' do
          expect(subject.should_send_email?).to be true
        end
      end
    end

    context 'has_no_visible_products?' do
      before { allow(trigger).to receive(:products_with_images) { [] } }

      it 'returns false' do # 6
        expect(subject.should_send_email?).to be false
      end
    end

    context '#is_not_a_cart?' do
      let!(:triggerable) { build(:purchase) }

      before do
        allow(trigger).to receive(:email) { customer.email }
        allow(trigger).to receive(:products_with_images) { products }
        allow(triggerable).to receive(:products) { products }
        allow_any_instance_of(ProductDecorator).to receive(:valid_landing_url?).and_return(true)
        allow_any_instance_of(ProductDecorator).to receive(:valid_image_url?).and_return(true)
      end

      it 'should not send the triggered email' do # 7
        expect(subject.should_send_email?).to be false
      end

      it 'should fail because of the right error message' do
        expect(subject.send :check_send_conditions).to eq(
          email_send_conditions.fetch(:is_not_a_cart?)
        )
      end
    end

    context '#cart_has_been_purchased?' do
      let!(:purchase) do
        create(:purchase,
               store_id: store.id,
               quote_id: triggerable.quote_id)
      end

      context 'with visible products' do
        it 'should not send the triggered email' do # 8
          expect(subject.should_send_email?).to be false
        end

        it 'should fail with an existing purchase message' do
          expect(subject.send :check_send_conditions).to eq(
            email_send_conditions.fetch(:cart_has_been_purchased?)
          )
        end
      end

      context 'without visible products' do
        before do
          allow(subject).to receive(:has_no_visible_products?).and_return(true)
        end

        it 'should not send the triggered email' do # 9
          expect(subject.should_send_email?).to be false
        end

        it 'should fail with an existing purchase message' do
          expect(subject.send :check_send_conditions).to eq(
            email_send_conditions.fetch(:cart_has_been_purchased?)
          )
        end
      end
    end

    context '#user_signin_switcheroo?' do
      let(:cart2) { build(:cart, store_id: store.id, customer_email: customer.email) }
      let!(:purchase) do
        create(:purchase,
               store_id: store.id,
               order_date_time: order_date_time,
               email: customer.email,
               quote_id: cart2.quote_id)
      end

      context 'purchase is within range' do
        let(:order_date_time) { 1.hour.ago }

        it 'should not send the triggered email' do # 11
          expect(subject.should_send_email?).to be false
        end

        it 'should fail because of the right error message' do # 12
          expect(subject.send :check_send_conditions).to eq(
            email_send_conditions.fetch(:user_signin_switcheroo?)
          )
        end
      end

      context 'purchase is not within range' do
        let(:order_date_time) { 2.days.ago }

        it 'should send the triggered email' do # 13
          expect(subject.should_send_email?).to be true
        end
      end
    end

    context '#user_has_multiple_carts?' do
      let!(:quote_updated) { 2.hours.ago }
      let!(:status) { '' }

      let!(:cart) { create(:cart, customer_email: customer.email, store_id: store.id, quote_updated: 1.hour.ago) }
      let!(:cart2) { create(:cart, store_id: store.id, customer_email: customer.email, quote_updated: quote_updated) }

      let!(:trigger) { create :trigger, store: store, trigger: cart }
      let!(:trigger2) { create :trigger, store: store, trigger: cart2, status: status }

      context 'when a related trigger has sent' do
        let!(:status) { 'Email Sent!' }

        it 'should not send the triggered email' do #14
          expect(subject.should_send_email?).to be false
        end

        it 'should fail because of the right error message' do # 15
          expect(subject.send :check_send_conditions).to eq(
            email_send_conditions.fetch(:user_has_mutliple_carts?)
          )
        end
      end

      context 'when the cart is the most recently updated' do
        it 'should send the triggered email' do # 16
          expect(subject.should_send_email?).to be true
        end
      end

      context 'when the cart is not the most recently updated' do
        let(:quote_updated) { 30.minutes.ago }

        it 'should not send the triggered email' do # 17
          expect(subject.should_send_email?).to be false
        end

        it 'should fail because of the right error message' do # 18
          expect(subject.send :check_send_conditions).to eq(
            email_send_conditions.fetch(:user_has_mutliple_carts?)
          )
        end
      end
    end

    context 'when the cart came from harvest' do
      before do
        allow(triggerable).to receive(:came_from_harvest?).and_return(true)
      end

      it 'should not send the triggered email' do # 19
        expect(subject.should_send_email?).to be false
      end
    end
  end
end