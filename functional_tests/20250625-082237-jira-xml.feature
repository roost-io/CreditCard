Feature: API Testing for BambooHR and Okta Integration

  # Test created by Divyesh Maheshwari

  Scenario: Fetch Employees from BambooHR
    Given the API base URL 'https://api.bamboohr.com/api/gateway.php/{subdomain}/v1/employees/directory'
    And a valid BambooHR API key
    When I send a GET request to fetch employees
    Then the response status should be 200
    And the response should contain a list of active employees with valid work emails
    And handle edge cases where no employees exist, all employees are inactive, or employees lack work emails

  Scenario: Check if User Exists in Okta
    Given the API base URL 'https://{yourOktaDomain}/api/v1/users'
    And a valid email address of an employee
    When I send a GET request to check if the user exists
    Then the response status should be 200
    And the response should return the Okta user object if the user exists
    And return null if the user does not exist
    And handle edge cases where the email address does not exist or is in an invalid format

  Scenario: Generate Temporary Password
    Given no input values are required
    When I generate a temporary password
    Then the password should be 12 characters long
    And contain at least one uppercase letter, one lowercase letter, and one digit
    And ensure the password does not contain special characters other than 'Aa1!'

  Scenario: Create Okta User Profile
    Given a valid employee object from BambooHR
    When I create an Okta user profile
    Then the response should return a correctly structured Okta user profile object
    And handle edge cases where optional fields like mobilePhone or supervisor are missing

  Scenario: Create User in Okta
    Given a valid Okta user profile
    When I send a POST request to create a user in Okta
    Then the response status should be 201
    And the response should return the created user object
    And handle edge cases where the user already exists or the user profile data is invalid

  Scenario: Update Existing Okta User
    Given a valid Okta user ID and updated profile data
    When I send a PUT request to update the user's profile in Okta
    Then the response status should be 200
    And the user's profile should be successfully updated
    And handle edge cases where the user ID does not exist or the profile data is invalid

  Scenario: Assign User to Groups
    Given a valid Okta user ID, department, and job title
    When I assign the user to groups
    Then the user should be assigned to the correct department and manager groups
    And handle edge cases where the department does not have a corresponding group or the job title does not include 'manager'

  Scenario: Provision Users
    Given options for dryRun and updateExisting
    When I provision users
    Then all employees should be correctly processed, creating or updating users in Okta as needed
    And handle edge cases where all employees already exist in Okta or errors occur during user creation or update

  Scenario: Sync Single Employee
    Given a valid BambooHR employee ID
    When I sync the employee's data to Okta
    Then the response status should be 200
    And the employee's data should be successfully synced
    And handle edge cases where the employee ID does not exist or the employee is inactive or missing an email

  Scenario: Performance of Fetching Employees
    Given a large number of employees in BambooHR
    When I fetch employees
    Then the operation should complete within a reasonable time frame

  Scenario: Scalability of User Provisioning
    Given a large number of users to be provisioned
    When I provision users
    Then the system should handle provisioning without performance degradation

  Scenario: Security of API Requests
    Given valid and invalid API keys and tokens
    When I make API requests
    Then only valid credentials should allow access
    And invalid credentials should be rejected

  Scenario: Reliability of User Creation and Updates
    Given continuous user creation and update requests
    When I perform these operations
    Then the system should maintain reliability and consistency in user data

  Scenario: Logging and Error Handling
    Given various error scenarios during API calls
    When errors occur
    Then errors should be logged with detailed information
    And the system should handle them gracefully

  Scenario: Usability of the Provisioning Process
    Given a user interface for running the provisioning script
    When I use the interface
    Then the process should be intuitive
    And provide clear feedback to the user
