class BillsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order
  before_action :set_payment

  def show
    authorize @order, :show?
    @order_items = @order.order_items.includes(:food, :food_variant)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = InvoicePdf.new(order: @order, payment: @payment).generate
        send_data pdf,
          filename: "invoice-order-#{@order.id}-payment-#{@payment.id}.pdf",
          type: "application/pdf",
          disposition: "attachment"
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_payment
    @payment = @order.payments.includes(:payment_method, :processed_by).find(params[:id])
  end
end