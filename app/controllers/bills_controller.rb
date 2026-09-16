class BillsController < ApplicationController
  before_action :set_order
  before_action :set_payment

  def show
    authorize @order, :show?
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_payment
    @payment = @order.payments.includes(:payment_method).find(params[:id])
  end
end