Feature: User Authentication
  As a user of the CUHK Booking System
  I want to register and login
  So that I can access the booking system

  Scenario: Register a new account
    When I register with email "alice@example.com" and username "alice" and password "password123"
    Then I should receive a successful registration response
    And the response should contain my user details

  Scenario: Login with valid credentials
    Given a user exists with email "bob@example.com" and password "password123"
    When I login with email "bob@example.com" and password "password123"
    Then I should receive a valid access token
    And I should receive a valid refresh token

  Scenario: Login with invalid credentials
    Given a user exists with email "charlie@example.com" and password "password123"
    When I login with email "charlie@example.com" and password "wrongpassword"
    Then I should receive an unauthorized error

  Scenario: Access protected endpoint without token
    When I request my profile without a token
    Then I should receive an unauthorized error
