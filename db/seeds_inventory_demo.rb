# Demo data cho module Inventory Management.
# Chạy: bin/rails runner db/seeds_inventory_demo.rb  (tương đương dán vào rails c)
# Tạo dữ liệu mẫu cho từng mục: Ingredients, Stock Transactions,
# Low Stock Requests, Waste Reports, Restock Tasks.
# Chỉ dùng cho môi trường dev.

admin   = User.find_by(role: :admin) || User.find_by(role: :inventory_manager)
inv     = User.find_by(role: :inventory_manager)
kitchen = User.find_by(role: :kitchen_staff)
raise "Thiếu user seed (inventory_manager/kitchen_staff). Chạy db:seed trước." unless inv && kitchen

puts "== 1) Ingredients =="
ingredients = {}
[
  # name,               unit, category,  unit_cost, current_qty, threshold
  ["Demo Ribeye",       "kg", "meat",    4.00,   1.0,   3.0],  # -> low_stock
  ["Demo Basmati Rice", "kg", "dry",     1.50,   0.0,   2.0],  # -> out_of_stock
  ["Demo Fresh Basil",  "g",  "produce", 0.05, 500.0, 100.0]   # -> in_stock
].each do |name, unit, cat, cost, qty, thr|
  ing = Ingredient.find_or_initialize_by(name: name)
  ing.assign_attributes(unit: unit, category: cat, unit_cost: cost,
                        current_quantity: qty, low_stock_threshold: thr)
  ing.save!
  ingredients[name] = ing
  puts "  #{ing.name}: qty=#{ing.current_quantity} thr=#{ing.low_stock_threshold} => #{ing.status}"
end

puts "== 2) Stock transactions (qua StockService để ghi ledger + sync tồn) =="
StockService.restock(ingredient: ingredients["Demo Fresh Basil"], quantity: 200,
                     user: inv, reason: "Demo PO-1001", reference: "demo:po-1001")
StockService.waste(ingredient: ingredients["Demo Fresh Basil"], quantity: 50,
                   user: inv, reason: "Demo spoilage", reference: "demo:waste-1")
StockService.apply_transaction(ingredient: ingredients["Demo Fresh Basil"],
                               transaction_type: :stock_out, quantity: 100,
                               user: inv, reason: "Demo kitchen prep", reference: "demo:prep-1")
# Kéo Demo Ribeye xuống dưới ngưỡng -> tự sinh RestockTask auto/pending.
StockService.adjust(ingredient: ingredients["Demo Ribeye"], new_quantity: 2,
                    user: inv, reason: "Demo physical count")

puts "== 3) Low stock requests =="
lsr = {}
{
  pending:   ["Demo Basmati Rice", "Demo: gạo sắp hết"],
  approved:  ["Demo Ribeye",       "Demo: cần thêm thịt"],
  rejected:  ["Demo Fresh Basil",  "Demo: bị từ chối"],
  completed: ["Demo Fresh Basil",  "Demo: đã xử lý"]
}.each do |status, (ing_name, note)|
  lsr[status] = LowStockRequest.create!(
    user: kitchen, ingredient: ingredients[ing_name], note: note, status: status,
    reviewed_by: (status == :pending ? nil : inv),
    reviewed_at: (status == :pending ? nil : Time.current)
  )
  puts "  LowStockRequest##{lsr[status].id} => #{lsr[status].status}"
end

puts "== 4) Waste reports =="
wr = {}
{
  pending:  ["Demo Fresh Basil",  30, nil],
  approved: ["Demo Basmati Rice", 20, 15],
  rejected: ["Demo Ribeye",        5, nil]
}.each do |status, (ing_name, qty, verified)|
  wr[status] = WasteReport.create!(
    ingredient: ingredients[ing_name], user: kitchen, quantity: qty,
    verified_quantity: verified, reason: "Demo waste (#{status})", status: status,
    reviewed_by: (status == :pending ? nil : inv),
    reviewed_at: (status == :pending ? nil : Time.current)
  )
  puts "  WasteReport##{wr[status].id} => #{wr[status].status}"
end

puts "== 5) Restock tasks (auto/pending đã sinh ở bước 2) =="
RestockTask.create!(ingredient: ingredients["Demo Fresh Basil"], quantity: 300, source: :auto,
                    status: :completed, received_quantity: 300, supplier: "Demo Foods Co.",
                    note: "Demo delivered", completed_at: Time.current)
RestockTask.create!(ingredient: ingredients["Demo Basmati Rice"], quantity: 2, source: :auto,
                    status: :cancelled, note: "Demo no longer needed")
RestockTask.create!(ingredient: lsr[:approved].ingredient, quantity: 4, source: :request,
                    status: :in_progress, low_stock_request: lsr[:approved], due_on: 2.days.from_now)
RestockTask.create!(ingredient: wr[:approved].ingredient, quantity: 10, source: :waste,
                    status: :pending, waste_report: wr[:approved], due_on: 3.days.from_now)

puts "== Summary =="
puts "  StockTransaction=#{StockTransaction.count}  LowStockRequest=#{LowStockRequest.count}  " \
     "WasteReport=#{WasteReport.count}  RestockTask=#{RestockTask.count}"
puts "Demo seed complete."
