module ReviewsHelper
  REVIEW_TYPE_META = {
    "meal"       => { label: "Meal review",       chip: "bg-amber-100",   text: "text-amber-700" },
    "restaurant" => { label: "Restaurant review", chip: "bg-[#8A1C2B]/10", text: "text-[#8A1C2B]" }
  }.freeze

  def review_type_meta(type) = REVIEW_TYPE_META.fetch(type.to_s, REVIEW_TYPE_META["meal"])

  def review_type_badge(type)
    meta = review_type_meta(type)
    content_tag(:span, meta[:label],
      class: "inline-flex items-center rounded-full #{meta[:chip]} px-2.5 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.14em] #{meta[:text]}")
  end

  def review_stars(rating)
    filled = rating.to_i.clamp(0, 5)
    content_tag(:span, ("★" * filled) + ("☆" * (5 - filled)), aria: { label: "#{filled} out of 5" })
  end
end
