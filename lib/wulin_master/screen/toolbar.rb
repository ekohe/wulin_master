module WulinMaster
  class Toolbar < Array
    def render
      # sort_when_render
      items = self.collect do |item|
        item.render
      end.join("").html_safe
      "<div id=\"toolbar\">#{items}</div>".html_safe
    end

    # Sort according option of each item
    # def sort_when_render
    #   self.dup.each do |item|
    #     if before_title = item.options[:before]
    #       before_index = self.find_index {|x| x.title == before_title }
    #       self.delete(item)
    #       self.insert(before_index, item)
    #     elsif after_title = item.options[:after]
    #       after_index = self.find_index {|x| x.title == after_title }
    #       self.delete(item)
    #       self.insert(after_index + 1, item)
    #     end
    #   end
    # end
  end
end