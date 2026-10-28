class PaymentsController < ApplicationController
  before_action :set_order
  before_action :set_payment, only: [:confirm, :success]

  def create
    authorize @order, :update?
    redirect_to order_path(@order), alert: "This order is already completed." and return if @order.completed?
    if @order.payments.pending.exists?
      redirect_to order_path(@order), alert: "There is already a pending payment for this order."
      return
    end

    @order.recalculate_total_price!

    payment_method = PaymentMethod.find_by!(id: params[:payment_method_id], active: true)

    @payment = @order.payments.create!(
      payment_method: payment_method,
      subtotal: @order.subtotal,
      discount_amount: @order.discount_amount || 0,
      total_amount: @order.total_price,
      currency: "VND",
      status: :pending,
      idempotency_key: SecureRandom.uuid
    )

    if payment_method.card?
      session = Stripe::Checkout::Session.create(
        {
          mode: "payment",
          line_items: [
            {
              price_data: {
                currency: "vnd",
                product_data: { name: "Restaurant order ##{@order.id}" },
                unit_amount: @payment.total_amount_vnd.to_i
              },
              quantity: 1
            }
          ],
          success_url: success_order_payment_url(@order, @payment),
          cancel_url: bill_order_payment_url(@order, @payment),
          metadata: {
            payment_id: @payment.id,
            order_id: @order.id
          }
        },
        { idempotency_key: @payment.idempotency_key }
      )

      @payment.update!(stripe_checkout_session_id: session.id)
      redirect_to session.url, status: :see_other, allow_other_host: true and return
    end

    redirect_to bill_order_payment_path(@order, @payment), notice: "Bill created."
    rescue ActiveRecord::RecordNotFound
      redirect_to order_path(@order), alert: "That payment method is unavailable."
    rescue ActiveRecord::RecordInvalid => error
      redirect_to order_path(@order), alert: error.record.errors.full_messages.to_sentence
  rescue Stripe::StripeError => error
    @payment&.update(status: :failed, failure_reason: error.message)
    redirect_to order_path(@order), alert: "Stripe could not start the payment."
  end

  def confirm
    authorize @order, :update?

    unless @payment.pending?
      redirect_to order_path(@order),
                  alert: "This payment is no longer pending." and return
    end

    @order.recalculate_total_price!
    unless @payment.total_amount == @order.total_price
      redirect_to order_path(@order), alert: "The order total changed. Create a new payment."
      return
    end

    Payment.transaction do
      @payment.update!(
        status: :completed,
        processed_by: current_user,
        paid_at: Time.current
      )

      @order.update!(status: :completed)
    end

    redirect_to order_path(@order),
                notice: "Payment confirmed and order completed."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to order_path(@order), alert: error.message
  end

  def success
    session = Stripe::Checkout::Session.retrieve(
      @payment.stripe_checkout_session_id
    )

    if session.payment_status == "paid"
      Payment.transaction do
        @payment.update!(
          status: :completed,
          paid_at: Time.current
        )

        @order.update!(status: :completed)
      end

      redirect_to order_path(@order),
                  notice: "Payment completed successfully."
    else
      redirect_to bill_order_payment_path(@order, @payment),
                  alert: "Payment has not been completed."
    end
  rescue Stripe::StripeError => error
    redirect_to bill_order_payment_path(@order, @payment),
                alert: error.message
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_payment
    @payment = @order.payments.find(params[:id])
  end
end