module WulinMaster
  class Toolbar < Array  
    def render
      items = self.collect do |item|
        item.render
      end.join("").html_safe
      "<div id=\"toolbar\">#{items}</div>".html_safe
    end
  end
end