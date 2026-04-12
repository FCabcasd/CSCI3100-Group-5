Feature: Admin Management
  As an administrator
  I want to manage users and bookings
  So that I can maintain the booking system

  Background:
    Given a tenant "CS Department" exists
    And a user "admin1" exists in "CS Department" with role "admin"
    And a user "regularuser" exists in "CS Department" with 100 points

  Scenario: Admin lists all users
    Given I am authenticated as "admin1"
    When I request the user list
    Then I should see a list of users

  Scenario: Admin confirms a booking
    Given I am authenticated as "admin1"
    And a pending booking exists
    When I confirm the booking
    Then the booking status should be "confirmed"

  Scenario: Admin suspends a user
    Given I am authenticated as "admin1"
    When I suspend user "regularuser"
    Then the user "regularuser" should be suspended

  Scenario: Non-admin cannot access admin endpoints
    Given I am authenticated as "regularuser"
    When I request the user list
    Then I should receive a forbidden error
