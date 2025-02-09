# svg helper
module SvgHelper
  def icon(name, options = {})
    options[:class] = options.fetch(:classes, nil)
    path = options.fetch(:path, "icons/#{name}.svg")
    icon = path
    inline_svg_tag(icon, options)
  end
end
