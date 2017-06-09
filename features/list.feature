@javascript
Feature: List objects
  In order to explore data in the database
  As a user
  I want to be able to list all the rows

  Scenario: Explore data scrolling the grid
    Given I have 1000 people in the database
    When I go to the homepage
    And I click on 'People'
    Then I should see the 'People' grid
    Given I wait for 0.1 second
    Then 200 rows should be loaded in the 'People' grid
    When I click on the first row of the 'People' grid
    And I scroll down for 2500px
    Given I wait for 0.1 second
    Then 400 rows should be loaded in the 'People' grid
