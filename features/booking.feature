Feature: Venue Booking
  As a registered user
  I want to book venues
  So that I can reserve spaces for my events

  Background:
    Given a tenant "CS Department" exists
    And a venue "LT1" exists in "CS Department" with capacity 200
    And a user "testuser" exists in "CS Department" with 100 points

  Scenario: Successfully create a booking
    Given I am authenticated as "testuser"
    When I create a booking for venue "LT1" from "10:00" to "12:00" tomorrow
    Then the booking should be created with status "pending"
    And a confirmation email should be sent

  Scenario: Detect venue conflict
    Given I am authenticated as "testuser"
    And a confirmed booking exists for venue "LT1" from "10:00" to "12:00" tomorrow
    When I create a booking for venue "LT1" from "11:00" to "13:00" tomorrow
    Then I should receive a conflict error

  Scenario: Cancel a booking early
    Given I am authenticated as "testuser"
    And I have a confirmed booking for venue "LT1" in 3 days
    When I cancel the booking with reason "Changed plans"
    Then the booking should be cancelled
    And no points should be deducted
    And a cancellation email should be sent

  Scenario: Late cancellation deducts points
    Given I am authenticated as "testuser"
    And I have a confirmed booking for venue "LT1" in 2 hours
    When I cancel the booking with reason "Emergency"
    Then the booking should be cancelled
    And 10 points should be deducted from "testuser"
