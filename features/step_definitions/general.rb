When /^(?:|I )press '([^"]*)'$/ do |button|
  click_button(button)
end

When /^(?:|I )click on '([^"]*)'$/ do |button|
  click_link(button)
end

Then /^(?:|I )should see '([^\']*)'$/ do |text|
  expect(page).to have_content(text)
end

Then /^take a screenshot$/ do
  page.save_screenshot("~/Desktop/screenshot-#{Time.now.to_i}.png")
end

Given /^I wait for (\d+) seconds?$/ do |n|
  sleep(n.to_i)
end

Given(/^I go to the homepage$/) do
  visit '/'
end

Then(/^I should see the '([^"]*)' grid$/) do |grid_name|
  expect(page).to have_xpath('//div[@class="grid_container"]/div[@class="grid-header"]/h2', text: grid_name)
end

Then(/^I should see the '([^"]*)' popup$/) do |dialog_title|
  expect(page).to have_xpath('//span[@class="ui-dialog-title"]', text: dialog_title)
end

When(/^I enter '([^"]*)' in '([^"]*)'$/) do |content, field|
  fill_in field, with: content
end

When(/^I press the '([^"]*)' key$/) do |key_code|
  find('body').native.send_keys(key_code.downcase.to_sym)
end

Then(/^I should see the notice '([^"]*)'$/) do |notice|
  expect(page).to have_xpath('//div[@class="notification"]', text: notice)
end

Then(/^I should see '([^"]*)' in the '([^"]*)' grid$/) do |text, grid_name|
  title = find(:xpath, '//div[@class="grid_container"]/div[@class="grid-header"]/h2', text: grid_name)
  grid_canvas = title.find(:xpath, '../..//div[@class="grid-canvas"]')
  expect(grid_canvas).to have_content(text)
end
