module ApplicationHelper
  def render_markdown(text)
    return "" if text.blank?
    
    html = ERB::Util.html_escape(text)
    html = html.gsub(/!\[([^\]]*)\]\(([^)]+)\)/, '<img src="\2" alt="\1" style="max-width: 100%; border-radius: 4px; margin: 4px 0;">')
    html = html.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2" target="_blank">\1</a>')
    html = html.gsub(/\n/, "<br>")
    html.html_safe
  end
end
