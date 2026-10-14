module ApplicationHelper
  def money(value)
    number_to_currency(value.to_d, precision: 0, strip_insignificant_zeros: true)
  end

  def rating(value)
    number_with_precision(value.to_d, precision: 1, strip_insignificant_zeros: true)
  end

  def percent(value)
    number_with_precision(value.to_d, precision: 1, strip_insignificant_zeros: true)
  end

  def trend_chart(series, width: 700, height: 180)
    return content_tag(:div, "No data available", class: "mt-6 text-sm text-gray-500") if series.blank?

    values = series.values.map(&:to_f)
    max_value = [values.max.to_f, 1.0].max
    min_value = [values.min.to_f, 0.0].min
    value_range = max_value - min_value
    value_range = 1.0 if value_range.zero?

    points = series.each_with_index.map do |(_label, value), index|
      x = 18 + (index * (width - 36) / [series.size - 1, 1].max.to_f)
      y = height - 18 - ((value.to_f - min_value) / value_range) * (height - 42)
      [x, y]
    end

    line_points = points.map { |x, y| "#{x.round(2)},#{y.round(2)}" }.join(" ")
    area_points = [points.first, *points, points.last].map { |x, y| "#{x.round(2)},#{y.round(2)}" }.join(" ")

    labels = series.map do |label, _value|
      content_tag(:span, trend_label(label), class: "text-[10px] uppercase tracking-[0.12em] text-gray-400")
    end

    svg_markup = tag.svg(viewBox: "0 0 #{width} #{height}", class: "h-44 w-full overflow-visible", role: "img") do
      safe_join([
        tag.path(d: "M 18 #{height - 18} L #{points.map { |x, y| "#{x.round(2)} #{y.round(2)}" }.join(' L ')} L #{width - 18} #{height - 18} Z", fill: "rgba(138, 28, 43, 0.08)"),
        tag.polyline(points: line_points, fill: "none", stroke: "#8A1C2B", "stroke-width" => 3, "stroke-linecap" => "round", "stroke-linejoin" => "round"),
        tag.circle(cx: points.last[0], cy: points.last[1], r: 4, fill: "#8A1C2B")
      ])
    end

    labels_markup = content_tag(:div, safe_join(labels), class: "mt-3 flex items-center justify-between gap-2 text-[10px] uppercase tracking-[0.12em] text-gray-400")

    content_tag(:div, class: "mt-6") do
      safe_join([svg_markup, labels_markup])
    end
  end

  def trend_label(label)
    return label.to_s if label.is_a?(String)

    label.respond_to?(:strftime) ? label.strftime("%d %b") : label.to_s
  end
end
