Feature: Admin Force Cancel
  As an administrator
  I want to force-cancel bookings without penalizing users
  So that I can handle emergency situations

  Background:
    Given a tenant "CS Department" exists
    And a venue "LT1" exists in "CS Department" with capacity 200
    And a user "admin1" exists in "CS Department" with role "admin"
    And a user "victim" exists in "CS Department" with 100 points

  Scenario: Admin force-cancels a booking without point deduction
    Given I am authenticated as "admin1"
    And user "victim" has a confirmed booking for venue "LT1" in 1 hours
    When I force cancel the booking with reason "Emergency maintenance"
    Then the force-cancelled booking should be cancelled
    And no points should be deducted from "victim"

  Scenario: Non-admin cannot force-cancel
    Given I am authenticated as "victim"
    And user "victim" has a confirmed booking for venue "LT1" in 3 days
    When I try to force cancel the booking
    Then I should receive a forbidden error
