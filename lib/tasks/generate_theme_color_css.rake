namespace :wulin_master do
  desc "Generate SCSS variables from theme color configuration"
  task :generate_theme_color_css => :environment do
    if WulinMaster.config.color_theme.blank?
      puts "WulinMaster.config.color_theme is blank"
      exit 1
    end

    content = <<~SCSS
      // Auto-generated: DO NOT EDIT BY HAND
      // Edit in config/initializers/wulin_master.rb
      // and generate using: bundle exec rake wulin_master:generate_theme_color_css
      $color-theme: '#{WulinMaster.config.color_theme}';
    SCSS
    File.write Rails.root.join("app/assets/stylesheets/_theme.generated.sass"), content
    puts "Set $color-theme to #{WulinMaster.config.color_theme}"
    puts "Wrote _theme.generated.scss"
  end
end
