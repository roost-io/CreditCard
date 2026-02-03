Feature: API Testing for BambooHR and Okta Integration

Background:
  Given the API base URL for BambooHR is 'https://api.bamboohr.com/api/gateway.php/subdomain/v1'
  And the API base URL for Okta is 'https://dev-123456.okta.com/api/v1'
  And the content type is 'application/json'
  And the authorization header is set with valid API keys

Scenario: Fetch BambooHR Employees
  Given the BambooHR API key is valid
  When I send a GET request to '/employees/active?fields=firstName,workEmail'
  Then the response status should be 200
  And the response should contain a list of active employees with 'firstName' and 'workEmail'
  And if the API key is invalid
    Then the response status should be 401
    And the response should contain 'Invalid API key'
  And if there are no active employees
    Then the response should be an empty array

Scenario: Check Okta User Exists
  Given a valid email address of an existing user in Okta
  When I send a GET request to '/users?filter=profile.email eq "user@example.com"'
  Then the response status should be 200
  And the response should contain the Okta user object
  And if the email does not exist
    Then the response should be null
  And if the email format is invalid
    Then the response status should be 400
    And the response should contain 'Invalid email format'

Scenario: Create Okta User Profile
  Given a valid BambooHR employee object
  When I send a POST request to '/users' with the employee object
  Then the response status should be 201
  And the response should contain a valid Okta user profile object
  And if the email is missing in the employee object
    Then the response status should be 400
    And the response should contain 'Email is required'
  And if optional fields like mobilePhone are missing
    Then the response should still contain a valid profile

Scenario: Create Okta User
  Given a valid Okta user profile
  When I send a POST request to '/users' with the user profile
  Then the response status should be 201
  And the response should contain the created user object
  And if the email is a duplicate
    Then the response status should be 409
    And the response should contain 'Duplicate email'
  And if the user profile format is invalid
    Then the response status should be 400
    And the response should contain 'Invalid user profile format'

Scenario: Update Existing Okta User
  Given a valid Okta user ID and updated profile data
  When I send a PUT request to '/users/{userId}' with the updated data
  Then the response status should be 200
  And the response should contain the updated user object
  And if the user ID is invalid
    Then the response status should be 404
    And the response should contain 'User not found'
  And if the profile data is invalid
    Then the response status should be 400
    And the response should contain 'Invalid profile data'

Scenario: Assign User to Groups
  Given a valid Okta user ID, department, and job title
  When I send a PUT request to '/users/{userId}/groups' with department and job title
  Then the response status should be 200
  And the user should be assigned to appropriate groups
  And if the user ID is invalid
    Then the response status should be 404
    And the response should contain 'User not found'
  And if the department does not exist
    Then no group should be assigned

Scenario: Provision Users
  Given options for provisioning such as dryRun and updateExisting
  When I send a POST request to '/provision' with the options
  Then the response status should be 200
  And the response should contain a summary of processed, created, and updated users
  And if there is a network failure
    Then the system should log an error and continue processing
  And if the provisioning options are invalid
    Then the response status should be 400
    And the response should contain 'Invalid provisioning options'

Scenario: Sync Single Employee
  Given a valid BambooHR employee ID
  When I send a POST request to '/sync/{employeeId}'
  Then the response status should be 200
  And the response should indicate successful synchronization
  And if the employee ID does not exist
    Then the response status should be 404
    And the response should contain 'Employee not found'
  And if the employee is not active
    Then a message should be logged and processing should be skipped

Scenario: Performance Testing for Fetching Employees
  Given a large number of employees in BambooHR
  When I perform a GET request to '/employees/active'
  Then the response time should be within acceptable limits
  And the system should not time out or crash

Scenario: Security Testing for API Authentication
  Given invalid API keys for BambooHR and Okta
  When I attempt to access the API
  Then the response status should be 401
  And the system should log unauthorized access attempts
  And sensitive error messages should not be exposed

Scenario: Scalability Testing for User Provisioning
  Given a large batch of users to be provisioned
  When I perform provisioning from BambooHR to Okta
  Then the system should handle the batch efficiently
  And there should be no degradation in performance

Scenario: Reliability Testing for Network Failures
  Given simulated network interruptions during API calls
  When I perform API operations
  Then the system should handle failures gracefully and retry
  And data integrity and consistency should be maintained

Scenario: Usability Testing for Log Messages
  Given various operations like fetching employees and creating users
  When I check the log messages
  Then they should be clear, informative, and easily understandable
  And log messages should not contain sensitive information
