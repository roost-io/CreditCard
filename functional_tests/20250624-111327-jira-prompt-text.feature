Feature: Credit Card Notification System

Scenario: Credit Card Due Reminder Notification
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder with an upcoming payment due date
  When I send a POST request to '/notifications/due-reminder' with the cardholder's details
  Then the response status should be 200
  And the response should confirm that a notification is sent
  And the notification should be sent even if the due date falls on a weekend or public holiday

Scenario: Overdue Balance Alert
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder who has missed their payment due date
  When I send a POST request to '/notifications/overdue-alert' with the cardholder's details
  Then the response status should be 200
  And the response should confirm that an alert is sent
  And the alert should be sent immediately after the due date is missed

Scenario: Collection Notification
  Given the API base URL 'http://api.creditcard.com'
  And an account that has become significantly delinquent
  When I send a POST request to '/notifications/collection' with the account details
  Then the response status should be 200
  And the response should confirm that a collection notification is sent
  And the notification should include all applicable charges and be sent to the correct contact details

Scenario: Payment Plan Proposal
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder unable to pay the full overdue balance at once
  When I send a POST request to '/notifications/payment-plan' with the cardholder's details
  Then the response status should be 200
  And the response should confirm that a payment plan proposal is offered
  And the proposal should be customizable based on the cardholder's financial situation

Scenario: Collection Agency Involvement
  Given the API base URL 'http://api.creditcard.com'
  And a cardholder fails to respond to previous notifications and reminders
  When I send a POST request to '/notifications/collection-agency' with the cardholder's details
  Then the response status should be 200
  And the response should confirm that a collection agency is involved
  And the cardholder should be notified before the collection agency is involved

Scenario: Legal Action Initiation
  Given the API base URL 'http://api.creditcard.com'
  And extreme cases of non-payment or default by the cardholder
  When I send a POST request to '/notifications/legal-action' with the cardholder's details
  Then the response status should be 200
  And the response should confirm that legal action is initiated
  And all prior notifications and attempts to contact the cardholder should be documented before legal action is taken

Scenario: Notification Delivery Time
  Given the API base URL 'http://api.creditcard.com'
  And various network conditions
  When I send a POST request to '/notifications/test-delivery-time' with network condition details
  Then the response status should be 200
  And notifications should be delivered within a reasonable time frame regardless of network conditions
  And test under low bandwidth and high latency conditions

Scenario: System Load Handling
  Given the API base URL 'http://api.creditcard.com'
  And a high volume of notifications to be sent simultaneously
  When I send a POST request to '/notifications/test-load-handling' with load details
  Then the response status should be 200
  And the system should handle the load without performance degradation
  And simulate peak times with maximum notification load

Scenario: Security and Privacy
  Given the API base URL 'http://api.creditcard.com'
  And access to cardholder's personal and financial information
  When I send a POST request to '/notifications/test-security' with security details
  Then the response status should be 200
  And data should be encrypted and access restricted to authorized personnel only
  And attempt unauthorized access to test security measures

Scenario: Usability of Notifications
  Given the API base URL 'http://api.creditcard.com'
  And notifications received by cardholders
  When I send a POST request to '/notifications/test-usability' with notification details
  Then the response status should be 200
  And notifications should be clear, concise, and easy to understand
  And test with users of different demographics to ensure clarity

Scenario: System Recovery
  Given the API base URL 'http://api.creditcard.com'
  And a system failure during notification sending process
  When I send a POST request to '/notifications/test-recovery' with failure details
  Then the response status should be 200
  And the system should recover and resume sending notifications without data loss
  And simulate a sudden system crash and observe recovery process
