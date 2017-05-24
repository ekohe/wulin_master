@javascript
Feature: Create objects
  In order to fill data in the database
  As a user
  I want to be able to create rows

  Scenario: Create data using the standard create popup
    Given I go to the homepage
    When I click on 'People'
    Then I should see the 'People' grid
    When I click on 'Add'
    Then I should see the 'Create new Person' popup
    When I enter 'Maxime' in 'First name'
    And I enter 'Guilbot' in 'Last name'
    # And I enter '28/08/1982 10:10' in 'Birthdate'
    # And I press the 'return' key
    When I press ' Create '
    Then I should see the notice 'Record successfully created!'
    And I should see 'Maxime' in the 'People' grid
    And I should see 'Guilbot' in the 'People' grid
    # And I should see '28/08/1982 10:10' in the 'People' grid
