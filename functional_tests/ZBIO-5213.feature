Feature: Credit Card Due Remote Notification Testing

Scenario Outline: Testing various API endpoints for credit card due notifications

Given the API base URL 'http://localhost:3000'

When I send a POST request to '/credit-card-due-reminder' with '<credit_card_id>' and '<near_due_date>'
Then the response status should be 200
And the response should contain 'automated notification has been sent'
And the response body should include 'last 4 digits' of '<credit_card_id>'

When I send a POST request to '/overdue-balance-alert' with '<credit_card_id>' and '<skip_due_date>'
Then the response status should be 200
And the response should contain 'overdue balance alert has been generated'
And the response body should include 'last 4 digits' of '<credit_card_id>'

When I send a POST request to '/collection-notification' with '<credit_card_id>' and '<delinquent_date>'
Then the response status should be 200
And the response should contain 'collection notification has been sent'
And the response body should include 'last 4 digits' of '<credit_card_id>'

When I send a POST request to '/payment-plan-proposal' with '<credit_card_id>' and '<inability_date>'
Then the response status should be 200
And the response should contain 'payment plan proposal has been sent'
And the response body should include 'last 4 digits' of '<credit_card_id>'

When I send a POST request to '/collection-agency' with '<credit_card_id>' and '<nonresponse_date>'
Then the response status should be 200
And the response should contain 'collection agency has been notified'
And the response body should include 'last 4 digits' of '<credit_card_id>'

When I send a POST request to '/legal-action-initiation' with '<credit_card_id>' and '<non_payment_date>'
Then the response status should be 200
And the response should contain 'legal action initiation documentation has been sent'
And the response body should include 'last 4 digits' of '<credit_card_id>'

Examples:
|credit_card_id|near_due_date|skip_due_date|delinquent_date|inability_date|nonresponse_date|non_payment_date|
|1234567890123456|2022-05-01|2022-05-02|2022-05-30|2022-06-01|2022-06-10|2022-06-15|

Feature: Non Functional Testing: Performance, Security, UI, Error Handling, Compatibility and Interruption Handling

Scenario: Testing system behavior under heavy load

Given the API Base URL is 'http://localhost:3000'
And the system is fully operational
When I stress test the system by sending hundreds of API requests simultaneously
Then the system should continue to respond in a timely manner
And the response status should always be 200

Scenario: Validate system security features

Given the API Base URL is 'http://localhost:3000'
When I send a GET request to '/view-full-card-details'
Then the response status should be 403
And the response should state 'full card details are not accessible'

Scenario: Testing UI for notifications

Given the API Base URL is 'http://localhost:3000'
When I send a GET request to '/view-notifications'
Then the notifications should be easily readable and correctly displayed

Scenario: Test error handling

Given the API Base URL is 'http://localhost:3000'
When I send a POST request to 'nonexistent-endpoint'
Then the response status should be 404
And the response should clearly define the error

Scenario: Test compatibility

Given the API Base URL is 'http://localhost:3000'
When I perform the test from different devices and mail clients
Then the notifications should be displayed correctly

Scenario: Interruption handling and recovery

Given the API Base URL is 'http://localhost:3000'
When I simulate an interruption like power outage or system crash
Then the system should recover and continue operation without data loss

Scenario: Load balancing

Given the API Base URL is 'http://localhost:3000'
When I simulate high traffic to the system
Then the system should balance the load and continue to respond without delay
