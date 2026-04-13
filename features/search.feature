Feature: Venue and Equipment Search
  As a registered user
  I want to search for venues and equipment
  So that I can find suitable resources for my events

  Background:
    Given a tenant "CS Department" exists
    And a user "searcher" exists in "CS Department" with 100 points
    And I am authenticated as "searcher"

  Scenario: Search venues by name
    Given a venue "Lecture Theatre 1" exists in "CS Department" with capacity 200
    And a venue "Seminar Room" exists in "CS Department" with capacity 30
    When I search for venues with query "Lecture"
    Then I should see 1 venue in the results
    And the results should include "Lecture Theatre 1"

  Scenario: Search venues with no results
    Given a venue "Lecture Theatre 1" exists in "CS Department" with capacity 200
    When I search for venues with query "Swimming Pool"
    Then I should see 0 venues in the results

  Scenario: Search equipment by name
    Given equipment "HD Projector" exists in "CS Department"
    And equipment "Wireless Microphone" exists in "CS Department"
    When I search for equipment with query "Projector"
    Then I should see 1 equipment in the results

  Scenario: Search requires a query parameter
    When I search for venues with empty query
    Then I should receive a bad request error
