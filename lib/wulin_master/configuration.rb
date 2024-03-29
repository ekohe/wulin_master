# frozen_string_literal: true

module WulinMaster
  def self.configure(configuration = WulinMaster::Configuration.new)
    yield configuration if block_given?
    @config = configuration
  end

  def self.config
    @config ||= WulinMaster::Configuration.new
  end

  class Configuration
    attr_accessor :app_title, :app_title_height, :always_reset_form,
                  :default_year, :default_month, :date_format, :color_theme, :button_mode, :nav_sidebar_partial_path,
                  :master_detail_color_theme

    def initialize
      self.app_title = 'Undefined App'
      self.app_title_height = '42px'
      self.always_reset_form = false
      self.default_year = Time.zone ? Time.zone.today.year : nil
      self.default_month = Time.zone ? Time.zone.today.month : nil
      self.color_theme = 'blue'
      self.button_mode = 'split'
      self.nav_sidebar_partial_path = ''
      self.master_detail_color_theme = 'teal'
      # International format is: d/m/Y (Dec 31st 2024 is 31/12/2024)
      # US format is: m/d/Y (Dec 31st 2024 is 12/31/2024)
      self.date_format = 'international' # alternative is 'us'
    end

    def split_button_mode?
      button_mode == 'split'
    end

    def merged_button_mode?
      button_mode == 'merged'
    end
  end
end
