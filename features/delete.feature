@javascript
Feature: Delete objects
  In order to delete data in the database
  As a user
  I want to be able to delete rows

  Scenario: Update data using the standard update popup
    Given I have 2 people in the database
    When I go to the homepage
    When I click on 'People'
    Then I should see the 'People' grid
    When I click on the first row of the 'People' grid
    When I click on 'Delete' button on the grid header
    Then I should see the 'Confirmation' popup
    When I confirm
    Then 1 rows should be loaded in the 'People' grid
