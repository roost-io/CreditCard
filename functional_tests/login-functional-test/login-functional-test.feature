Feature: User Login ID Uniqueness
  As a system administrator
  I want to ensure that all user login IDs are unique, regardless of user type (Standard or SSO)
  So that data integrity is maintained and user accounts can be uniquely identified.

  Background:
    Given the API base URL is "https://api.example.com"
    And a user already exists in the system with login ID "existing.user"

  # API tests to validate the backend logic for user creation and login ID conflict detection.
  # This is the primary validation for the new SSO user check capability.
  @api
  Scenario Outline: Validate API response when creating a new user with a unique or duplicate Login ID
    When I send a POST request to "/api/v1/users" with the following payload:
      '''
      {
        "loginID": "<loginID>",
        "firstName": "Test",
        "lastName": "User",
        "email": "<email>",
        "userType": "<userType>"
      }
      '''
    Then the response status code should be <statusCode>
    And the response body should contain the message "<expectedMessage>"

    Examples:
      | description                       | userType | loginID         | email                 | statusCode | expectedMessage           |
      | Create standard user with new ID  | standard | new.standard    | new.standard@test.com | 201        | "User created successfully" |
      | Block standard user with dup ID   | standard | existing.user   | new.standard@test.com | 409        | "Login ID already exists"   |
      | Create SSO user with new ID       | sso      | new.sso         | new.sso@test.com      | 201        | "User created successfully" |
      | Block SSO user with dup ID        | sso      | existing.user   | new.sso@test.com      | 409        | "Login ID already exists"   |
      | Block user with empty login ID    | standard |                 | empty.id@test.com     | 400        | "Login ID cannot be empty"  |
      | Block user with empty user type   |          | another.new     | another@test.com      | 400        | "User Type is required"     |

  # UI tests to ensure the user interface correctly displays feedback when creating users.
  # This validates that the backend error is properly communicated to the end-user.
  @ui
  Scenario Outline: Validate user creation feedback on the UI for unique and duplicate Login IDs
    Given I am an administrator on the "Add New User" page
    When I select "<userType>" as the user type
    And I enter "<loginID>" into the "Login ID" field
    And I fill in all other required user details
    And I click the "Create User" button
    Then I should see a notification message saying "<expectedMessage>"

    Examples:
      | description                       | userType | loginID         | expectedMessage                                      |
      | Create standard user with new ID  | Standard | new.standard    | "User created successfully!"                         |
      | Block standard user with dup ID   | Standard | existing.user   | "Error: Login ID 'existing.user' is already in use." |
      | Create SSO user with new ID       | SSO      | new.sso         | "User created successfully!"                         |
      | Block SSO user with dup ID        | SSO      | existing.user   | "Error: Login ID 'existing.user' is already in use." |
      | Validate empty login ID field     | Standard |                 | "Error: Login ID is a required field."               |
