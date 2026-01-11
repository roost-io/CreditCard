Feature: Credit Card Notification System

Scenario: Credit Card Due Reminder
  Given the API base URL 'http://localhost:3000'
  And the credit card due date is '01/12/2022'
  When I send a POST request to '/send-reminder' with payload { "dueDate": "01/12/2022" }
  Then the response status should be 200
  And the response should contain 'Reminder is sent on 30/11/2022'
  # Edge Case: If the card due date falls on a holiday, the reminder should still be sent one day prior.
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Overdue Balance Alert
  Given the API base URL 'http://localhost:3000'
  And the payment due date was '01/12/2022'
  When I send a POST request to '/send-overdue-alert' with payload { "currentDate": "02/12/2022", "dueDate": "01/12/2022" }
  Then the response status should be 200
  And the response should contain 'Alert should be sent on 02/12/2022'
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Collection Notification
  Given the API base URL 'http://localhost:3000'
  And the account is significantly delinquent
  When I send a POST request to '/send-collection-notification' with payload { "accountStatus": "delinquent" }
  Then the response status should be 200
  And the response should contain 'Collection Notification is sent detailing the amount owed and additional charges'
  # Edge Case: Ensure account classification is accurate and not sending notices to accounts just day(s) past due.
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Payment Plan Proposal
  Given the API base URL 'http://localhost:3000'
  And the user informs about inability to pay
  When I send a POST request to '/offer-payment-plan' with payload { "userStatus": "unable to pay" }
  Then the response status should be 200
  And the response should contain 'A payment plan proposal is offered with reduced interest rates or fees'
  # Edge Case: This feature should not be triggered by the user in good standing or with minor delinquency.
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Collection Agency Involvement
  Given the API base URL 'http://localhost:3000'
  And the cardholder fails to respond to previous notifications and reminders
  When I send a POST request to '/involve-collection-agency' with payload { "responseStatus": "no response" }
  Then the response status should be 200
  And the response should contain 'Collection agency is involved in the process'
  # Edge Case: Ensure collection agency involvement threshold is accurate, can't involve agency just a few days after the payment due date.
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Legal Action Initiation
  Given the API base URL 'http://localhost:3000'
  And there are extreme cases of non-payment or default
  When I send a POST request to '/initiate-legal-action' with payload { "caseStatus": "extreme non-payment" }
  Then the response status should be 200
  And the response should contain 'Legal action is initiated'
  # Edge Case: There should be a rigorous confirmation procedure before initiating legal action to prevent undeserved legal hassles to the user.
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Performance Testing - Load Handling
  Given the API base URL 'http://localhost:3000'
  When I simulate sending notifications to all users
  Then the system should handle the load without performance degradation
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Performance Testing - Alert System Speed
  Given the API base URL 'http://localhost:3000'
  When I test the alert system with thousands of cardholders
  Then the system should work swiftly and promptly
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Usability Testing
  Given the API base URL 'http://localhost:3000'
  When I review the notification messages
  Then the messages should be clear and understandable to the cardholders
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Security Testing
  Given the API base URL 'http://localhost:3000'
  When I test interactions involving sensitive cardholder data
  Then the data should be protected
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Compatibility Testing
  Given the API base URL 'http://localhost:3000'
  When I test notifications across different device types
  Then the notifications should be delivered effectively
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Recovery Testing
  Given the API base URL 'http://localhost:3000'
  When I simulate system crashes or hardware failures
  Then the system should recover without losing critical data
  # Comment: This test is created by Divyesh Maheshwari

Scenario: Reliability Testing
  Given the API base URL 'http://localhost:3000'
  When I test the system's continuous operation over a long period
  Then the system should perform its functions without disruption
  # Comment: This test is created by Divyesh Maheshwari
