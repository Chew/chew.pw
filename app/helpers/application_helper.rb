#noinspection RubyResolve
module ApplicationHelper
  def fas_icon(icon)
    content_tag :i, nil, class: "fas fa-#{icon}"
  end

  def fab_icon(icon)
    content_tag :i, nil, class: "fab fa-#{icon}"
  end

  def fa_icon(icon)
    tag.i class: icon
  end

  # Adds necessary tags for meta where needed
  # @param title [String] The title of the page. Appears in navbar and embed titles. Do not include "- Service"
  # @param description [String] Embed description
  # @param service [String] the service, e.g. Chewbotcca, Minecraft Tools, etc
  # @param color [String] Embed color
  def meta_tags(title: '', description: '', service: '', color: '#F078DD', keywords: 'chew')
    [
      tag.title("#{title} - #{service}"),
      tag('meta', property: 'og:title', content: "#{title}"),
      tag('meta', property: 'twitter:title', content: "#{title}"),
      tag('meta', property: 'description', content: description.to_s),
      tag('meta', name: 'description', content: description.to_s),
      tag('meta', property: 'og:description', content: description.to_s),
      tag('meta', property: 'og:site_name', content: service.to_s),
      tag('meta', property: 'twitter:site', content: service.to_s),
      tag('meta', name: 'theme-color', content: color),
      tag('meta', name: 'keywords', content: keywords.to_s)
    ].join("\n").html_safe
  end

  # Adds a item to a navbar dropdown
  # @param name [String] the name (shown on the dropdown)
  # @param href [String] where to actually link to
  # @param fa_icon [String] the icon to show before the text
  # @param external [Boolean] Whether this opens in a new tab (optional if href is an external link)
  def dropdown_item(name: '', href: '#', fa_icon: nil, external: false)
    tag.a(class: 'dropdown-item', href: href, target: external ? '_blank' : nil) do
      # Add icon if needed
      concat(fa_icon(fa_icon)) if fa_icon
      # Add a space if there is an icon
      concat(' ') if fa_icon
      # Add the name
      "#{concat(name)}"
    end
  end

  # Adds an item to a navbar
  # @param name [String] the name (shown in navbar)
  # @param href [String] the destination link
  # @param fa_icon [String] the icon to show before the text (optional)
  # @param external [Boolean] Whether this opens in a new tab (optional if href is an external link)
  def navbar_item(name: '', href: '#', fa_icon: nil, external: false, pill: "")
    tag.li(class: "nav-item#{' disabled active' if request.path == href}") do
      tag.a(class: "nav-link#{' active disabled' if request.path == href}", href: href, target: external ? '_blank' : nil) do
        # Add icon if needed
        concat(fa_icon(fa_icon)) if fa_icon
        # Add a space if there is an icon
        concat(' ') if fa_icon
        # Add the name
        "#{concat(name)}"
        # Add pill if needed after, if applicable.
        # A span tag with "badge rounded-pill text-bg-danger" class and the text provided
        concat(" ") if pill
        concat(tag.span(pill, class: "badge rounded-pill bg-danger")) if pill
      end
    end
  end

  # Creates a navbar dropdown
  # The contents of the block should be dropdown_items
  # @param name [String] the name of the dropdown
  # @param fa_icon [String] the icon to show before the text (optional)
  # @param block [Block] the contents of the dropdown
  def nav_dropdown(name: '', fa_icon: nil, &block)
    id = "#{name.parameterize}-dropdown"
    tag.li(class: 'nav-item dropdown') do
      tag.a(class: 'nav-link dropdown-toggle', href: '#', id: id, role: 'button', data: { 'bs-toggle': 'dropdown' }, aria: { haspopup: true, expanded: false }) do
        # Add icon if needed
        concat(fa_icon(fa_icon)) if fa_icon
        # Add a space if there is an icon
        concat(' ') if fa_icon
        # Add the name
        "#{concat(name)}"
      end +
        tag.div(class: 'dropdown-menu', aria: { labelledby: id }) do
          block.call
        end
    end
  end

  # Creates a clickable link to a parameterized title.
  # @param name [String] the name (shown in navbar)
  # @return [String] the link
  def header_link(name)
    link_to name, "##{name.parameterize}"
  end

  # Converts a timestamp into a friendly date:
  # DayOfWeek, Month Day (with ordinal), Year
  # @param date [String] the timestamp
  # @return [String] the date
  def friendly_date(date, with_time: false, in_zone: "UTC")
    time = Time.parse(date).in_time_zone(in_zone)
    if with_time
      time.strftime("%A, %B #{time.day.ordinalize}, %Y at %l:%M %p %Z")
    else
      time.strftime("%A, %B #{time.day.ordinalize}, %Y")
    end
  end

  # Converts a time in seconds to hh:mm:ss (with milliseconds)
  # @param time [Float] the time in seconds
  # @return [String] the time
  def to_hms(time)
    formatted = Time.at(time).utc.strftime("%H:%M:%S.%L")
    formatted.start_with?("00:") ? formatted.sub("00:", "") : formatted
  end
end
