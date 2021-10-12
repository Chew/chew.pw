module ApplicationHelper
  def fas_icon(icon)
    "<i class=\"fas fa-#{icon}\"></i>".html_safe
  end

  def fab_icon(icon)
    "<i class=\"fab fa-#{icon}\"></i>".html_safe
  end

  # Adds necessary tags for meta where needed
  # @param title [String] The title of the page. Appears in navbar and embed titles. Do not include "- Service"
  # @param description [String] Embed description
  # @param service [String] the service, e.g. Chewbotcca, Minecraft Tools, etc
  # @param color [String] Embed color
  def meta_tags(title: '', description: '', service: '', color: '#F078DD', keywords: 'chew')
    [
      tag.title("#{title} - #{service}"),
      tag('meta', property: 'og:title', content: "#{title} - #{service}"),
      tag('meta', property: 'twitter:title', content: "#{title} - #{service}"),
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
    tag = "<a class=\"dropdown-item\" href=\"#{href}\""
    tag += if external || href.start_with?("http")
             " target=\"_blank\" rel=\"noopener\">"
           else
             ">"
           end
    if fa_icon
      tag += "<i class=\"#{fa_icon}\"></i> "
    end
    tag += name
    tag += "</a>"
    tag.html_safe
  end

  # Adds an item to a navbar
  # @param name [String] the name (shown in navbar)
  # @param href [String] the destination link
  # @param fa_icon [String] the icon to show before the text (optional)
  # @param external [Boolean] Whether this opens in a new tab (optional if href is an external link)
  def navbar_item(name: '', href: '#', fa_icon: nil, external: false)
    tag = "<li class=\"nav-item#{' disabled active' if request.path == href}\">"
    tag += "<a class=\"nav-link#{' active disabled' if request.path == href}\" href=\"#{href}\""
    tag += if external
             " target=\"_blank\">"
           else
             ">"
           end
    if fa_icon
      tag += "<i class=\"#{fa_icon}\"></i> "
    end
    tag += "#{name}</a>"
    tag += "</li>"
    tag.html_safe
  end
end
