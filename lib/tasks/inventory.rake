namespace :inventory do
  desc "Deduct stock for items already accepted but not yet deducted"
  task backfill_accepted: :environment do
    OrderItem.where(status: %i[accepted preparing ready]).find_each do |item|
      StockService.consume_order_item!(item)
    rescue StockService::Error => e
      puts "item #{item.id}: #{e.message}"
    end
  end
end
