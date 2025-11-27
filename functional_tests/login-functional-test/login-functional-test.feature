@user-management
Feature: User Management - Sleep Physician Details

  This feature covers the creation, editing, and validation of user accounts,
  with a primary focus on ensuring that Login IDs are unique for both SSO and standard users.

  Background:
    Given an administrator is logged in to the system

  # --- API Test Scenarios ---
  # These scenarios validate the backend logic directly, ensuring data integrity at the API level.

  @api @regression
  Scenario Outline: API prevents creating a user with a duplicate Login ID
    Given the API base URL is set
    And a user with Login ID "existing.user" already exists in the system
    When I send a POST request to "/api/v1/users" with a payload containing Login ID "<login_id>" and SSO status <sso_flag>
      """
      {
        "firstName": "Api",
        "lastName": "Test",
        "email": "api.test.user@example.com",
        "loginId": "<login_id>",
        "isSsoUser": <sso_flag>,
        "isActive": true
      }
      """
    Then the response status should be "409 Conflict"
    And the response body should contain an error message "Login ID already exists"

    Examples:
      | login_id      | sso_flag | description                               |
      | existing.user | true     | SSO user with exact duplicate Login ID    |
      | existing.user | false    | Standard user with exact duplicate ID     |
      | EXISTING.USER | true     | SSO user with case-insensitive duplicate  |
      |  existing.user  | true     | SSO user with leading/trailing spaces     |

  @api @happy-path
  Scenario: API allows creating a user with a unique Login ID
    Given the API base URL is set
    When I send a POST request to "/api/v1/users" with a unique Login ID "unique.api.user"
      """
      {
        "firstName": "Api",
        "lastName": "Success",
        "email": "api.success.user@example.com",
        "loginId": "unique.api.user",
        "isSsoUser": true,
        "isActive": true
      }
      """
    Then the response status should be "201 Created"
    And the response body should contain the created user's details

  # --- UI Test Scenarios ---
  # These scenarios validate the user experience, form functionality, and client-side feedback.

  @ui @critical-path
  Scenario Outline: Prevent user creation with a duplicate Login ID
    Given I am on the "Sleep Physician Details" creation page
    And a user with Login ID "j.doe" already exists in the system
    When I fill in the Last Name with "Test" and Email with "test@example.com"
    And I enter "<login_id_to_test>" in the "Login ID" field
    And I set the "SSO" toggle to "<sso_status>"
    And I click the "Save" button
    Then the user creation should fail
    And I should see an inline error message "Login ID already exists" next to the Login ID field

    Examples:
      | login_id_to_test | sso_status | description                                  |
      | j.doe            | enabled    | SSO user with exact duplicate Login ID       |
      | j.doe            | disabled   | Standard user with exact duplicate Login ID  |
      | J.DOE            | enabled    | SSO user with case-insensitive duplicate     |
      |  j.doe           | enabled    | SSO user with leading/trailing spaces        |

  @ui @regression
  Scenario Outline: Prevent updating a user to have a duplicate Login ID
    Given a user "User A" with Login ID "user.a" exists
    And I am editing the details for "User B" who is a "<user_type>" user
    When I change the "Login ID" field to "user.a"
    And I click the "Save" button
    Then the user update should fail
    And I should see an inline error message "Login ID already exists"

    Examples:
      | user_type |
      | SSO       |
      | Standard  |

  @ui @happy-path
  Scenario: Editing a user without changing their own Login ID is successful
    Given I am editing the details for an SSO user with Login ID "s.jones"
    When I change the "First Name" field to "Samantha"
    And I click the "Save" button
    Then I should see a "User updated successfully" message
    And the update should be saved without a duplicate ID error

  @ui @happy-path
  Scenario Outline: Successfully create a new user with valid and unique data
    Given I am on the "Sleep Physician Details" creation page
    When I fill in the form with Last Name "<last_name>", First Name "<first_name>", and a unique Email
    And I enter a unique Login ID
    And I set the "SSO" toggle to "<sso_status>"
    And if creating a standard user, I enter a valid matching password
    And I click the "Save" button
    Then I should see a "User created successfully" message
    And the new user should appear in the user list

    Examples:
      | sso_status | last_name  | first_name | description                               |
      | enabled    | Physician  | Renée      | SSO user with Unicode characters          |
      | disabled   | Clinician  | John       | Standard user with all mandatory fields   |
      | enabled    | Researcher |            | SSO user with only mandatory name fields  |

  @ui @validation
  Scenario Outline: Verify form field validations for user creation and editing
    Given I am on the "Sleep Physician Details" creation page
    When I fill the form with "<field_value>" in the "<field_name>" field
    And I leave other mandatory fields blank or invalid as per the test case
    And I click the "Save" button
    Then the form submission should be prevented
    And I should see the error message "<error_message>"

    Examples:
      | field_name          | field_value          | error_message                     | description                       |
      | Last Name           |                      | Required Input                    | Empty mandatory field             |
      | Email               | invalid-email        | Invalid email format              | Invalid email format              |
      | Login ID            | user!@#              | Login ID contains invalid characters | Login ID with special characters  |
      | New Password        | weakpass             | Password does not meet policy     | Weak password for standard user   |
      | Retype New Password | doesnotmatch         | Passwords do not match            | Mismatched passwords for standard |
      | Link Expiry Seconds | abc                  | Must be a numeric value           | Non-numeric input in numeric field|
      | Email               | existing@example.com | Email address already in use      | Duplicate email address           |

  @ui @usability
  Scenario: UI state of password fields changes based on SSO toggle
    Given I am on the "Sleep Physician Details" page for a new standard user
    Then the "New Password" and "Retype New Password" fields are visible and mandatory
    When I enable the "SSO" toggle
    Then the "New Password" and "Retype New Password" fields should be hidden or disabled
    When I disable the "SSO" toggle
    Then the "New Password" and "Retype New Password" fields should become visible and mandatory again

  @ui @usability
  Scenario: Form data is preserved after a failed submission
    Given I am on the "Sleep Physician Details" creation page
    And a user with Login ID "j.doe" already exists
    When I fill in the First Name with "John", Last Name with "Doe", and Email with "john.doe@example.com"
    And I enter "j.doe" in the "Login ID" field
    And I click the "Save" button
    Then I should see an inline error message "Login ID already exists"
    And the values for "First Name", "Last Name", and "Email" should still be present in the form

  @ui @usability
  Scenario: Real-time validation for duplicate Login ID
    Given I am on the "Sleep Physician Details" creation page
    And a user with Login ID "j.doe" already exists
    When I enter "j.doe" in the "Login ID" field
    And I tab to the next field
    Then an inline error message "Login ID already exists" should appear immediately
    When I change the "Login ID" field to a unique value "j.doe.new"
    And I tab to the next field
    Then the inline error message should disappear

  @ui @regression
  Scenario Outline: Verify functionality and persistence of user setting toggles and checkboxes
    Given I am editing an existing user
    When I change the state of the "<control_name>" control
    And I click the "Save" button
    And I re-open the same user's details
    Then the "<control_name>" control should reflect the new saved state

    Examples:
      | control_name              |
      | Active toggle             |
      | Locked toggle             |
      | Redok toggle              |
      | Override MFA toggle       |
      | Windows Creds checkbox    |
      | Maximize Views checkbox   |

  @security @ui
  Scenario Outline: Application correctly handles malicious input in text fields
    Given I am on the "Sleep Physician Details" creation page
    When I enter the payload '<payload>' into the "First Name" field
    And I fill all other mandatory fields with valid data
    And I click the "Save" button
    And I navigate to a page where the user's name is displayed
    Then the application should not execute any scripts or encounter a database error
    And the user's name should be displayed as sanitized text

    Examples:
      | payload                        | description      |
      | <script>alert('XSS')</script> | XSS Injection    |
      | ' OR '1'='1' --                | SQL Injection    |
