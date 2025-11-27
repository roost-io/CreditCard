Feature: User Account Management with Duplicate Login ID Validation
  As a system administrator,
  I want to receive a notification if a login ID already exists when creating any user type (Standard or SSO),
  So that I can ensure all user login IDs are unique.

  #-----------------------------------------------------
  # Background setup for API and UI tests
  #-----------------------------------------------------
  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization header is set with a valid admin token from 'AUTH_TOKEN'
    And the content type is 'application/json'
    And a standard user with login ID 'existing.user' already exists in the system

  #-----------------------------------------------------
  # API Test Scenarios
  #-----------------------------------------------------
  @api
  Scenario: Successfully create a new standard user with a unique login ID
    Given the request body for a new standard user:
      '''
      {
        "loginId": "new.standard.user",
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@example.com",
        "userType": "STANDARD"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 201
    And the response body should contain a unique 'userId'
    And the response body 'loginId' should be 'new.standard.user'

  @api
  Scenario: Fail to create a standard user with an existing login ID
    Given the request body for a new standard user with a duplicate login ID:
      '''
      {
        "loginId": "existing.user",
        "firstName": "Jane",
        "lastName": "Smith",
        "email": "jane.smith@example.com",
        "userType": "STANDARD"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 409
    And the response body should contain an error message 'Login ID already exists'

  @api
  Scenario: Successfully create a new SSO user with a unique login ID
    Given the request body for a new SSO user:
      '''
      {
        "loginId": "new.sso.user",
        "firstName": "Sam",
        "lastName": "Wilson",
        "email": "sam.wilson@example.com",
        "userType": "SSO"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 201
    And the response body should contain a unique 'userId'
    And the response body 'loginId' should be 'new.sso.user'

  @api @critical
  Scenario: Fail to create an SSO user with an existing login ID
    Given the request body for a new SSO user with a duplicate login ID:
      '''
      {
        "loginId": "existing.user",
        "firstName": "Peter",
        "lastName": "Jones",
        "email": "peter.jones@example.com",
        "userType": "SSO"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 409
    And the response body should contain an error message 'Login ID already exists'

  @api
  Scenario: Fail to create a user with a case-insensitive duplicate login ID
    Given the request body for a new user with a case-variant duplicate login ID:
      '''
      {
        "loginId": "Existing.User",
        "firstName": "Case",
        "lastName": "Test",
        "email": "case.test@example.com",
        "userType": "STANDARD"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 409
    And the response body should contain an error message 'Login ID already exists'

  @api
  Scenario: Fail to create a user with a missing login ID
    Given the request body for a new user with a missing login ID:
      '''
      {
        "firstName": "Missing",
        "lastName": "Login",
        "email": "missing.login@example.com",
        "userType": "STANDARD"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 400
    And the response body should contain a validation error for the 'loginId' field

  @api
  Scenario: Retrieve an existing user by their ID
    When I send a GET request to '/api/v1/users/123'
    Then the response status should be 200
    And the response body 'loginId' should be 'existing.user'
    And the response body should contain 'firstName', 'lastName', and 'email' fields

  @api
  Scenario: Attempt to create a user without proper authorization
    Given the authorization header is invalid or not set
    And the request body for a new standard user:
      '''
      {
        "loginId": "unauthorized.user",
        "firstName": "Unauthorized",
        "lastName": "Access",
        "email": "unauthorized@example.com",
        "userType": "STANDARD"
      }
      '''
    When I send a POST request to '/api/v1/users'
    Then the response status should be 401

  #-----------------------------------------------------
  # UI Test Scenarios
  #-----------------------------------------------------
  @ui
  Scenario: Admin successfully creates a new standard user through the UI
    Given I am on the 'Create User' page
    When I select 'Standard' as the user type
    And I enter 'new.ui.standard' in the 'Login ID' field
    And I enter 'Emily' in the 'First Name' field
    And I enter 'Clark' in the 'Last Name' field
    And I enter 'emily.clark@example.com' in the 'Email' field
    And I click the 'Create User' button
    Then I should see a success message 'User new.ui.standard created successfully'
    And I should be redirected to the 'User List' page

  @ui
  Scenario: Admin sees an error when creating a standard user with a duplicate login ID
    Given I am on the 'Create User' page
    When I select 'Standard' as the user type
    And I enter 'existing.user' in the 'Login ID' field
    And I enter 'Duplicate' in the 'First Name' field
    And I enter 'User' in the 'Last Name' field
    And I enter 'duplicate.user@example.com' in the 'Email' field
    And I click the 'Create User' button
    Then I should see an error message 'Login ID already exists. Please choose another.'
    And I should remain on the 'Create User' page

  @ui
  Scenario: Admin successfully creates a new SSO user through the UI
    Given I am on the 'Create User' page
    When I select 'SSO' as the user type
    And I enter 'new.ui.sso' in the 'Login ID' field
    And I enter 'Michael' in the 'First Name' field
    And I enter 'Brown' in the 'Last Name' field
    And I enter 'michael.brown@example.com' in the 'Email' field
    And I click the 'Create User' button
    Then I should see a success message 'User new.ui.sso created successfully'
    And I should be redirected to the 'User List' page

  @ui @critical
  Scenario: Admin sees an error when creating an SSO user with a duplicate login ID
    Given I am on the 'Create User' page
    When I select 'SSO' as the user type
    And I enter 'existing.user' in the 'Login ID' field
    And I enter 'Another' in the 'First Name' field
    And I enter 'Duplicate' in the 'Last Name' field
    And I enter 'another.duplicate@example.com' in the 'Email' field
    And I click the 'Create User' button
    Then I should see an error message 'Login ID already exists. Please choose another.'
    And I should remain on the 'Create User' page

  @ui
  Scenario: UI form validation for empty required fields
    Given I am on the 'Create User' page
    When I click the 'Create User' button
    Then I should see a validation message 'Login ID is required' next to the 'Login ID' field
    And I should see a validation message 'First Name is required' next to the 'First Name' field
    And I should see a validation message 'Email is required' next to the 'Email' field

  @ui
  Scenario: Real-time validation shows login ID is already taken while typing
    Given I am on the 'Create User' page
    When I enter 'existing.user' in the 'Login ID' field
    And I move focus away from the 'Login ID' field
    Then I should see a validation message 'This Login ID is already taken' displayed next to the field
