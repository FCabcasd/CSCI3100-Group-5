Feature: Booking Check-In
  As a user with a confirmed booking
  I want to check in on-site
  So the system knows I am using the resource

  Background:
    Given a tenant "CS Department" exists
    And a venue "LT1" exists in "CS Department" with capacity 200
    And a user "checkinuser" exists in "CS Department" with 100 points

  Scenario: Successfully check in to a confirmed booking
    Given I am authenticated as "checkinuser"
    And I have a confirmed booking for venue "LT1" starting now
    When I check in to the booking
    Then the check-in should be successful

  Scenario: Cannot check in to a pending booking
    Given I am authenticated as "checkinuser"
    And I have a pending booking for venue "LT1"
    When I check in to the booking
    Then I should receive a bad request error

  Scenario: Cannot check in twice
    Given I am authenticated as "checkinuser"
    And I have a confirmed booking for venue "LT1" starting now
    And the booking is already checked in
    When I check in to the booking
    Then I should receive a bad request error
