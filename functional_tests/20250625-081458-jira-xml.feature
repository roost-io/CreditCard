# This test is created by Divyesh Maheshwari.

Feature: API Testing for Credit Card Notification System

  Scenario: Credit Card Due Reminder
    Given the API base URL 'http://localhost:3000'
    And the credit card due date is '01/12/2022'
    When I send a GET request to '/send-reminder?dueDate=01/12/2022'
    Then the response status should be 200
    And the response should contain 'Reminder sent on 30/11/2022'
    And the reminder should be sent even if the due date is a holiday

  Scenario: Overdue Balance Alert
    Given the API base URL 'http://localhost:3000'
    And the current date is '02/12/2022'
    And the payment due date was '01/12/2022'
    When I send a GET request to '/send-overdue-alert?dueDate=01/12/2022'
    Then the response status should be 200
    And the response should contain 'Alert sent on 02/12/2022'

  Scenario: Collection Notification
    Given the API base URL 'http://localhost:3000'
    And the account is significantly delinquent
    When I send a POST request to '/send-collection-notification' with payload '{ "accountStatus": "delinquent" }'
    Then the response status should be 200
    And the response should contain 'Collection Notification sent with amount owed and additional charges'
    And ensure account classification is accurate

  Scenario: Payment Plan Proposal
    Given the API base URL 'http://localhost:3000'
    And the user informs about inability to pay
    When I send a POST request to '/offer-payment-plan' with payload '{ "userStatus": "unable to pay" }'
    Then the response status should be 200
    And the response should contain 'Payment plan proposal offered with reduced interest rates or fees'
    And this feature should not trigger for users in good standing or with minor delinquency

  Scenario: Collection Agency Involvement
    Given the API base URL 'http://localhost:3000'
    And the cardholder fails to respond to previous notifications
    When I send a POST request to '/involve-collection-agency' with payload '{ "responseStatus": "no response" }'
    Then the response status should be 200
    And the response should contain 'Collection agency involved'
    And ensure agency involvement threshold is accurate

  Scenario: Legal Action Initiation
    Given the API base URL 'http://localhost:3000'
    And there are extreme cases of non-payment or default
    When I send a POST request to '/initiate-legal-action' with payload '{ "caseStatus": "extreme default" }'
    Then the response status should be 200
    And the response should contain 'Legal action initiated'
    And there should be a rigorous confirmation procedure before initiation

  Scenario: Performance Testing for Notification System
    Given the API base URL 'http://localhost:3000'
    When I simulate sending notifications to all users
    Then the system should handle the load efficiently
    And the alert system should work swiftly and promptly

  Scenario: Usability Testing for Notification Messages
    Given the API base URL 'http://localhost:3000'
    When I review the notification messages
    Then the messages should be clear and understandable to cardholders

  Scenario: Security Testing for Cardholder Data
    Given the API base URL 'http://localhost:3000'
    When I test the API interactions
    Then sensitive cardholder data should be protected

  Scenario: Compatibility Testing for Notification Delivery
    Given the API base URL 'http://localhost:3000'
    When I test notification delivery across devices
    Then notifications should be delivered effectively on PCs, mobile phones, and tablets

  Scenario: Recovery Testing for System Failures
    Given the API base URL 'http://localhost:3000'
    When I simulate system crashes and hardware failures
    Then the system should recover without losing critical data

  Scenario: Reliability Testing for Continuous Operation
    Given the API base URL 'http://localhost:3000'
    When I test the system's continuous operation over time
    Then the system should perform its functions without disruption
