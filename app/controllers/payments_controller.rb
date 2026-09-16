class PaymentsController < ApplicationController
  before_action :set_order
  before_action :set_payment, only: [:confirm]

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

    redirect_to bill_order_payment_path(@order, @payment), notice: "Bill created."
    rescue ActiveRecord::RecordNotFound
      redirect_to order_path(@order), alert: "That payment method is unavailable."
    rescue ActiveRecord::RecordInvalid => error
      redirect_to order_path(@order), alert: error.record.errors.full_messages.to_sentence
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

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_payment
    @payment = @order.payments.find(params[:id])
  end
end