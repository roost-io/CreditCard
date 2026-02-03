Feature: Credit Card Notification System

Scenario: Sending Credit Card Due Reminder
  Given the API base URL 'http://api.creditcard.com'
  And the credit card due date is '01/12/2022'
  When I send a GET request to '/reminder' with the due date as a parameter
  Then the response status should be 200
  And the response should contain a reminder date of '30/11/2022'
  And if the due date is a holiday, the reminder should still be sent one day prior

Scenario: Sending Overdue Balance Alert
  Given the API base URL 'http://api.creditcard.com'
  And today's date is '02/12/2022' and the payment due date was '01/12/2022'
  When I send a GET request to '/overdue-alert' with the due date as a parameter
  Then the response status should be 200
  And the response should contain an alert sent on '02/12/2022'

Scenario: Sending Collection Notification
  Given the API base URL 'http://api.creditcard.com'
  And the account is significantly delinquent
  When I send a GET request to '/collection-notification'
  Then the response status should be 200
  And the response should contain details of the amount owed and additional charges
  And ensure accurate account classification to avoid sending notices to accounts just days past due

Scenario: Offering Payment Plan Proposal
  Given the API base URL 'http://api.creditcard.com'
  And the user informs about inability to pay
  When I send a POST request to '/payment-plan-proposal' with user details
  Then the response status should be 200
  And the response should contain a payment plan proposal with reduced interest rates or fees
  And this feature should not trigger for users in good standing or with minor delinquency

Scenario: Involving Collection Agency
  Given the API base URL 'http://api.creditcard.com'
  And the cardholder fails to respond to previous notifications and reminders
  When I send a GET request to '/collection-agency-involvement'
  Then the response status should be 200
  And the response should confirm collection agency involvement
  And ensure collection agency involvement threshold is accurate, avoiding agency involvement just days after the payment due date

Scenario: Initiating Legal Action
  Given the API base URL 'http://api.creditcard.com'
  And there are extreme cases of non-payment or default
  When I send a GET request to '/legal-action-initiation'
  Then the response status should be 200
  And the response should confirm legal action initiation
  And there should be a rigorous confirmation procedure before initiating legal action to prevent undeserved legal hassles to the user

Scenario: Performance Testing for Notification System
  Given the API base URL 'http://api.creditcard.com'
  When I simulate sending notifications to all users
  Then the system should handle the load efficiently
  And the alert system should work swiftly and promptly even with thousands of cardholders

Scenario: Usability Testing for Notification Messages
  Given the API base URL 'http://api.creditcard.com'
  When I review the notification messages
  Then the messages should be clear and understandable to the cardholders
  And notifications should use clear and user-friendly language

Scenario: Security Testing for Sensitive Data Protection
  Given the API base URL 'http://api.creditcard.com'
  When I test the interactions for data protection
  Then sensitive cardholder data should be protected
  And the notification delivery platform should be secure and reliable

Scenario: Compatibility Testing for Notification Delivery
  Given the API base URL 'http://api.creditcard.com'
  When I test notification delivery across different devices
  Then notifications should be delivered effectively on PCs, mobile phones, and tablets
  And notifications should be sent reliably without delays

Scenario: Recovery Testing for System Resilience
  Given the API base URL 'http://api.creditcard.com'
  When I simulate system crashes and hardware failures
  Then the system should recover without data loss
  And the system should maintain critical data integrity

Scenario: Reliability Testing for Continuous Performance
  Given the API base URL 'http://api.creditcard.com'
  When I test the system's long-term performance
  Then the system should perform its functions continuously without disruption
  And the system should ensure continuous and uninterrupted performance
