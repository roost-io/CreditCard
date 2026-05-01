Feature: User Authentication and Registration Workflows

  # UI TESTS
  @ui
  Scenario Outline: Login with various credentials
    Given I am on the 'Login' page
    When I enter '<username>' in the 'Username' field
    And I enter '<password>' in the 'Password' field
    And I click the 'Submit' button
    Then I should see '<expected_message>'
    And I should be on '<target_page>'

    Examples:
      | username           | password         | expected_message                     | target_page       |
      | validUser          | ValidPass123!    | Welcome, validUser                   | dashboard        |
      | validUser          | WrongPass!       | Invalid username or password         | login            |
      | notExistUser       | SomePass123!     | Invalid username or password         | login            |
      | deletedUser        | CorrectPass!     | Access denied                        | login            |

  @ui
  Scenario Outline: Registration Form Field Boundary Validation
    Given I am on the 'Sign Up' page
    When I enter '<email>' in the 'Email' field
    And I enter '<username>' in the 'Username' field
    And I enter '<password>' in the 'Password' field
    And I enter '<confirm_password>' in the 'Confirm Password' field
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | email             | username         | password              | confirm_password | expected_message                                  |
      | valid@mail.com    | ab               | ValidPass123!         | ValidPass123!    | Username must be at least 3 characters             |
      | valid@mail.com    | abc              | short7                | short7           | Password must be at least 8 characters             |
      | valid@mail.com    | abc              | ValidPass123456789012 | ValidPass123456789012 | Registration successful                       |
      | valid@mail.com    | abc              | tooLongPassword1234567 | tooLongPassword1234567 | Password may not exceed 20 characters      |
      | valid@mail.com    | abc              | Password1             | Password2        | Passwords do not match                             |
      | valid@mail.com    | abc              | passwordabc           | passwordabc      | Password must include uppercase, digit, symbol     |
      | valid@mail.com    | abc              | Passwordabc           | Passwordabc      | Password must include digit and symbol             |
      | valid@mail.com    | abc              | Password1             | Password1        | Password must include symbol                       |
      | valid@mail.com    | abc              | !@#$%^&*Aa1           | !@#$%^&*Aa1      | Registration successful                            |
      | valid@mail.com    | test user        | ValidPass123!         | ValidPass123!    | Usernames must not contain whitespace              |
      | valid@mail.com    | abcdefghijklmnopqrstuvwxyzabcdef | ValidPass123! | ValidPass123!    | Username must be a maximum of 32 characters      |
      | valid@mail.com    | abcdefghijklmnopqrstuvwxyzabcdefa | ValidPass123! | ValidPass123!    | Username must be a maximum of 32 characters      |
      | valid@mail.com    | abc              | ValidPass123!         | ValidPass123!    | Registration successful                            |

  @ui
  Scenario Outline: Email Format Validation During Registration
    Given I am on the 'Sign Up' page
    When I enter '<username>' in the 'Username' field
    And I enter '<email>' in the 'Email' field
    And I enter 'ValidPass123!' in the 'Password' field
    And I enter 'ValidPass123!' in the 'Confirm Password' field
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | username | email              | expected_message                 |
      | tester   | userexample.com    | Email format is invalid          |
      | tester   | user@com           | Email format is invalid          |
      | tester   | test@mail.com      | Registration successful          |

  @ui
  Scenario Outline: Mandatory Field Validation During Registration
    Given I am on the 'Sign Up' page
    When I leave '<field_to_blank>' blank in the form
    And I enter valid values in other required fields
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | field_to_blank | expected_message                                   |
      | Email          | Email field is required                            |
      | Username       | Username field is required                         |
      | Password       | Password field is required                         |

  @ui
  Scenario Outline: Registration with Existing Email
    Given I am on the 'Sign Up' page
    When I enter a unique username
    And I enter '<email>' in the 'Email' field
    And I enter a valid password in the 'Password' and 'Confirm Password' fields
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | email            | expected_message                     |
      | duplicate@mail.com | Email is already in use            |
      | unique@mail.com     | Registration successful            |

  @ui
  Scenario Outline: Password Minimum Complexity Enforcement
    Given I am on the 'Sign Up' page
    When I enter a valid username and email
    And I enter '<password>' in the 'Password' field
    And I enter '<password>' in the 'Confirm Password' field
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | password        | expected_message                                       |
      | passwordabc     | Password must include uppercase, digit, symbol         |
      | Passwordabc     | Password must include digit and symbol                 |
      | Password1       | Password must include symbol                           |
      | Password1!      | Registration successful                                |

  @ui
  Scenario: Show/hide password toggle functionality
    Given I am on the 'Login' page with the password field available
    When I begin typing a password
    And the password is masked by default
    And I click the 'show/hide password' icon
    Then the password should become visible
    When I click the 'show/hide password' icon again
    Then the password input should be masked again

  @ui
  Scenario: Successful logout from dashboard
    Given I am logged in and on the dashboard screen
    When I click the 'Logout' button in the dashboard header
    Then I should be redirected to the 'Login' page
    And the session should be terminated
    When I use browser back button
    Then access to dashboard is not restored without re-authentication

  @ui
  Scenario Outline: Attempt login with account in restricted state
    Given I am on the 'Login' page
    When I enter '<username>' in the 'Username' field
    And I enter '<password>' in the 'Password' field
    And I submit the login form
    Then I should see '<expected_message>'
    And I should be on 'Login' page

    Examples:
      | username      | password       | expected_message         |
      | deletedUser   | ValidPass123!  | Access denied            |
      | disabledUser  | ValidPass123!  | Access denied            |
      | deactivatedUser | ValidPass123!| Access denied            |

  @ui
  Scenario Outline: Registration with whitespace in username
    Given I am on the 'Sign Up' page
    When I enter '<username>' in the 'Username' field containing whitespace
    And I enter valid email and password values
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | username           | expected_message                       |
      | test user          | Usernames must not contain whitespace   |
      |  user              | Usernames must not contain whitespace   |
      | user   | Usernames must not contain whitespace   |

  @ui
  Scenario: Resend email verification link from login prompt
    Given I am on the 'Login' page and my email is unverified
    When I attempt to log in with valid credentials
    Then I should see a prompt to verify email
    When I click 'Resend Verification Link'
    Then a new verification email should arrive in my inbox
    And the UI should show confirmation of re-sending

  @ui
  Scenario: Confirmation email contains correct verification link and expiry details
    Given I have completed registration with valid data
    When I open the confirmation email in my inbox
    Then the email should contain a properly formed verification link
    And the message should state the link expiry duration

  @ui
  Scenario: Mandatory password length boundaries in password reset flow
    Given I am on the 'Forgot Password' flow
    When I enter a password '<password>' that is shorter than minimum requirement
    And I confirm the password as '<password>'
    And I submit the form
    Then I should see 'Password must be at least 8 characters'

    Examples:
      | password   |
      | short7     |

  @ui
  Scenario Outline: Username maximum and minimum length validation
    Given I am on the 'Sign Up' page
    When I enter '<username>' in the 'Username' field
    And I complete all other required fields
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | username                                 | expected_message                                  |
      | ab                                       | Username must be at least 3 characters             |
      | abc                                      | Registration successful                            |
      | abcdefghijklmnopqrstuvwxyzabcdef          | Registration successful                            |
      | abcdefghijklmnopqrstuvwxyzabcdefa         | Username must be a maximum of 32 characters        |

  @ui
  Scenario Outline: Password upper boundary validation during registration
    Given I am on the 'Sign Up' page
    When I enter all required fields
    And I enter '<password>' in the 'Password' and 'Confirm Password' fields
    And I submit the registration form
    Then I should see '<expected_message>'

    Examples:
      | password                  | expected_message                                 |
      | ValidPass123456789012     | Registration successful                          |
      | InvalidPass1234567890123  | Password may not exceed 20 characters             |

  @ui
  Scenario: Registration with all special characters in password
    Given I am on the 'Sign Up' page
    When I enter a valid email in the 'Email' field
    And I enter a valid username in the 'Username' field
    And I enter '!@#$%^&*Aa1' in the 'Password' field
    And I confirm the password as '!@#$%^&*Aa1'
    And I complete any other mandatory fields
    And I submit the registration form
    Then I should see 'Registration successful'

  @ui
  Scenario: Registration with password reset notification email structure and audit logging
    Given I initiate a password reset via the 'Forgot Password' flow
    When I receive the password reset email
    Then the email subject and sender should be correct
    And the content should include the reset link and expiration info
    And no password should be displayed in the email
    When I navigate to the security audit log
    Then a log entry for password reset request with user, timestamp, and IP address should exist

  @ui
  Scenario: Audit log records successful registration event
    Given user registration has completed successfully
    When I log into the administrator/audit console
    And I navigate to the user registration audit log
    Then I should find a log entry including user identifier, timestamp, IP address, and event type

  @ui
  Scenario: Email not verified blocks login and triggers verification prompt
    Given I am on the 'Login' page after registering but not verifying email
    When I enter registered email and password and submit
    Then login should be blocked
    And I should see 'Please verify your email address'
    When I check the inbox, a new verification email should have been sent

  @ui
  Scenario: Password reset with expired link
    Given I have received a password reset email
    And the reset link has expired
    When I click the expired reset link and attempt to set a new password
    Then I should see 'Password reset link has expired' and no password change is allowed

  @ui
  Scenario Outline: Password change from profile with various current password values
    Given I am logged in and on 'Profile' page
    When I click 'Change Password'
    And I enter '<current_password>' in the 'Current Password' field
    And I enter '<new_password>' in the 'New Password' field
    And I confirm '<new_password>' in the 'Confirm New Password' field
    And I submit the password change form
    Then I should see '<expected_message>'

    Examples:
      | current_password | new_password     | expected_message                      |
      | CorrectPass!     | NewPass123!      | Password changed successfully          |
      | WrongPass!       | NewPass123!      | Incorrect current password             |

  # END-TO-END SCENARIOS

  @ui
  Scenario: Full user registration and email verification flow
    Given I am on the application homepage
    When I click 'Sign Up' and complete the registration form with valid name, email, and password
    And I submit the registration form
    And I open the test email inbox and locate the verification email
    And I click the verification link in the email
    And I return to the login page
    When I log in with the registered credentials
    Then I should gain access to the dashboard
    And I log out to end session

  @ui
  Scenario: Forgot password and set new password flow
    Given I am on the 'Login' page
    When I click 'Forgot Password'
    And I enter a valid email address and submit the reset request
    And I open the received password reset email
    And I click the reset link
    And I enter a valid new password and confirmation
    And I submit the form
    And I return to the login page
    When I log in with the new password
    Then I should see the dashboard

  # STATE TRANSITION & SESSION MANAGEMENT

  @ui
  Scenario: Account lock after multiple failed login attempts and unlock after password reset
    Given I am on the 'Login' page
    When I enter valid username with incorrect password and submit
    And I repeat this process '<attempts>' times
    Then I should see 'Account is locked'
    When I initiate 'Forgot Password'
    And I complete password reset via email
    And I log in with the new password
    Then I should see the dashboard
    And 'Account is unlocked' status

    Examples:
      | attempts |
      | 5        |

  @ui
  Scenario: Automatic logout after session timeout
    Given I am logged in and on the dashboard
    When I remain inactive for '<timeout_minutes>' minutes
    And I attempt to access any secure page
    Then I should be redirected to the login page

    Examples:
      | timeout_minutes |
      | 15             |

  @ui
  Scenario Outline: Session timeout enforcement at exact threshold
    Given I am logged in and on the dashboard
    When I remain inactive and start a timer
    Then at '<minute>' minute '<second>' I should be '<session_state>'

    Examples:
      | minute | second | session_state          |
      | 14     | 59     | logged in              |
      | 15     | 0      | logged out and prompted for login |

