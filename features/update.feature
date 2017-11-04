@javascript
Feature: Update objects
  In order to change data in the database
  As a user
  I want to be able to update row info

  Scenario: Update data using the standard update popup
    Given I have 1 people in the database
    Given I go to the homepage
    When I click on 'People'
    Then I should see the 'People' grid
    When I click on the first row of the 'People' grid
    When I click on 'Edit' button on the grid header
    Then I should see the 'Update Person' popup
    Given I wait for 0.5 second
    When I enter 'Maxime' in 'First name'
    And I enter 'Guilbot' in 'Last name'
    And I enter '28/08/1982' in 'Birthdate'
    When I press ' Update '
    Then I should see the notice '1 person updated'
    And I should see 'Maxime' in the 'People' grid
    And I should see 'Guilbot' in the 'People' grid
    And I should see '28/08/1982' in the 'People' grid
