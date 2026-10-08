module ReviewsHelper
  def review_badge
    content_tag(:span, "Restaurant review",
      class: "inline-flex items-center rounded-full bg-[#8A1C2B]/10 px-2.5 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.14em] text-[#8A1C2B]")
  end

  def review_stars(rating)
    filled = rating.to_i.clamp(0, 5)
    content_tag(:span, ("★" * filled) + ("☆" * (5 - filled)), aria: { label: "#{filled} out of 5" })
  end
end
