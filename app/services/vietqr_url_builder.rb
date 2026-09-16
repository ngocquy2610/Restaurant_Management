class VietqrUrlBuilder
  BASE_URL = "https://img.vietqr.io/image".freeze

  def self.configured?
    [bank_code, account_number, account_name].all?(&:present?)
  end

  def self.call(payment)
    return unless configured?

    query = {
      amount: amount_in_vnd(payment),
      addInfo: "ORDER-#{payment.order_id}-PAYMENT-#{payment.id}",
      accountName: account_name
    }.to_query

    "#{BASE_URL}/#{bank_code}-#{account_number}-compact2.jpg?#{query}"
  end

  def self.bank_code
    ENV["VIETQR_BANK_CODE"].presence || Rails.application.credentials.dig(:vietqr, :bank_code)
  end

  def self.account_number
    ENV["VIETQR_ACCOUNT_NUMBER"].presence || Rails.application.credentials.dig(:vietqr, :account_number)
  end

  def self.account_name
    ENV["VIETQR_ACCOUNT_NAME"].presence || Rails.application.credentials.dig(:vietqr, :account_name)
  end

  def self.exchange_rate
    (
      ENV["USD_TO_VND_RATE"].presence ||
      Rails.application.credentials.dig(:vietqr, :usd_to_vnd_rate) ||
      25_000
    ).to_d
  end

  def self.amount_in_vnd(payment)
    (payment.total_amount.to_d * exchange_rate).round
  end
end