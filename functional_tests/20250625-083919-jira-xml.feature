Feature: API Testing for BambooHR and Okta Integration

Background:
  Given the API base URL for BambooHR is 'https://api.bamboohr.com/api/gateway.php/{subdomain}/v1'
  And the API base URL for Okta is 'https://{oktaDomain}.okta.com/api/v1'
  And the authorization header is set
  And the content type is 'application/json'

Scenario: Fetch BambooHR Employees
  Given a valid BambooHR API key and subdomain
  When I send a GET request to '/employees/directory?fields=firstName,workEmail'
  Then the response status should be 200
  And the response should contain active employees with 'firstName' and 'workEmail'
  And if the API key is invalid, the response status should be 401
  And if there are no active employees, the response should be an empty array

Scenario: Check Okta User Exists
  Given a valid email address of an existing user in Okta
  When I send a GET request to '/users?q={email}'
  Then the response status should be 200
  And the response should contain the Okta user object for the provided email
  And if the email does not exist, the response should be null
  And if the email format is invalid, the response status should be 400

Scenario: Create Okta User Profile
  Given a valid BambooHR employee object with fields like firstName, lastName, workEmail
  When I send a POST request to '/users' with the employee object as payload
  Then the response status should be 201
  And the response should contain a valid Okta user profile object
  And if email is missing in the employee object, the response status should be 400
  And if optional fields like mobilePhone are missing, a valid profile should still be returned

Scenario: Create Okta User
  Given a valid Okta user profile created from BambooHR employee data
  When I send a POST request to '/users' with the Okta user profile as payload
  Then the response status should be 201
  And the response should contain the created user object
  And if the email is duplicate, the response status should be 409
  And if the user profile format is invalid, the response status should be 400

Scenario: Update Existing Okta User
  Given a valid Okta user ID and updated profile data
  When I send a PUT request to '/users/{userId}' with the updated profile data
  Then the response status should be 200
  And the response should contain the updated user object
  And if the user ID is invalid, the response status should be 404
  And if the profile data is invalid, the response status should be 400

Scenario: Assign User to Groups
  Given a valid Okta user ID, department, and job title
  When I send a POST request to '/users/{userId}/groups' with department and job title
  Then the response status should be 200
  And the user should be assigned to appropriate groups based on department and role
  And if the user ID is invalid, the response status should be 404
  And if the department does not exist, no group assignment should be made

Scenario: Provision Users
  Given options for provisioning like dryRun and updateExisting
  When I send a POST request to '/provision' with the provisioning options
  Then the response status should be 200
  And the response should contain a summary of processed, created, and updated users
  And if there is a network failure, an error should be logged and processing should continue
  And if the provisioning options are invalid, the response status should be 400

Scenario: Sync Single Employee
  Given a valid BambooHR employee ID
  When I send a POST request to '/sync/employee/{employeeId}'
  Then the response status should be 200
  And the response should confirm successful sync of the employee from BambooHR to Okta
  And if the employee ID does not exist, the response status should be 404
  And if the employee is not active, a message should be logged and processing skipped

Scenario: Performance Testing for Fetching Employees
  Given a large number of employees in BambooHR
  When I send a GET request to '/employees/directory'
  Then the employees should be fetched within acceptable time limits
  And the system should not time out or crash under load

Scenario: Security Testing for API Authentication
  Given invalid API keys for BambooHR and Okta
  When I send a request with invalid API keys
  Then the system should reject the request with a status 401
  And unauthorized access attempts should be logged
  And the system should not expose sensitive error messages

Scenario: Scalability Testing for User Provisioning
  Given a large batch of users to be provisioned from BambooHR to Okta
  When I send a POST request for provisioning
  Then the system should handle the batch efficiently without performance degradation
  And the system should not fail or slow down with increasing number of users

Scenario: Reliability Testing for Network Failures
  Given simulated network interruptions during API calls
  When I perform various API operations
  Then the system should gracefully handle network failures and retry operations
  And the system should maintain data integrity and consistency despite failures

Scenario: Usability Testing for Log Messages
  Given various operations like fetching employees and creating users
  When these operations are performed
  Then log messages should be clear, informative, and easily understandable
  And log messages should not contain sensitive information
