# frozen_string_literal: true

class HomepageController < WulinMaster::HomeController
  def example
    render plain: '<h1>You got to see me!</h1>'
  end
end
