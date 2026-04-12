Feature: Recurring Bookings
  As a registered user
  I want to create recurring bookings
  So that I can reserve weekly meeting slots

  Background:
    Given a tenant "CS Department" exists
    And a venue "LT1" exists in "CS Department" with capacity 200
    And a user "recuruser" exists in "CS Department" with 100 points

  Scenario: Create weekly recurring booking
    Given I am authenticated as "recuruser"
    When I create a weekly recurring booking for venue "LT1" for 3 weeks
    Then 3 bookings should be created
    And all bookings should have status "pending"

  Scenario: Recurring booking skips conflicting slots
    Given I am authenticated as "recuruser"
    And a confirmed booking exists for venue "LT1" from "10:00" to "12:00" tomorrow
    When I create a daily recurring booking for venue "LT1" for 3 days
    Then at least 2 bookings should be created
