@javascript
Feature: Create objects
  In order to fill data in the database
  As a user
  I want to be able to create rows

  Scenario: Create data using the standard create popup
    Given I go to the homepage
    When I click on 'People'
    Then I should see the 'People' grid
    When I click on 'Create'
    Then I should see the 'Create new Person' popup
    When I enter 'Maxime' in 'First name'
    And I enter 'Guilbot' in 'Last name'
    And I enter '28/08/1982' in 'Birthdate'
    When I press ' Create '
    Then I should see the notice 'Person successfully created'
    Then take a screenshot
    And I should see 'Maxime' in the 'People' grid
    And I should see 'Guilbot' in the 'People' grid
    And I should see '28/08/1982' in the 'People' grid
