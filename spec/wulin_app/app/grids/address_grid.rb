# frozen_string_literal: true

class AddressGrid < WulinMaster::Grid
  title "Addresses"

  model Address

  # path '/addresses' # Define a different route for the grid

  COUNTRY_OPTIONS = ["中国", "United States"].freeze
  CITY_OPTIONS = {
    "中国" => %w[北京 上海 广州 成都 深圳],
    "United States" => ["New York", "California", "Illinois"]
  }.freeze

  column :country, choices: COUNTRY_OPTIONS, editor: "SelectEditor"
  column :city, choices: CITY_OPTIONS, depend_column: :country, editor: "SelectEditor"

  load_default_actions # Add default toolbar items for this grid
end
