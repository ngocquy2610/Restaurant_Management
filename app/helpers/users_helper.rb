module UsersHelper
  def tier_color(tier_id)
    case tier_id
    when 0
      "border-[#CD7F32]" # Bronze
    when 1
      "border-[#C0C0C0]" # Silver
    when 2
      "border-[#FFD700]" # Gold
    when 3
      "border-[#B9F2FF]" # Diamond
    when 4
      "border-[#FFFFFF]" # White
    else
      "border-[#FFFFFF]"
    end
  end
end
