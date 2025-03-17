Feature: Credit Card Notification System

Scenario: Credit Card Due Reminder Notification
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder with an upcoming payment due date
  When I send a POST request to '/notifications/due-reminder' with payload:
    | cardholderId | dueDate     |
    | 12345        | 2023-11-15  |
  Then the response status should be 200
  And the response should contain 'Notification sent to cardholder with card ending in 1234'
  And the notification should be sent even if the due date falls on a weekend or holiday

Scenario: Overdue Balance Alert
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder who missed the payment due date
  When I send a POST request to '/notifications/overdue-alert' with payload:
    | cardholderId | overdueAmount |
    | 12345        | 150.00        |
  Then the response status should be 200
  And the response should contain 'Alert sent to cardholder with card ending in 1234 detailing overdue balance'
  And the alert should reflect the correct overdue amount even if a partial payment was made

Scenario: Collection Notification
  Given the API base URL 'http://api.creditcard.com'
  And an account that becomes significantly delinquent
  When I send a POST request to '/notifications/collection' with payload:
    | cardholderId | delinquentAmount |
    | 12345        | 500.00           |
  Then the response status should be 200
  And the response should contain 'Collection notification sent with card ending in 1234'
  And the notification should not be sent if the account is under dispute

Scenario: Payment Plan Proposal
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder unable to pay the full overdue balance
  When I send a POST request to '/notifications/payment-plan' with payload:
    | cardholderId | proposedPlan |
    | 12345        | Plan A       |
  Then the response status should be 200
  And the response should contain 'Proposal sent with repayment schedule for card ending in 1234'
  And the proposal should include accurate interest rates or fees

Scenario: Collection Agency Involvement
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder who fails to respond to previous notifications
  When I send a POST request to '/notifications/collection-agency' with payload:
    | cardholderId | agencyId |
    | 12345        | 67890    |
  Then the response status should be 200
  And the response should contain 'Collection agency involved with card ending in 1234'
  And data should be securely transferred to the collection agency

Scenario: Legal Action Initiation
  Given the API base URL 'http://api.creditcard.com'
  And extreme cases of non-payment or default
  When I send a POST request to '/notifications/legal-action' with payload:
    | cardholderId | legalActionId |
    | 12345        | 98765         |
  Then the response status should be 200
  And the response should contain 'Legal documentation includes card ending in 1234'
  And legal action should not be initiated if the account is under dispute or negotiation

Scenario: Performance Testing
  Given the API base URL 'http://api.creditcard.com'
  When the system handles a large volume of notifications and alerts simultaneously
  Then notifications and alerts should be sent without delay or system crash
  And system performance should be tested during peak times

Scenario: Security Testing
  Given the API base URL 'http://api.creditcard.com'
  When notifications are sent
  Then only the last 4 digits of the credit card number should be included
  And no full credit card numbers should be displayed or shared in plain text
  And test for vulnerabilities such as CWE-200 and CWE-522

Scenario: Usability Testing
  Given the API base URL 'http://api.creditcard.com'
  When notifications and alerts are sent
  Then notifications should be clear, concise, and provide necessary information
  And test for readability on different devices and screen sizes

Scenario: Reliability Testing
  Given the API base URL 'http://api.creditcard.com'
  When notifications and alerts are sent
  Then the system should consistently send notifications and alerts without failure
  And the system should recover after a failure or outage

Scenario: Compliance Testing
  Given the API base URL 'http://api.creditcard.com'
  When notifications and processes are executed
  Then all notifications and processes should comply with relevant regulations and standards
  And changes in regulations should be promptly reflected in the system processes
