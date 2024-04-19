Feature: Credit Card Due and Missed Payment Notifications

Scenario: Credit Card Due Reminder
Given the base API endpoint '/cardholder-notifications'
When I POST notification to '/due-reminder'
Then the response status should be 200
And the response body should contain 'Payment for card XXXX is due soon'

Scenario: Include last 4 digits in Due Reminder
Given the automated notification to cardholder
When I look into the 'card_last_4_digits' key 
Then the response should contain valid 4-digit number 

Scenario: Overdue Balance Alert
Given the base API endpoint '/cardholder-notifications'
When I POST alert to '/overdue-alert'
Then the response status should be 200
And the response body should contain 'Payment for card XXXX is overdue'

Scenario: Include last 4 digits in Overdue Alert
Given the overdue balance alert
When I look into the 'card_last_4_digits' key 
Then the response should contain valid 4-digit number 

Scenario: Collection Notification
Given the base API endpoint '/cardholder-notifications'
When I POST notification to '/collection-notice'
Then the response status should be 200
And the response body should contain 'Account on card XXXX is significantly delinquent'

Scenario: Payment Plan Proposal
Given the base API endpoint '/cardholder-notifications'
When I POST proposal to '/payment-proposal'
Then the response status should be 200
And the response body should contain 'We have a payment plan proposal for your card XXXX'

Scenario: Collection Agency Involvement
Given the base API endpoint '/cardholder-notifications'
When I POST notice to '/collection-agency-notice'
Then the response status should be 200
And the response body should contain 'Collection agency will be involved for card XXXX'

Scenario: Legal Action Initiation
Given the base API endpoint '/cardholder-notifications'
When I POST notice to '/legal-action-notice'
Then the response status should be 200
And the response body should contain 'Legal action initiated for card XXXX due to non-payment or default'

Feature: Non-functional Test Cases

Scenario: Validation of Security
Given cardholder communication or collection document
When I look into the 'card_number' key 
Then the response should contain only last 4 digits of the card number
And full credit card number should not be visible

Scenario: Validation of Performance
Given a large batch of notifications 
When I POST notifications to '/batch-notifications'
Then the response status should be 200
And the response body should contain 'Notifications sent successfully'

Scenario: Validation of Reliability
Given regular functioning of the system
When I look into the 'system_status' 
Then the response should contain 'Running smoothly'

Scenario: Validation of Usability
Given any notification sent to cardholder
When I look into the 'notification_message' 
Then the language should be easy and steps should be clear
