Feature: API Testing for Credit Card Management System

  # Functional Test Cases

  Scenario: Credit Card Due Reminder
    Given the API base URL 'http://localhost:3000'
    And the credit card due date is '01/12/2022'
    When I send a GET request to '/reminder' with the due date
    Then the response status should be 200
    And the response should contain 'Reminder is sent on 30/11/2022'
    And if the due date is a holiday, the reminder should still be sent one day prior

  Scenario: Overdue Balance Alert
    Given the API base URL 'http://localhost:3000'
    And the payment due date was '01/12/2022'
    When I send a GET request to '/alert' with the current date '02/12/2022'
    Then the response status should be 200
    And the response should contain 'Alert should be sent on 02/12/2022'

  Scenario: Collection Notification
    Given the API base URL 'http://localhost:3000'
    And the account is significantly delinquent
    When I send a GET request to '/collection-notification'
    Then the response status should be 200
    And the response should contain 'Collection Notification detailing the amount owed and additional charges'
    And ensure account classification is accurate

  Scenario: Payment Plan Proposal
    Given the API base URL 'http://localhost:3000'
    And the user informs about the inability to pay
    When I send a POST request to '/payment-plan' with user status
    Then the response status should be 200
    And the response should contain 'A payment plan proposal with reduced interest rates or fees'
    And this feature should not trigger for users in good standing

  Scenario: Collection Agency Involvement
    Given the API base URL 'http://localhost:3000'
    And the cardholder fails to respond to previous notifications
    When I send a GET request to '/collection-agency'
    Then the response status should be 200
    And the response should contain 'Collection agency is involved'
    And ensure agency involvement threshold is accurate

  Scenario: Legal Action Initiation
    Given the API base URL 'http://localhost:3000'
    And there are extreme cases of non-payment or default
    When I send a GET request to '/legal-action'
    Then the response status should be 200
    And the response should contain 'Legal action is initiated'
    And there should be a rigorous confirmation procedure

  # Non-Functional Test Cases

  Scenario: Performance Testing
    Given the API base URL 'http://localhost:3000'
    When I simulate load for sending notifications to all users
    Then the system should handle the load efficiently
    And the alert system should work swiftly even with thousands of cardholders

  Scenario: Usability Testing
    Given the API base URL 'http://localhost:3000'
    When I check the notification messages
    Then the messages should be clear and understandable to the cardholders

  Scenario: Security Testing
    Given the API base URL 'http://localhost:3000'
    When I test the interactions
    Then sensitive cardholder data should be protected

  Scenario: Compatibility Testing
    Given the API base URL 'http://localhost:3000'
    When I deliver notifications across different device types
    Then the notifications should be delivered effectively on PCs, mobile phones, and tablets

  Scenario: Recovery Testing
    Given the API base URL 'http://localhost:3000'
    When the system encounters crashes or hardware failures
    Then the system should recover without losing any critical data

  Scenario: Reliability Testing
    Given the API base URL 'http://localhost:3000'
    When I test the system over a long period
    Then the system should perform its functions continuously without disruption

# Comment: This test is created by Divyesh Maheshwari.
