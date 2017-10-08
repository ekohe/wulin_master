When(/^(?:|I )press '([^"]*)'$/) do |button|
  page.execute_script("$('.flatpickr-calendar').removeClass('open')")
  click_button(button)
end

When(/^(?:|I )click on '([^"]*)'$/) do |button|
  click_link(button)
end

Then(/^(?:|I )should see '([^\']*)'$/) do |text|
  expect(page).to have_content(text)
end

Then(/^take a screenshot$/) do
  page.save_screenshot("~/Desktop/screenshot-#{Time.now.to_i}.png")
end

Given(/^I wait for (.+) seconds?$/) do |n|
  sleep(n.to_f)
end

Given(/^I go to the homepage$/) do
  visit root_path
end

When(/^I enter '([^"]*)' in '([^"]*)'$/) do |content, field|
  within(:css, ".modal") do
    fill_in field, with: content
  end
end

When(/^I press the '([^"]*)' key$/) do |key_code|
  find('body').native.send_keys(key_code.downcase.to_sym)
end

Given(/^I have (\d+) (.*) in the database$/) do |count, factory_name|
  create_list(factory_name.singularize.to_sym, count.to_i)
end
