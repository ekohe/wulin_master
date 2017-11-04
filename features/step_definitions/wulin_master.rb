# frozen_string_literal: true

Then(/^I should see the '([^"]*)' grid$/) do |grid_name|
  expect(page).to have_xpath('//div[@class="grid_container"]/div[@class="grid-header"]/h2', text: grid_name)
end

Then(/^I should see the '([^"]*)' popup$/) do |dialog_title|
  expect(page).to have_xpath('//h5[@class="title"]', text: dialog_title)
end

Then(/^I should see the notice '([^"]*)'$/) do |notice|
  expect(page).to have_xpath('//div[@class="notification"]', text: notice)
end

Then(/^I should see '([^"]*)' in the '([^"]*)' grid$/) do |text, grid_name|
  title = find(:xpath, '//div[@class="grid_container"]/div[contains(@class, "grid-header")]/h2', text: grid_name)
  grid_canvas = title.find(:xpath, '../..//div[@class="grid-canvas"]')
  expect(grid_canvas).to have_content(text)
end

Then(/^(\d+) rows should be loaded in the '([^"]*)' grid$/) do |number_of_rows, grid_name|
  singular_grid_name = grid_name.singularize.downcase
  last_row = page.evaluate_script("gridManager.getGrid('#{singular_grid_name}').getData()[#{number_of_rows.to_i - 1}]")
  expect(last_row).not_to eq(nil)
  expect(last_row["slick_index"]).to eq(number_of_rows.to_i - 1)
end

When(/^I click on the first row of the '([^"]*)' grid$/) do |grid_name|
  title = find(:xpath, '//div[@class="grid_container"]/div[contains(@class, "grid-header")]/h2', text: grid_name)
  grid_canvas = title.find(:xpath, '../..//div[@class="grid-canvas"]')
  first_row = grid_canvas.find(:xpath, './div[1]')
  first_row.click
end

When(/^I scroll down for (\d+)px$/) do |scroll|
  page.execute_script("$('.slick-viewport')[0].scrollTop = $('.slick-viewport')[0].scrollTop + #{scroll.to_i}")
end
