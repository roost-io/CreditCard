Feature: Credit Card Application and Management API Testing

Background:
  Given the API base URL 'http://api.bank.com'
  And the authorization header is set
  And the content type is 'application/json'

Scenario: Credit Card Application Submission
  Given the API endpoint '/credit-card/apply'
  And the request payload contains valid identification, income details, and contact information
  When I send a POST request to the endpoint
  Then the response status should be 201
  And the response should contain a confirmation message 'Application submitted successfully'

Scenario: Credit Card Application Error Handling
  Given the API endpoint '/credit-card/apply'
  And the request payload contains invalid or incomplete information
  When I send a POST request to the endpoint
  Then the response status should be 400
  And the response should contain an error message 'Invalid or incomplete information'

Scenario: Waiving Off Charges
  Given the API endpoint '/credit-card/waive-charges'
  And the request payload contains the unexpected fee details
  When I send a POST request to the endpoint
  Then the response status should be 200
  And the response should confirm 'Charges waived successfully'

Scenario: Redeeming Reward Points
  Given the API endpoint '/credit-card/redeem-points'
  And the request payload contains the reward choice and points to redeem
  When I send a POST request to the endpoint
  Then the response status should be 200
  And the response should confirm 'Rewards claimed successfully'

Scenario: Credit Limit Extension
  Given the API endpoint '/credit-card/credit-limit/increase'
  And the request payload contains the customer's creditworthiness details
  When I send a POST request to the endpoint
  Then the response status should be 200
  And the response should confirm 'Credit limit increased'

Scenario: Credit Limit Reduction
  Given the API endpoint '/credit-card/credit-limit/decrease'
  And the request payload contains the customer's financial situation details
  When I send a POST request to the endpoint
  Then the response status should be 200
  And the response should confirm 'Credit limit reduced'

Scenario: Promotional Balance Transfers
  Given the API endpoint '/credit-card/balance-transfer'
  And the request payload contains the balance transfer details under promotional terms
  When I send a POST request to the endpoint
  Then the response status should be 200
  And the response should confirm 'Balance transferred successfully under promotional terms'

Scenario: System Response Time for Credit Card Application
  Given the API endpoint '/credit-card/apply'
  And the request payload contains valid information
  When I send a POST request to the endpoint
  Then the response time should be less than 2 seconds

Scenario: Handling Multiple Credit Card Applications
  Given the API endpoint '/credit-card/apply'
  And multiple request payloads contain valid information
  When I send multiple POST requests to the endpoint simultaneously
  Then the system should handle all requests without performance degradation

Scenario: System Behavior on Connection Loss
  Given the API endpoint '/credit-card/apply'
  And the request payload contains valid information
  When I simulate a connection loss during the application process
  And I restore the connection
  Then I should be able to resume the application process without data loss

Scenario: Secure Protocols for Data Entry and Storage
  Given the API endpoint '/credit-card/apply'
  And the request payload contains personal and financial data
  When I monitor the network traffic
  Then all data entry and storage processes should use secure protocols such as HTTPS and encryption

Scenario: Maximum Attempts for Unsuccessful Applications
  Given the API endpoint '/credit-card/apply'
  And the request payload contains invalid data
  When I send multiple POST requests to the endpoint
  And I reach the maximum allowed attempts
  Then the response should contain a message 'Maximum attempts reached, please try again later'

Scenario: Notification on Successful Actions
  Given the API endpoint '/credit-card/actions'
  And the request payload contains actions like fee waiving, points redemption, or credit limit update
  When I send a POST request to the endpoint
  Then the customer should receive a notification for each successful action performed

Scenario: Data Integrity During Balance Transfers
  Given the API endpoint '/credit-card/balance-transfer'
  And the request payload contains balance transfer details under a promotional offer
  When I send a POST request to the endpoint
  Then data integrity should be maintained throughout the balance transfer process
