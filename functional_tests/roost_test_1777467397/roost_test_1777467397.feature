Feature: Aegis Card Platform - Portal, API, Security, Applications, Transactions, Billing, and Non-Functional Requirements

  Background:
    Given the API base URL is '${API_BASE_URL}'
    And the portal base URL is '${PORTAL_BASE_URL}'
    And the realtime WebSocket URL is '${REALTIME_WS_URL}'
    And the default request headers are set to:
      | Header       | Value              |
      | Content-Type | application/json   |
      | Accept       | application/json   |
    And I can run network inspection tools (curl and openssl) on the test runner
    And I can run browser automation with DevTools access for the portal

  # ---------------------------------------------------------------------------
  # Platform / TLS / CDN (API + UI)
  # ---------------------------------------------------------------------------

  @ui @functional @TC-PLAT-01
  Scenario: Portal base URL reachable over HTTPS and served via CDN
    Given I am on the '${PORTAL_BASE_URL}' page
    When I wait for the page to finish loading
    Then I should see the page loaded without browser security warnings
    And the browser should indicate a secure HTTPS connection
    And I should see that static assets are successfully downloaded in the network panel
    And the response headers for the HTML document should include CDN-indicative headers
    And the response headers for at least one static asset should include CDN-indicative headers

  @api @security @TC-PLAT-02
  Scenario Outline: API base URL /v2 reachable over HTTPS and enforces TLS 1.3 minimum using <tls_mode>
    Given the DNS name 'api.aegiscard.com' resolves to at least one IP address
    When I perform a TLS handshake to host 'api.aegiscard.com' on port 443 forcing <tls_mode>
    Then the TLS handshake result should be <handshake_result>
    And the negotiated TLS version should be <negotiated_tls_version>

    Examples:
      | tls_mode | handshake_result | negotiated_tls_version |
      | TLS1.3   | SUCCESS          | TLSv1.3                |
      | TLS1.2   | FAILURE          | NONE                   |

  @api @security @TC-PLAT-02
  Scenario: API v2 endpoint is reachable over HTTPS (network level)
    Given the DNS name 'api.aegiscard.com' resolves to at least one IP address
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {}
      """
    Then the response status should be one of:
      | status |
      | 200    |
      | 400    |
      | 401    |
      | 422    |
      | 429    |
    And the request should not fail due to TLS or connection errors

  # ---------------------------------------------------------------------------
  # Registration
  # ---------------------------------------------------------------------------

  @api @functional @TC-REG-01
  Scenario: Register user succeeds (201) and returns onboarding artifacts
    Given I have generated a unique email 'test+reg01-${RUN_ID}@example.com'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Alicia",
        "last_name": "Tester",
        "email": "test+reg01-${RUN_ID}@example.com",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-15",
        "phone_number": "+14165550101",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be 201
    And the response JSON should contain:
      | path               |
      | user_id            |
      | verification_token |
    And the response JSON path 'user_id' should not be empty
    And the response JSON path 'verification_token' should not be empty

  @api @negative @TC-REG-01
  Scenario: Registering the same email twice indicates the account now exists
    Given I have generated a unique email 'test+reg01dup-${RUN_ID}@example.com'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Alicia",
        "last_name": "Tester",
        "email": "test+reg01dup-${RUN_ID}@example.com",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-15",
        "phone_number": "+14165550101",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be 201
    When I send the same POST request to '/v2/auth/register' with the same payload again
    Then the response status should not be 201

  @api @negative @TC-REG-02
  Scenario Outline: Register rejects when agree_terms is false and succeeds when corrected
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Brandon",
        "last_name": "Consent",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1992-06-20",
        "phone_number": "+14165550102",
        "ssn_last4": "5678",
        "agree_terms": <agree_terms>
      }
      """
    Then the response status should be <status>
    And the response JSON should <user_artifacts_presence> contain:
      | path               |
      | user_id            |
      | verification_token |

    Examples:
      | email                              | agree_terms | status | user_artifacts_presence |
      | test+reg02-${RUN_ID}@example.com   | false       | 400    | not                     |
      | test+reg02fix-${RUN_ID}@example.com| true        | 201    |                         |

  @api @negative @TC-REG-03
  Scenario: Register returns 409 EMAIL_EXISTS when email already registered
    Given the email 'test+reg03-existing@example.com' is already registered
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Casey",
        "last_name": "Duplicate",
        "email": "test+reg03-existing@example.com",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1991-03-10",
        "phone_number": "+14165550103",
        "ssn_last4": "9012",
        "agree_terms": true
      }
      """
    Then the response status should be 409
    And the response JSON path 'error' should equal 'EMAIL_EXISTS'
    And the response JSON should not contain:
      | path               |
      | user_id            |
      | verification_token |

  @api @negative @TC-REG-04
  Scenario Outline: Register returns 422 WEAK_PASSWORD for weak passwords
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Password",
        "last_name": "Weak",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "1990-01-01",
        "phone_number": "+14165550104",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And the response JSON path 'error' should <error_assertion> equal '<error_code>'
    And the response JSON should <token_presence> contain:
      | path               |
      | user_id            |
      | verification_token |

    Examples:
      | email                                | password         | status | error_code     | error_assertion | token_presence |
      | test+reg04a-${RUN_ID}@example.com     | password         | 422    | WEAK_PASSWORD  |                 | not          |
      | test+reg04b-${RUN_ID}@example.com     | Abcdefghijk1     | 422    | WEAK_PASSWORD  |                 | not          |
      | test+reg04ctrl-${RUN_ID}@example.com  | Str0ng!Passw0rd  | 201    |                | not             |              |

  @api @boundary @TC-REG-05
  Scenario Outline: Registration first_name validation (alpha-only and length 2-50)
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "<first_name>",
        "last_name": "Smith",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-01",
        "phone_number": "+14165550111",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And for error responses the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |

    Examples:
      | email                               | first_name                                           | status |
      | test+regfn2-${RUN_ID}@example.com   | Al                                                  | 201    |
      | test+regfn50-${RUN_ID}@example.com  | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  | 201    |
      | test+regfn1-${RUN_ID}@example.com   | A                                                   | 400    |
      | test+regfn51-${RUN_ID}@example.com  | BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB | 400    |
      | test+regfnDigit-${RUN_ID}@example.com| Jo3                                                | 400    |
      | test+regfnHyphen-${RUN_ID}@example.com| Jo-An                                              | 400    |

  @api @negative @TC-REG-07
  Scenario Outline: Registration rejects malformed email formats
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Email",
        "last_name": "Format",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-01",
        "phone_number": "+14165550112",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |

    Examples:
      | email                                 | status |
      | test+emailctrl-${RUN_ID}@example.com   | 201    |
      | plainaddress                           | 400    |
      | missingdomain@                         | 400    |
      | @missinglocal.example.com              | 400    |
      | test..dots@example.com                 | 400    |
      | test+bad space@example.com             | 400    |

  @api @boundary @TC-REG-08
  Scenario Outline: Registration password complexity and boundary length enforcement
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Pw",
        "last_name": "Rule",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "1990-01-01",
        "phone_number": "+14165550113",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And for status 422 the response JSON path 'error' should equal 'WEAK_PASSWORD'

    Examples:
      | email                              | password        | status |
      | test+pwdok1-${RUN_ID}@example.com  | Aa1!aaaaaaaab    | 201    |
      | test+pwdlen11-${RUN_ID}@example.com| Aa1!aaaaaaa      | 422    |
      | test+pwdlower-${RUN_ID}@example.com| aaaaaaaaaaaa     | 422    |
      | test+pwdupper-${RUN_ID}@example.com| AAAAAAAAAAAA     | 422    |
      | test+pwddigit-${RUN_ID}@example.com| Aa!aaaaaaaaaa    | 422    |
      | test+pwdsym-${RUN_ID}@example.com  | Aa1aaaaaaaaaaa   | 422    |
      | test+pwdlen12-${RUN_ID}@example.com| Aa1!aaaaaaaa     | 201    |

  @api @boundary @TC-REG-09
  Scenario Outline: Registration date_of_birth format and age >= 18 enforcement
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Dob",
        "last_name": "Rule",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "<date_of_birth>",
        "phone_number": "+14165550114",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |

    Examples:
      | email                             | date_of_birth           | status |
      | test+dob18-${RUN_ID}@example.com  | ${DOB_EXACTLY_18}        | 201    |
      | test+dob17-${RUN_ID}@example.com  | ${DOB_UNDER_18_BY_1_DAY} | 400    |
      | test+dobfmt1-${RUN_ID}@example.com| 04/29/2000              | 400    |
      | test+dobfmt2-${RUN_ID}@example.com| 2000-13-01              | 400    |
      | test+dobfmt3-${RUN_ID}@example.com| 2000-01-01T00:00:00Z     | 400    |

  @api @negative @TC-REG-10
  Scenario Outline: Registration rejects non-E.164 phone_number formats
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "Phone",
        "last_name": "Rule",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-01",
        "phone_number": "<phone_number>",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'phone_number'

    Examples:
      | email                               | phone_number       | status |
      | test+phoneok-${RUN_ID}@example.com  | +14165551234        | 201    |
      | test+phonebad1-${RUN_ID}@example.com| 4165551234          | 400    |
      | test+phonebad2-${RUN_ID}@example.com| ++14165551234       | 400    |

  @api @boundary @TC-REG-11
  Scenario Outline: Registration ssn_last4 must be exactly 4 numeric digits
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "SSN",
        "last_name": "Rule",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-01",
        "phone_number": "+14165550115",
        "ssn_last4": "<ssn_last4>",
        "agree_terms": true
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'ssn_last4'

    Examples:
      | email                           | ssn_last4 | status |
      | test+ssnok-${RUN_ID}@example.com| 1234      | 201    |
      | test+ssn3-${RUN_ID}@example.com | 123       | 400    |
      | test+ssn5-${RUN_ID}@example.com | 12345     | 400    |
      | test+ssnA-${RUN_ID}@example.com | 12A4      | 400    |

  @api @negative @TC-REG-12
  Scenario Outline: Registration missing required field returns 400 with error, field, message
    Given I have generated a unique email '<email>'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "last_name": "Missing",
        "email": "<email>",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-01",
        "phone_number": "+14165550116",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be 400
    And the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |
    And the response JSON path 'field' should equal '<missing_field>'

    Examples:
      | email                             | missing_field |
      | test+regmissing-${RUN_ID}@example.com | first_name  |

  # ---------------------------------------------------------------------------
  # Login / MFA / Lockout / Rate limiting
  # ---------------------------------------------------------------------------

  @api @functional @TC-LOGIN-01
  Scenario: Login success returns access_token, refresh_token, expires_in and token works on a protected endpoint
    Given a registered user exists with email 'test+login01@example.com' and password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+login01@example.com",
        "password": "Str0ng!Passw0rd"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path          |
      | access_token  |
      | refresh_token |
      | expires_in    |
    When I store the response JSON path 'access_token' as 'access_token'
    And I send a GET request to '/v2/accounts/${ACCOUNT_ID}/summary' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should not be 401

  @api @negative @TC-LOGIN-01
  Scenario: Tampered access token is rejected for protected endpoint
    Given I have a valid access token stored as 'access_token'
    When I send a GET request to '/v2/accounts/${ACCOUNT_ID}/summary' with headers:
      | Header        | Value                          |
      | Authorization | Bearer ${access_token}_TAMPERED |
    Then the response status should be one of:
      | status |
      | 401    |
      | 403    |

  @api @negative @TC-LOGIN-02
  Scenario: Login returns 401 INVALID_CREDENTIALS for wrong password
    Given a registered user exists with email 'test+login02@example.com' and password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+login02@example.com",
        "password": "Wr0ng!Passw0rd"
      }
      """
    Then the response status should be 401
    And the response JSON path 'error' should equal 'INVALID_CREDENTIALS'
    And the response JSON should not contain:
      | path          |
      | access_token  |
      | refresh_token |
      | expires_in    |

  @api @functional @TC-LOGIN-03
  Scenario: Login with MFA enabled accepts optional 6-digit TOTP mfa_code
    Given a registered MFA-enabled user exists with email 'test+mfa@example.com' and password 'Str0ng!Passw0rd'
    And I have generated a valid 6-digit TOTP code for that user as 'mfa_code'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+mfa@example.com",
        "password": "Str0ng!Passw0rd",
        "mfa_code": "${mfa_code}"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path          |
      | access_token  |
      | refresh_token |
      | expires_in    |

  @api @state-transition @TC-LOGIN-04
  Scenario: Account locks after 5 failed login attempts and returns 403 ACCOUNT_LOCKED + unlock_at
    Given a registered user exists with email 'test+lockout@example.com' and password 'Str0ng!Passw0rd'
    When I send 5 POST requests to '/v2/auth/login' with payload:
      """
      {
        "email": "test+lockout@example.com",
        "password": "WrongPass!0000"
      }
      """
    Then each response status should be 401
    When I send a 6th POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+lockout@example.com",
        "password": "WrongPass!0000"
      }
      """
    Then the response status should be 403
    And the response JSON path 'error' should equal 'ACCOUNT_LOCKED'
    And the response JSON should contain:
      | path      |
      | unlock_at |

  @api @resilience @TC-LOGIN-05
  Scenario: Login rate limit returns 429 RATE_LIMITED with retry_after after exceeding 10 req/min per IP
    Given a registered user exists with email 'test+rl01@example.com' and password 'ValidPass!12345'
    When I send 10 POST requests to '/v2/auth/login' within 60 seconds with payload:
      """
      {
        "email": "test+rl01@example.com",
        "password": "ValidPass!12345"
      }
      """
    Then each response status should be 200
    When I send 1 more POST request to '/v2/auth/login' within the same 60 seconds with payload:
      """
      {
        "email": "test+rl01@example.com",
        "password": "ValidPass!12345"
      }
      """
    Then the response status should be 429
    And the response JSON path 'error' should equal 'RATE_LIMITED'
    And the response JSON should contain:
      | path        |
      | retry_after |

  @api @negative @TC-LOGIN-06
  Scenario Outline: Login fails for unknown email and does not issue tokens
    Given a registered user exists with email 'test+login06-registered@example.com' and password 'ValidPassw0rd!234'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "<email>",
        "password": "ValidPassw0rd!234"
      }
      """
    Then the response status should be <status>
    And the response JSON should <token_presence> contain:
      | path          |
      | access_token  |
      | refresh_token |
      | expires_in    |
    And for status 401 the response JSON path 'error' should equal 'INVALID_CREDENTIALS'

    Examples:
      | email                             | status | token_presence |
      | test+login06-registered@example.com| 200    |                |
      | test+login06-unknown@example.com   | 401    | not            |

  @api @boundary @TC-LOGIN-07
  Scenario Outline: Login device_id UUID v4 validation when provided
    Given a registered user exists with email 'test+login07@example.com' and password 'ValidPassw0rd!234'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+login07@example.com",
        "password": "ValidPassw0rd!234",
        "device_id": "<device_id>"
      }
      """
    Then the response status should be <status>
    And for non-200 responses the response JSON should not contain:
      | path          |
      | access_token  |
      | refresh_token |

    Examples:
      | device_id                             | status |
      | 550e8400-e29b-41d4-a716-446655440000  | 200    |
      | 550e8400-e29b-11d4-a716-446655440000  | 400    |
      | not-a-uuid                            | 400    |

  @api @functional @TC-LOGIN-08
  Scenario: remember_me=true extends refresh token TTL to 30 days (observable via cookie/token metadata)
    Given a registered user exists with email 'test+login08@example.com' and password 'ValidPassw0rd!234'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+login08@example.com",
        "password": "ValidPassw0rd!234",
        "remember_me": false
      }
      """
    Then the response status should be 200
    When I record the refresh token TTL/expiry metadata as 'baseline_refresh_ttl'
    And I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+login08@example.com",
        "password": "ValidPassw0rd!234",
        "remember_me": true
      }
      """
    Then the response status should be 200
    And I record the refresh token TTL/expiry metadata as 'remember_me_refresh_ttl'
    And the 'remember_me_refresh_ttl' should indicate approximately 30 days

  # ---------------------------------------------------------------------------
  # Token Refresh
  # ---------------------------------------------------------------------------

  @api @functional @TC-REFRESH-01
  Scenario: Token refresh returns new access_token and refresh_token (rotation enforced)
    Given a registered user exists with email 'test+rt01@example.com' and password 'ValidPassw0rd!234'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+rt01@example.com",
        "password": "ValidPassw0rd!234"
      }
      """
    Then the response status should be 200
    When I store the response JSON path 'access_token' as 'access_token_1'
    And I store the response JSON path 'refresh_token' as 'refresh_token_1'
    And I send a POST request to '/v2/auth/token/refresh' with payload:
      """
      {
        "refresh_token": "${refresh_token_1}"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path          |
      | access_token  |
      | refresh_token |
    And the response JSON path 'access_token' should not equal '${access_token_1}'
    And the response JSON path 'refresh_token' should not equal '${refresh_token_1}'

  @api @security @TC-REFRESH-02
  Scenario: Token refresh invalidates old refresh token after successful refresh (single-use)
    Given a registered user exists with email 'test+rt02@example.com' and password 'ValidPassw0rd!234'
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+rt02@example.com",
        "password": "ValidPassw0rd!234"
      }
      """
    Then the response status should be 200
    When I store the response JSON path 'refresh_token' as 'refresh_token_1'
    And I send a POST request to '/v2/auth/token/refresh' with payload:
      """
      {
        "refresh_token": "${refresh_token_1}"
      }
      """
    Then the response status should be 200
    When I store the response JSON path 'refresh_token' as 'refresh_token_2'
    And I send a POST request to '/v2/auth/token/refresh' with payload:
      """
      {
        "refresh_token": "${refresh_token_1}"
      }
      """
    Then the response status should be 401
    And the response JSON path 'error' should equal 'TOKEN_INVALID'
    When I send a POST request to '/v2/auth/token/refresh' with payload:
      """
      {
        "refresh_token": "${refresh_token_2}"
      }
      """
    Then the response status should be 200

  @api @negative @TC-REFRESH-04
  Scenario Outline: Token refresh requires refresh_token field (missing/empty fails; valid succeeds)
    Given a registered user exists with email 'test+rt04@example.com' and password 'ValidPassw0rd!234'
    And I have obtained a valid refresh token as 'valid_refresh_token' via login
    When I send a POST request to '/v2/auth/token/refresh' with payload:
      """
      <payload>
      """
    Then the response status should be <status>

    Examples:
      | payload                                      | status |
      | {}                                           | 400    |
      | {"refresh_token": ""}                        | 400    |
      | {"refresh_token": "${valid_refresh_token}"}  | 200    |

  # ---------------------------------------------------------------------------
  # Portal token storage / PCI / CSRF / Session (UI-focused)
  # ---------------------------------------------------------------------------

  @ui @security @TC-TOKSTORE-01
  Scenario: Auth tokens stored in HttpOnly, Secure cookies and not accessible via document.cookie
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+cookie01@example.com' and password 'Str0ng!Passw0rd'
    Then I should be on an authenticated page
    And the auth/session cookies should have the 'HttpOnly' attribute
    And the auth/session cookies should have the 'Secure' attribute
    When I evaluate JavaScript 'document.cookie'
    Then the result should not include token cookie names or token-like values

  @ui @security @TC-TOKSTORE-02
  Scenario: Auth tokens are never stored in localStorage or sessionStorage
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+ls01@example.com' and password 'Str0ng!Passw0rd'
    Then I should be on an authenticated page
    When I inspect localStorage for token-like keys and values
    Then localStorage should not contain access or refresh tokens
    When I inspect sessionStorage for token-like keys and values
    Then sessionStorage should not contain access or refresh tokens

  @ui @functional @TC-DRAFT-01
  Scenario: Credit application auto-save occurs every 60 seconds to localStorage draft
    Given I open a clean browser context
    And I am on the credit application form page
    And localStorage for the portal origin is empty
    When I enter 'Jordan Test' in the 'Full legal name' field
    And I enter '+14165550199' in the 'Phone number' field
    And I wait 60 seconds
    Then localStorage should contain an application draft entry
    When I change the 'Phone number' field to '+14165550200'
    And I wait 60 seconds
    Then the application draft in localStorage should reflect the updated phone number
    When I refresh the page
    Then the application form should restore values from the saved draft

  @ui @security @TC-DRAFT-02
  Scenario: Draft auto-save does not store auth tokens in localStorage
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+draft02@example.com' and password 'Str0ng!Passw0rd'
    And I navigate to the credit application flow
    And I enter 'Jordan Test' in the 'Full legal name' field
    And I wait 60 seconds
    Then localStorage should contain a draft entry
    And localStorage should not contain token-like keys or values
    And sessionStorage should not contain token-like keys or values

  @ui @security @TC-PAN-01
  Scenario: PAN displayed in browser only as masked format
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+pan01@example.com' and password 'Str0ng!Passw0rd'
    And I navigate to the card details area
    Then I should see a masked PAN like '**** **** **** 4242'
    And the DOM should not contain an unmasked PAN-like digit sequence

  @ui @security @TC-PCI-02
  Scenario: Card fields use iframe tokenisation and no raw PAN in DOM
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+pciform@example.com' and password 'Str0ng!Passw0rd'
    And I navigate to the card entry form
    Then I should see card input fields rendered inside one or more iframes
    When I type a synthetic card number '4242 4242 4242 4242' into the card number field
    Then the top-level DOM should not contain '4242424242424242'
    And the network payload for the form submission should not contain raw PAN digits

  @ui @security @TC-CSRF-02
  Scenario: CSRF cookie policy SameSite=Strict is enforced for portal sessions
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+samesite@example.com' and password 'Str0ng!Passw0rd'
    Then the portal session cookies should have 'SameSite=Strict'

  @ui @security @TC-SESSION-01
  Scenario: Portal session expires after 15 minutes of inactivity
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+session01@example.com' and password 'Str0ng!Passw0rd'
    Then I should be on an authenticated page
    When I remain inactive for 15 minutes
    Then I should be redirected to the login page when accessing a protected page

  @ui @functional @TC-SESSION-02
  Scenario: Portal shows 2-minute warning modal before auto-logout
    Given I open a clean browser context
    And I am on the '${PORTAL_BASE_URL}' page
    When I log in via the portal UI with email 'test+session02@example.com' and password 'Str0ng!Passw0rd'
    And I remain inactive for 13 minutes
    Then I should see an inactivity warning modal
    When I do not interact for 2 more minutes
    Then I should be logged out automatically

  # ---------------------------------------------------------------------------
  # Applications Step 1
  # ---------------------------------------------------------------------------

  @api @functional @TC-APP1-01
  Scenario: Application Step 1 succeeds and returns application_id and session_token
    Given I am authenticated as 'test+app1ok@example.com' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Jordan Avery Test",
        "email": "test+app1ok@example.com",
        "phone_number": "+14165550101",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be 201
    And the response JSON should contain:
      | path            |
      | application_id  |
      | session_token   |

  @api @boundary @TC-APP1-02
  Scenario Outline: Step 1 full_legal_name boundary validation (100 accepted, 101 rejected)
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "<full_legal_name>",
        "email": "<user_email>",
        "phone_number": "+14165550101",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be <status>
    And for status 201 the response JSON should contain:
      | path           |
      | application_id |
      | session_token  |
    And for status 400 the response JSON path 'field' should equal 'full_legal_name'

    Examples:
      | user_email                      | full_legal_name                         | status |
      | test+app1bva100@example.com     | ${STRING_LEN_100}                       | 201    |
      | test+app1bva101@example.com     | ${STRING_LEN_101}                       | 400    |

  @api @negative @TC-APP1-03
  Scenario: Step 1 email must match authenticated user email (reject mismatch)
    Given I am authenticated as 'test+app1emailA@example.com' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Email Mismatch Test",
        "email": "test+app1emailB@example.com",
        "phone_number": "+14165550101",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be 400
    And the response JSON path 'field' should equal 'email'
    And the response JSON should not contain:
      | path           |
      | application_id |
      | session_token  |

  @api @negative @TC-APP1-04
  Scenario: Step 1 returns 409 DUPLICATE_APPLICATION when active application already in progress
    Given I am authenticated as 'test+dupapp@example.com' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Dup App Test",
        "email": "test+dupapp@example.com",
        "phone_number": "+14165550101",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be 201
    When I send the same POST request to '/v2/applications/start' again with the same payload
    Then the response status should be 409
    And the response JSON path 'error' should equal 'DUPLICATE_APPLICATION'

  @api @boundary @TC-APP1-05
  Scenario Outline: Step 1 phone_number must be E.164 (accept valid, reject invalid)
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Phone Format Test",
        "email": "<user_email>",
        "phone_number": "<phone_number>",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'phone_number'

    Examples:
      | user_email                      | phone_number         | status |
      | test+app1phoneok@example.com    | +14165550123          | 201    |
      | test+app1phonebad1@example.com  | 4165550123            | 400    |
      | test+app1phonebad2@example.com  | +1 (416) 555-0123     | 400    |

  @api @boundary @TC-APP1-06
  Scenario Outline: Step 1 address.street max 100 chars boundary
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Street Length Test",
        "email": "<user_email>",
        "phone_number": "+14165550123",
        "residential_address": {
          "street": "<street>",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'address.street'

    Examples:
      | user_email                     | street            | status |
      | test+app1street100@example.com | ${STRING_LEN_100} | 201    |
      | test+app1street101@example.com | ${STRING_LEN_101} | 400    |

  @api @boundary @TC-APP1-07
  Scenario Outline: Step 1 address.city max 60 chars boundary
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "City Length Test",
        "email": "<user_email>",
        "phone_number": "+14165550123",
        "residential_address": {
          "street": "100 King St W",
          "city": "<city>",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'address.city'

    Examples:
      | user_email                   | city           | status |
      | test+app1city60@example.com  | ${STRING_LEN_60} | 201    |
      | test+app1city61@example.com  | ${STRING_LEN_61} | 400    |

  @api @boundary @TC-APP1-08
  Scenario Outline: Step 1 province must be 2-char ISO 3166-2 code
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Province Test",
        "email": "<user_email>",
        "phone_number": "+14165550123",
        "residential_address": {
          "street": "100 Test St",
          "city": "Toronto",
          "province": "<province>",
          "postal_code": "M5V 2T6"
        },
        "id_type": "PASSPORT",
        "id_number": "ZXCV1234"
      }
      """
    Then the response status should be <status>

    Examples:
      | user_email                  | province | status |
      | test+app1provok@example.com | ON       | 201    |
      | test+app1prov3@example.com  | ONT      | 400    |
      | test+app1prov1@example.com  | O        | 400    |

  @api @boundary @TC-APP1-09
  Scenario Outline: Step 1 postal_code must match Canadian format A1A 1A1
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Postal Code Test",
        "email": "<user_email>",
        "phone_number": "+14165550124",
        "residential_address": {
          "street": "200 Test Ave",
          "city": "Ottawa",
          "province": "ON",
          "postal_code": "<postal_code>"
        },
        "id_type": "DRIVERS_LICENSE",
        "id_number": "D1E2F3G4"
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'address.postal_code'

    Examples:
      | user_email                    | postal_code | status |
      | test+app1pcok@example.com     | K1A 0B1     | 201    |
      | test+app1pcmissspace@example.com| K1A0B1    | 400    |
      | test+app1pcbad@example.com    | 123 456     | 400    |

  @api @boundary @TC-APP1-10
  Scenario Outline: Step 1 id_type enum enforcement
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "ID Type Test",
        "email": "<user_email>",
        "phone_number": "+14165550125",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "<id_type>",
        "id_number": "ZXCV1234"
      }
      """
    Then the response status should be <status>

    Examples:
      | user_email                 | id_type         | status |
      | test+app1idpass@example.com| PASSPORT        | 201    |
      | test+app1iddl@example.com  | DRIVERS_LICENSE | 201    |
      | test+app1idpr@example.com  | PR_CARD         | 201    |
      | test+app1idbad@example.com | NATIONAL_ID     | 400    |

  @api @boundary @TC-APP1-11
  Scenario Outline: Step 1 id_number alphanumeric max 20 chars boundary
    Given I am authenticated as '<user_email>' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "ID Number Test",
        "email": "<user_email>",
        "phone_number": "+14165550126",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "K1A 0B1"
        },
        "id_type": "PASSPORT",
        "id_number": "<id_number>"
      }
      """
    Then the response status should be <status>

    Examples:
      | user_email                   | id_number                 | status |
      | test+app1idnum20@example.com | AB12CD34EF56GH78IJ90      | 201    |
      | test+app1idnum21@example.com | AB12CD34EF56GH78IJ901     | 400    |
      | test+app1idnumhy@example.com | ABC-123                   | 400    |

  @api @negative @TC-APP1-12
  Scenario: Step 1 validation failure returns 400 with error, field, message
    Given I am authenticated as 'test+app1invalid@example.com' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "Invalid Postal",
        "email": "test+app1invalid@example.com",
        "phone_number": "+14165550127",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "INVALID"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be 400
    And the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |

  # ---------------------------------------------------------------------------
  # Applications Step 2 (X-App-Session, sequencing, boundaries)
  # ---------------------------------------------------------------------------

  @api @functional @TC-APP2-01
  Scenario: Application Step 2 succeeds with X-App-Session and returns PENDING_REVIEW and fico_pull_id
    Given I am authenticated as 'test+app2ok@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "SELF_EMPLOYED",
        "gross_annual_income": 85000.00,
        "other_income": 0.00,
        "monthly_rent": 1800.00,
        "existing_debt_payments": 350.00,
        "sin_consent": true
      }
      """
    Then the response status should be 200
    And the response JSON path 'status' should equal 'PENDING_REVIEW'
    And the response JSON should contain:
      | path         |
      | fico_pull_id |

  @api @negative @TC-APP2-02
  Scenario: Step 2 rejects when EMPLOYED but employer_name missing
    Given I am authenticated as 'test+app2emp@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "EMPLOYED",
        "gross_annual_income": 65000.00,
        "monthly_rent": 1500.00,
        "existing_debt_payments": 200.00,
        "sin_consent": true
      }
      """
    Then the response status should be 400
    And the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |
    And the response JSON path 'field' should equal 'employer_name'

  @api @boundary @TC-APP2-03
  Scenario Outline: Step 2 gross_annual_income boundary validation
    Given I am authenticated as 'test+app2income@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "RETIRED",
        "gross_annual_income": <gross_annual_income>,
        "monthly_rent": 0.00,
        "existing_debt_payments": 0.00,
        "sin_consent": true
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'gross_annual_income'

    Examples:
      | gross_annual_income | status |
      | 9999999.99          | 200    |
      | 10000000.00         | 400    |
      | 0.00                | 400    |
      | -1.00               | 400    |

  @api @negative @TC-APP2-04
  Scenario Outline: Step 2 rejects when sin_consent is false or omitted; succeeds when true
    Given I am authenticated as 'test+app2consent@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      <payload>
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'field' should equal 'sin_consent'

    Examples:
      | payload                                                                                                                                 | status |
      | {"employment_status":"STUDENT","gross_annual_income":12000.00,"monthly_rent":650.00,"existing_debt_payments":50.00,"sin_consent":false} | 400    |
      | {"employment_status":"STUDENT","gross_annual_income":12000.00,"monthly_rent":650.00,"existing_debt_payments":50.00}                     | 400    |
      | {"employment_status":"STUDENT","gross_annual_income":12000.00,"monthly_rent":650.00,"existing_debt_payments":50.00,"sin_consent":true}  | 200    |

  @api @state-transition @TC-APPSEQ-01
  Scenario: Enforce sequential completion: Step 2 cannot be completed without X-App-Session from Step 1
    Given I am authenticated as 'test+appseq01@example.com' with password 'Str0ng!Passw0rd'
    When I send a POST request to '/v2/applications/11111111-1111-1111-1111-111111111111/financials' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "employment_status": "UNEMPLOYED",
        "gross_annual_income": 30000.00,
        "monthly_rent": 900.00,
        "existing_debt_payments": 150.00,
        "sin_consent": true
      }
      """
    Then the response status should not be 200
    When I create an application via Step 1 and store 'application_id' and 'session_token'
    And I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "UNEMPLOYED",
        "gross_annual_income": 30000.00,
        "monthly_rent": 900.00,
        "existing_debt_payments": 150.00,
        "sin_consent": true
      }
      """
    Then the response status should be 200
    And the response JSON path 'status' should equal 'PENDING_REVIEW'
    And the response JSON should contain:
      | path         |
      | fico_pull_id |
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-App-Session | invalid-token          |
    And payload:
      """
      {
        "employment_status": "UNEMPLOYED",
        "gross_annual_income": 30000.00,
        "monthly_rent": 900.00,
        "existing_debt_payments": 150.00,
        "sin_consent": true
      }
      """
    Then the response status should be 401
    And the response JSON path 'error' should equal 'SESSION_EXPIRED'

  @api @negative @TC-APPSEQ-02
  Scenario: Step 2 returns 401 SESSION_EXPIRED when session_token is invalid
    Given I am authenticated as 'test+appseq02@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | invalid-session-token-01 |
    And payload:
      """
      {
        "employment_status": "EMPLOYED",
        "employer_name": "TestCo",
        "gross_annual_income": 75000.00,
        "other_income": 0.00,
        "monthly_rent": 1500.00,
        "existing_debt_payments": 250.00,
        "sin_consent": true
      }
      """
    Then the response status should be 401
    And the response JSON path 'error' should equal 'SESSION_EXPIRED'

  @api @boundary @TC-APPSEQ-03
  Scenario: Validate X-App-Session required and expiry boundary (29:59 succeeds; 30:01 expires)
    Given I am authenticated as 'test+appseq03@example.com' with password 'Str0ng!Passw0rd'
    When I create an application via Step 1 and store 'application_id_1' and 'session_token_1' and record issuance time as 'T0'
    And I send a POST request to '/v2/applications/${application_id_1}/financials' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "employment_status": "SELF_EMPLOYED",
        "gross_annual_income": 90000.00,
        "other_income": 5000.00,
        "monthly_rent": 0.00,
        "existing_debt_payments": 300.00,
        "sin_consent": true
      }
      """
    Then the response status should not be 200
    When I wait until elapsed time since 'T0' is 29 minutes and 59 seconds
    And I send a POST request to '/v2/applications/${application_id_1}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token_1}       |
    And payload:
      """
      {
        "employment_status": "SELF_EMPLOYED",
        "gross_annual_income": 90000.00,
        "other_income": 5000.00,
        "monthly_rent": 0.00,
        "existing_debt_payments": 300.00,
        "sin_consent": true
      }
      """
    Then the response status should be 200
    When I create an application via Step 1 and store 'application_id_2' and 'session_token_2' and record issuance time as 'T1'
    And I wait until elapsed time since 'T1' is 30 minutes and 1 second
    And I send a POST request to '/v2/applications/${application_id_2}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token_2}       |
    And payload:
      """
      {
        "employment_status": "SELF_EMPLOYED",
        "gross_annual_income": 90000.00,
        "other_income": 5000.00,
        "monthly_rent": 0.00,
        "existing_debt_payments": 300.00,
        "sin_consent": true
      }
      """
    Then the response status should be 401
    And the response JSON path 'error' should equal 'SESSION_EXPIRED'

  @api @functional @TC-APP2-05
  Scenario Outline: Step 2 other_income defaults to 0.00 when omitted
    Given I am authenticated as 'test+app2otherincome@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      <payload>
      """
    Then the response status should be 200
    And the response JSON path 'status' should equal 'PENDING_REVIEW'
    And the response JSON should contain:
      | path         |
      | fico_pull_id |

    Examples:
      | payload                                                                                                                                                |
      | {"employment_status":"EMPLOYED","employer_name":"TestCo Ltd","gross_annual_income":85000.00,"monthly_rent":1800.00,"existing_debt_payments":250.00,"sin_consent":true} |
      | {"employment_status":"EMPLOYED","employer_name":"TestCo Ltd","gross_annual_income":85000.00,"other_income":0.00,"monthly_rent":1800.00,"existing_debt_payments":250.00,"sin_consent":true} |

  @api @boundary @TC-APP2-06
  Scenario Outline: Step 2 monthly_rent boundary allows 0.00 but rejects negative
    Given I am authenticated as 'test+app2rent@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "RETIRED",
        "gross_annual_income": 60000.00,
        "monthly_rent": <monthly_rent>,
        "existing_debt_payments": 0.00,
        "sin_consent": true
      }
      """
    Then the response status should be <status>

    Examples:
      | monthly_rent | status |
      | 0.00         | 200    |
      | -0.01        | 400    |

  @api @boundary @TC-APP2-07
  Scenario Outline: Step 2 existing_debt_payments enforces Decimal(10,2) precision
    Given I am authenticated as 'test+app2debt@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "SELF_EMPLOYED",
        "gross_annual_income": 120000.00,
        "monthly_rent": 1500.00,
        "existing_debt_payments": <existing_debt_payments>,
        "sin_consent": true
      }
      """
    Then the response status should be <status>

    Examples:
      | existing_debt_payments | status |
      | 1234.56                | 200    |
      | 1234.567               | 400    |

  @api @negative @TC-APP2-08
  Scenario: Step 2 missing required field returns 400 with error, field, message
    Given I am authenticated as 'test+app2missing@example.com' with password 'Str0ng!Passw0rd'
    And I have created an application via Step 1 and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "EMPLOYED",
        "employer_name": "TestCo Ltd",
        "monthly_rent": 1200.00,
        "existing_debt_payments": 100.00,
        "sin_consent": true
      }
      """
    Then the response status should be 400
    And the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |

  # ---------------------------------------------------------------------------
  # Applications Step 3 (decisions, signature, defaults)
  # ---------------------------------------------------------------------------

  @api @functional @TC-APP3-01
  Scenario: Step 3 approved decision returns credit_limit and card_number_masked
    Given I am authenticated as 'test+app3approved@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    And the decisioning stub is configured for application '${application_id}' with FICO value 700
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "U3ludGhldGljIFNpZ25hdHVyZQ=="
      }
      """
    Then the response status should be 200
    And the response JSON path 'decision' should equal 'APPROVED'
    And the response JSON should contain:
      | path               |
      | credit_limit       |
      | card_number_masked |
    And the response JSON path 'card_number_masked' should not match the regex '\d{13,19}'

  @api @functional @TC-APP3-02
  Scenario: Step 3 pending decision includes review_eta_hours
    Given I am authenticated as 'test+app3pending@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    And the decisioning stub is configured for application '${application_id}' with FICO value 650
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "VGVzdCBTaWduYXR1cmU=",
        "marketing_opt_in": true
      }
      """
    Then the response status should be 200
    And the response JSON path 'decision' should equal 'PENDING'
    And the response JSON should contain:
      | path             |
      | review_eta_hours |

  @api @functional @TC-APP3-03
  Scenario: Step 3 declined decision includes reason_code
    Given I am authenticated as 'test+app3decline@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    And the decisioning stub is configured for application '${application_id}' with FICO value 550
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "RGVjbGluZSBUZXN0IFNpZw=="
      }
      """
    Then the response status should be 200
    And the response JSON path 'decision' should equal 'DECLINED'
    And the response JSON should contain:
      | path        |
      | reason_code |
    And the response body should not match the regex '\d{13,19}'

  @api @negative @TC-APP3-04
  Scenario Outline: Step 3 rejects missing/malformed e_signature with 400 SIGNATURE_REQUIRED
    Given I am authenticated as 'test+app3sig@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      <payload>
      """
    Then the response status should be 400
    And the response JSON path 'error' should equal 'SIGNATURE_REQUIRED'

    Examples:
      | payload                                               |
      | {"card_product_id":"AEGIS_GOLD"}                       |
      | {"card_product_id":"AEGIS_GOLD","e_signature":"not-base64"} |

  @api @functional @TC-APP3-05
  Scenario: Step 3 marketing_opt_in defaults to false when omitted (if observable)
    Given I am authenticated as 'test+app3marketing@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "VGVzdCBTaWduYXR1cmU="
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path     |
      | decision |
    And if the response JSON contains 'marketing_opt_in' then the response JSON path 'marketing_opt_in' should equal 'false'

  @api @boundary @TC-APP3-08
  Scenario: Decision boundary at FICO 680 returns PENDING and includes review_eta_hours
    Given I am authenticated as 'test+app3b680@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    And the decisioning stub is configured for application '${application_id}' with FICO value 680
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "VGVzdCBVc2Vy"
      }
      """
    Then the response status should be 200
    And the response JSON path 'decision' should equal 'PENDING'
    And the response JSON should contain:
      | path             |
      | review_eta_hours |
    And the response JSON should not contain:
      | path               |
      | credit_limit       |
      | card_number_masked |

  @api @boundary @TC-APP3-10
  Scenario: Decision boundary at FICO 599 returns DECLINED and includes reason_code
    Given I am authenticated as 'test+app3b599@example.com' with password 'Str0ng!Passw0rd'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    And the decisioning stub is configured for application '${application_id}' with FICO value 599
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "VGVzdCBVc2Vy"
      }
      """
    Then the response status should be 200
    And the response JSON path 'decision' should equal 'DECLINED'
    And the response JSON should contain:
      | path        |
      | reason_code |

  @api @functional @TC-APP3-06
  Scenario: Step 3 card_product_id must come from GET /v2/products
    Given I am authenticated as 'test+app3products@example.com' with password 'Str0ng!Passw0rd'
    When I send a GET request to '/v2/products' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    When I store a valid product id from the response as 'card_product_id_valid'
    And I have completed Step 1 and Step 2 successfully and stored 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "${card_product_id_valid}",
        "e_signature": "VGVzdCBTaWduYXR1cmU="
      }
      """
    Then the response status should be 200
    When I create a new application and complete Step 1 and Step 2 and store 'application_id2' and 'session_token2'
    And I send a POST request to '/v2/applications/${application_id2}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token2}        |
    And payload:
      """
      {
        "card_product_id": "NOT_A_REAL_PRODUCT",
        "e_signature": "VGVzdCBTaWduYXR1cmU="
      }
      """
    Then the response status should be 400
    And the response JSON should contain:
      | path    |
      | error   |
      | field   |
      | message |

  # ---------------------------------------------------------------------------
  # Transactions: initiate, limits, FX, list
  # ---------------------------------------------------------------------------

  @api @functional @TC-TXN-01
  Scenario: Initiate transaction approved path returns transaction_id, available_credit, auth_code
    Given I am authenticated as 'test+txn01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 25.50,
        "merchant_name": "Test Coffee Shop",
        "merchant_id": "TESTMERCH0001",
        "mcc_code": "5812",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "QA approval test"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path             |
      | transaction_id   |
      | available_credit |
      | auth_code        |

  @api @functional @TC-TXN-02
  Scenario: Essential service over-limit within 5% buffer returns over_limit_flag true
    Given I am authenticated as 'test+txn02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with available_credit configured to 100.00
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 104.00,
        "merchant_name": "Essential Utility",
        "merchant_id": "ESSUTIL0001",
        "mcc_code": "4900",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "Essential over-limit buffer test"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path            |
      | transaction_id  |
      | over_limit_flag |
    And the response JSON path 'over_limit_flag' should equal 'true'

  @api @negative @TC-TXN-03
  Scenario: Initiate transaction returns 402 INSUFFICIENT_FUNDS with available_credit
    Given I am authenticated as 'test+txn03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with available_credit configured to 50.00
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 200.00,
        "merchant_name": "Test Electronics",
        "merchant_id": "TESTELEC0001",
        "mcc_code": "5732",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be 402
    And the response JSON path 'error' should equal 'INSUFFICIENT_FUNDS'
    And the response JSON should contain:
      | path             |
      | available_credit |

  @api @negative @TC-TXN-04
  Scenario: Initiate transaction returns 403 CARD_INACTIVE when card not Active or Frozen
    Given I am authenticated as 'test+txn04@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with card status configured to 'Blocked'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "Test Merchant",
        "merchant_id": "TESTM0001",
        "mcc_code": "5999",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be 403
    And the response JSON path 'error' should equal 'CARD_INACTIVE'
    And the response JSON should contain:
      | path        |
      | card_status |

  @api @boundary @TC-TXN-05
  Scenario Outline: Initiate transaction rejects transaction_amount <= 0 with 422 INVALID_AMOUNT
    Given I am authenticated as 'test+txn05@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": <amount>,
        "merchant_name": "Boundary Merchant",
        "merchant_id": "BOUND0001",
        "mcc_code": "5999",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be <status>
    And for status 422 the response JSON path 'error' should equal 'INVALID_AMOUNT'

    Examples:
      | amount | status |
      | 0.00   | 422    |
      | -0.01  | 422    |
      | 0.01   | 200    |

  @api @negative @TC-TXN-06
  Scenario: Initiate transaction requires exchange_rate when currency_code != CAD
    Given I am authenticated as 'test+txn06@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "FX Test Merchant",
        "merchant_id": "FXMERCH0001",
        "mcc_code": "5999",
        "currency_code": "USD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should not be 200
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "FX Test Merchant",
        "merchant_id": "FXMERCH0001",
        "mcc_code": "5999",
        "currency_code": "USD",
        "exchange_rate": 1.350000,
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should not be the missing-exchange-rate failure from the previous attempt

  @api @resilience @TC-TXNFREQ-01
  Scenario: Transaction frequency limit triggers 429 FREQ_EXCEEDED with mfa_required true on 11th transaction
    Given I am authenticated as 'test+txnfreq@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with sufficient credit and eligible status
    When I send 10 POST requests to '/v2/accounts/${account_id}/transactions' within 60 minutes with payload template:
      """
      {
        "transaction_amount": 1.00,
        "merchant_name": "LoadTest Shop",
        "merchant_id": "${MERCHANT_ID}",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "freq test"
      }
      """
    Then each response status should be 200
    When I send 1 more POST request to '/v2/accounts/${account_id}/transactions' within the same 60 minutes with payload:
      """
      {
        "transaction_amount": 1.00,
        "merchant_name": "LoadTest Shop",
        "merchant_id": "LTSHOP11",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "freq test #11"
      }
      """
    Then the response status should be 429
    And the response JSON path 'error' should equal 'FREQ_EXCEEDED'
    And the response JSON path 'mfa_required' should equal 'true'

  @api @boundary @TC-TXNFREQ-02
  Scenario: Transaction frequency boundary does not trigger FREQ_EXCEEDED at exactly 10 transactions
    Given I am authenticated as 'test+txnfreqb@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with sufficient credit and eligible status
    When I send exactly 10 POST requests to '/v2/accounts/${account_id}/transactions' within 60 minutes
    Then all 10 responses should have status 200
    And none of the 10 responses should contain error 'FREQ_EXCEEDED'

  @api @functional @TC-FX-01
  Scenario: Foreign transaction fee calculation applies 1.03 multiplier to (amount × exchange_rate)
    Given I am authenticated as 'test+fx01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I compute expected_total_cad as (100.00 * 1.250000) * 1.03 rounded to 2 decimals
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 100.00,
        "merchant_name": "FX Test Merchant",
        "merchant_id": "FXM123",
        "mcc_code": "5812",
        "currency_code": "USD",
        "exchange_rate": 1.250000,
        "transaction_type": "PURCHASE",
        "description": "FX formula test"
      }
      """
    Then the response status should be 200
    And the response should contain a CAD total field consistent with '${expected_total_cad}' within 0.01

  @api @functional @TC-FX-02
  Scenario: Foreign fee is itemised separately as foreign_fee_amount in response
    Given I am authenticated as 'test+fx02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 50.00,
        "merchant_name": "FX Fee Merchant",
        "merchant_id": "FXFEE50",
        "mcc_code": "5999",
        "currency_code": "EUR",
        "exchange_rate": 1.450000,
        "transaction_type": "PURCHASE",
        "description": "FX fee itemization test"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path              |
      | foreign_fee_amount |
    And the response JSON path 'foreign_fee_amount' should be greater than 0

  @api @functional @TC-TXNLIST-01
  Scenario: List transactions default from_date is billing cycle start (fixture-based)
    Given I am authenticated as 'test+txnlist01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And the billing cycle start date for the account is '${BILLING_CYCLE_START}'
    And there exists at least one transaction before '${BILLING_CYCLE_START}' and at least one on or after it
    When I send a GET request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response should include transactions from on/after '${BILLING_CYCLE_START}'
    And the response should exclude transactions strictly before '${BILLING_CYCLE_START}'

  @api @negative @TC-TXNLIST-02
  Scenario: List transactions rejects invalid date range with 400 INVALID_DATE_RANGE when to_date < from_date
    Given I am authenticated as 'test+txnlist02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a GET request to '/v2/accounts/${account_id}/transactions?from_date=2026-04-10&to_date=2026-04-09' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 400
    And the response JSON path 'error' should equal 'INVALID_DATE_RANGE'
    And the response JSON should not contain:
      | path          |
      | transactions  |

  @api @boundary @TC-TXNLIST-03
  Scenario Outline: List transactions enforces per_page max 100 boundary
    Given I am authenticated as 'test+txnlist03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with at least 120 transactions seeded
    When I send a GET request to '/v2/accounts/${account_id}/transactions?per_page=<per_page>&page=1' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be <status>
    And for status 200 the response JSON path 'transactions' should have length less than or equal to 100

    Examples:
      | per_page | status |
      | 100      | 200    |
      | 101      | 400    |

  @api @security @TC-TXNLIST-04
  Scenario: List transactions returns 403 FORBIDDEN when account not owned by user
    Given UserA is authenticated and has a token 'tokenA'
    And UserB owns an account_id stored as 'account_id_B'
    When I send a GET request to '/v2/accounts/${account_id_B}/transactions' with headers:
      | Header        | Value          |
      | Authorization | Bearer ${tokenA} |
    Then the response status should be 403
    And the response JSON path 'error' should equal 'FORBIDDEN'
    And the response JSON should not contain:
      | path         |
      | transactions |

  @api @boundary @TC-TXNLIST-05
  Scenario Outline: List transactions page min 1 boundary and default page=1
    Given I am authenticated as 'test+txnlist05@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a GET request to '/v2/accounts/${account_id}/transactions<query>' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be <status>
    And for status 200 the response JSON path 'page' should equal <page_value>

    Examples:
      | query      | status | page_value |
      |            | 200    | 1          |
      | ?page=1    | 200    | 1          |
      | ?page=0    | 400    | 0          |
      | ?page=-1   | 400    | 0          |

  @api @functional @TC-TXNLIST-06
  Scenario Outline: List transactions category filter accepts enum values and rejects unknown
    Given I am authenticated as 'test+txnlist06@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a GET request to '/v2/accounts/${account_id}/transactions?category=<category>' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be <status>

    Examples:
      | category     | status |
      | PURCHASE     | 200    |
      | FEE          | 200    |
      | CHARGEBACK   | 400    |

  @api @functional @TC-TXN-12
  Scenario: Initiate transaction currency_code defaults to CAD when omitted
    Given I am authenticated as 'test+txn12@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "Test Merchant CA",
        "merchant_id": "TMCA123456",
        "mcc_code": "5411",
        "transaction_type": "PURCHASE",
        "description": "Default currency test"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path           |
      | transaction_id |
    When I store the response JSON path 'transaction_id' as 'transaction_id'
    And I send a GET request to '/v2/accounts/${account_id}/transactions?page=1&per_page=25' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the transaction with id '${transaction_id}' should have currency_code 'CAD'

  @api @boundary @TC-TXN-14
  Scenario Outline: Initiate transaction transaction_type enum validation
    Given I am authenticated as 'test+txn14@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 1.00,
        "merchant_name": "Enum Type Merchant",
        "merchant_id": "<merchant_id>",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "<transaction_type>"
      }
      """
    Then the response status should be <status>

    Examples:
      | transaction_type  | merchant_id  | status |
      | PURCHASE          | ENUM001      | 200    |
      | CASH_ADVANCE      | ENUM002      | 200    |
      | BALANCE_TRANSFER  | ENUM003      | 200    |
      | REVERSAL          | ENUM004      | 400    |

  @api @boundary @TC-TXN-15
  Scenario Outline: Initiate transaction description max 255 chars boundary
    Given I am authenticated as 'test+txn15@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 2.00,
        "merchant_name": "Desc Merchant",
        "merchant_id": "<merchant_id>",
        "mcc_code": "5812",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "<description>"
      }
      """
    Then the response status should be <status>

    Examples:
      | merchant_id | description        | status |
      | DESC255     | ${STRING_LEN_255}  | 200    |
      | DESC256     | ${STRING_LEN_256}  | 400    |

  @api @security @TC-TXN-07
  Scenario: Initiate transaction enforces account_id ownership (IDOR protection)
    Given UserA is authenticated and has a token 'tokenA' and an owned account 'account_id_A'
    And UserB is authenticated and has a token 'tokenB' and an owned account 'account_id_B'
    When I send a POST request to '/v2/accounts/${account_id_B}/transactions' with headers:
      | Header        | Value            |
      | Authorization | Bearer ${tokenA} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "Test Merchant",
        "merchant_id": "TESTMERCHANT01",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "Ownership enforcement test"
      }
      """
    Then the response status should not be 200
    And the response JSON should not contain:
      | path           |
      | transaction_id |
      | auth_code      |
    When I send a POST request to '/v2/accounts/${account_id_B}/transactions' with headers:
      | Header        | Value            |
      | Authorization | Bearer ${tokenB} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "Test Merchant",
        "merchant_id": "TESTMERCHANT01",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "Owner success control"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path           |
      | transaction_id |

  @api @boundary @TC-TXN-08
  Scenario Outline: Initiate transaction transaction_amount Decimal(10,2) precision validation
    Given I am authenticated as 'test+txn08@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": "<amount>",
        "merchant_name": "Precision Merchant",
        "merchant_id": "PREC<suffix>",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be <status>

    Examples:
      | amount        | suffix | status |
      | 99999999.99   | 01     | 200    |
      | 0.01          | 02     | 200    |
      | 1.001         | 03     | 400    |
      | 1.00          | 04     | 200    |

  @api @boundary @TC-TXN-09
  Scenario Outline: Initiate transaction merchant_name max 100 chars boundary
    Given I am authenticated as 'test+txn09@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 10.00,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be <status>

    Examples:
      | merchant_name       | merchant_id | status |
      | ${STRING_LEN_100}   | MN100       | 200    |
      | ${STRING_LEN_101}   | MN101       | 400    |

  @api @boundary @TC-TXN-10
  Scenario Outline: Initiate transaction merchant_id alphanumeric max 32 chars boundary
    Given I am authenticated as 'test+txn10@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 12.34,
        "merchant_name": "QA Store",
        "merchant_id": "<merchant_id>",
        "mcc_code": "5411",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be <status>

    Examples:
      | merchant_id                         | status |
      | A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1    | 200    |
      | A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1Z   | 400    |
      | MERCHANT-01                         | 400    |

  @api @negative @TC-TXN-11
  Scenario Outline: Initiate transaction requires 4-digit mcc_code
    Given I am authenticated as 'test+txn11@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 20.00,
        "merchant_name": "QA Cafe",
        "merchant_id": "QACAFE01<suffix>",
        "mcc_code": "<mcc_code>",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be <status>

    Examples:
      | mcc_code | suffix | status |
      | 5812     | 1      | 200    |
      | 123      | 2      | 400    |
      | 12345    | 3      | 400    |
      | 12A4     | 4      | 400    |

  # ---------------------------------------------------------------------------
  # Account Summary (Dashboard API)
  # ---------------------------------------------------------------------------

  @api @functional @TC-SUM-01
  Scenario: Get account summary success returns required fields
    Given I am authenticated as 'test+sum01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a GET request to '/v2/accounts/${account_id}/summary' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON should contain:
      | path              |
      | current_balance   |
      | available_credit  |
      | credit_limit      |
      | account_status    |
      | billing_cycle_end |
      | points_balance    |

  @api @functional @TC-SUM-02
  Scenario: Get account summary include_rewards defaults to false when omitted
    Given I am authenticated as 'test+sum02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a GET request to '/v2/accounts/${account_id}/summary' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    When I send a GET request to '/v2/accounts/${account_id}/summary?include_rewards=false' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response payload for omitted include_rewards should be functionally equivalent to include_rewards=false for rewards sections

  @api @security @TC-SUM-03
  Scenario: Get account summary returns 403 FORBIDDEN for non-owned account
    Given UserB is authenticated and has a token 'tokenB'
    And UserA owns an account_id stored as 'account_id_A'
    When I send a GET request to '/v2/accounts/${account_id_A}/summary' with headers:
      | Header        | Value            |
      | Authorization | Bearer ${tokenB} |
    Then the response status should be 403
    And the response JSON path 'error' should equal 'FORBIDDEN'
    And the response JSON should not contain:
      | path             |
      | current_balance  |
      | available_credit |
      | credit_limit     |

  # ---------------------------------------------------------------------------
  # Card status / Lost or stolen / PIN
  # ---------------------------------------------------------------------------

  @api @state-transition @TC-CARDSTAT-01
  Scenario: Freeze card succeeds with valid confirm_otp
    Given I am authenticated as 'test+cardfreeze@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "Frozen",
        "reason": "Freeze via test",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path       |
      | card_id    |
      | new_status |
      | updated_at |
    And the response JSON path 'new_status' should equal 'Frozen'

  @api @state-transition @TC-CARDSTAT-02
  Scenario: Unfreeze card succeeds with valid confirm_otp
    Given I am authenticated as 'test+cardunfreeze@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Frozen'
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "Active",
        "reason": "Unfreeze via test",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be 200
    And the response JSON path 'new_status' should equal 'Active'
    And the response JSON should contain:
      | path       |
      | updated_at |

  @api @negative @TC-CARDSTAT-03
  Scenario: Card status update rejects invalid transition with 400 INVALID_TRANSITION and allowed_transitions
    Given I am authenticated as 'test+cardbadtransition@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in a state where transition to 'Frozen' is invalid
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "Frozen",
        "reason": "Attempt invalid transition",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be 400
    And the response JSON path 'error' should equal 'INVALID_TRANSITION'
    And the response JSON should contain:
      | path                |
      | allowed_transitions |

  @api @security @TC-CARDSTAT-04
  Scenario: Card status update fails with 401 OTP_FAILED and attempts_remaining
    Given I am authenticated as 'test+cardotpfailed@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "Frozen",
        "confirm_otp": "000000"
      }
      """
    Then the response status should be 401
    And the response JSON path 'error' should equal 'OTP_FAILED'
    And the response JSON should contain:
      | path               |
      | attempts_remaining |

  @api @audit @TC-CARDSTAT-05
  Scenario Outline: Card status reason max 255 chars (accept) vs 256 (reject); successful change is audit-logged
    Given I am authenticated as 'test+cardreason@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "<status_value>",
        "reason": "<reason>",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be <http_status>
    And for status 200 the response JSON path 'new_status' should equal '<status_value>'

    Examples:
      | status_value | reason            | http_status |
      | Frozen       | ${STRING_LEN_255} | 200         |
      | Active       | ${STRING_LEN_256} | 400         |

  @api @boundary @TC-CARDSTAT-06
  Scenario Outline: Card status update requires 6-digit confirm_otp format
    Given I am authenticated as 'test+cardotpformat@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "Frozen",
        "confirm_otp": "<confirm_otp>"
      }
      """
    Then the response status should not be 200

    Examples:
      | confirm_otp |
      | 12345       |
      | 1234567     |
      | 12A456      |

  @api @functional @TC-LOST-01
  Scenario Outline: Report card lost/stolen blocks card and schedules replacement
    Given I am authenticated as 'test+lost01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked' or 'Closed'
    When I send a POST request to '/v2/cards/${card_id}/report-lost' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "loss_type": "<loss_type>"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path            |
      | blocked_card_id |
      | new_card_eta    |
      | case_number     |

    Examples:
      | loss_type |
      | LOST      |
      | STOLEN    |

  @api @negative @TC-LOST-02
  Scenario: Report lost/stolen returns 409 ALREADY_BLOCKED if card already Blocked or Closed
    Given I am authenticated as 'test+lost02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Blocked'
    When I send a POST request to '/v2/cards/${card_id}/report-lost' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "loss_type": "STOLEN"
      }
      """
    Then the response status should be 409
    And the response JSON path 'error' should equal 'ALREADY_BLOCKED'

  @api @boundary @TC-LOST-03
  Scenario: Report lost/stolen accepts last_known_use in ISO 8601 UTC
    Given I am authenticated as 'test+lost03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked' or 'Closed'
    When I send a POST request to '/v2/cards/${card_id}/report-lost' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "loss_type": "LOST",
        "last_known_use": "2026-04-01T13:45:30Z"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path            |
      | blocked_card_id |
      | new_card_eta    |
      | case_number     |

  @api @negative @TC-LOST-04
  Scenario: Report lost/stolen rejects unknown loss_type and does not block the card
    Given I am authenticated as 'test+lost04@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked' or 'Closed'
    When I send a POST request to '/v2/cards/${card_id}/report-lost' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "loss_type": "MISPLACED",
        "last_known_use": "2026-03-21T10:15:30Z"
      }
      """
    Then the response status should not be 200

  @api @functional @TC-LOST-05
  Scenario: Report lost/stolen accepts optional delivery_address override
    Given I am authenticated as 'test+lost05@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked' or 'Closed'
    When I send a POST request to '/v2/cards/${card_id}/report-lost' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "loss_type": "LOST",
        "last_known_use": "2026-04-01T12:30:00Z",
        "delivery_address": {
          "street": "100 Test Ave",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "A1A 1A1"
        }
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path            |
      | blocked_card_id |
      | new_card_eta    |
      | case_number     |

  @api @functional @TC-PIN-01
  Scenario: Set virtual PIN succeeds with encrypted 4-digit PIN, matching confirm_pin, and session_otp
    Given I am authenticated as 'test+pin01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked'
    And I have obtained a valid 6-digit session_otp as 'session_otp' from '/v2/auth/otp/request'
    And I have RSA-OAEP encrypted '1234' as 'enc_pin_1234'
    When I send a PUT request to '/v2/cards/${card_id}/pin' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "new_pin": "${enc_pin_1234}",
        "confirm_pin": "${enc_pin_1234}",
        "session_otp": "${session_otp}"
      }
      """
    Then the response status should be 200
    And the response JSON path 'success' should equal 'true'
    And the response JSON should contain:
      | path       |
      | updated_at |

  @api @negative @TC-PIN-02
  Scenario: Set virtual PIN returns 400 PIN_MISMATCH when confirm_pin does not match new_pin
    Given I am authenticated as 'test+pin02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked'
    And I have obtained a valid 6-digit session_otp as 'session_otp' from '/v2/auth/otp/request'
    And I have RSA-OAEP encrypted '1234' as 'enc_pin_1234'
    And I have RSA-OAEP encrypted '4321' as 'enc_pin_4321'
    When I send a PUT request to '/v2/cards/${card_id}/pin' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "new_pin": "${enc_pin_1234}",
        "confirm_pin": "${enc_pin_4321}",
        "session_otp": "${session_otp}"
      }
      """
    Then the response status should be 400
    And the response JSON path 'error' should equal 'PIN_MISMATCH'

  @api @boundary @TC-PIN-03
  Scenario Outline: Set virtual PIN returns 400 PIN_FORMAT when PIN is not exactly 4 numeric digits
    Given I am authenticated as 'test+pin03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked'
    And I have obtained a valid 6-digit session_otp as 'session_otp' from '/v2/auth/otp/request'
    And I have RSA-OAEP encrypted '<pin_plaintext>' as 'enc_pin'
    When I send a PUT request to '/v2/cards/${card_id}/pin' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "new_pin": "${enc_pin}",
        "confirm_pin": "${enc_pin}",
        "session_otp": "${session_otp}"
      }
      """
    Then the response status should be 400
    And the response JSON path 'error' should equal 'PIN_FORMAT'

    Examples:
      | pin_plaintext |
      | 123           |
      | 12345         |
      | 12A4          |

  @api @negative @TC-PIN-04
  Scenario: Set virtual PIN returns 403 CARD_BLOCKED when card is Blocked
    Given I am authenticated as 'test+pin04@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Blocked'
    And I have obtained a valid 6-digit session_otp as 'session_otp' from '/v2/auth/otp/request'
    And I have RSA-OAEP encrypted '1234' as 'enc_pin_1234'
    When I send a PUT request to '/v2/cards/${card_id}/pin' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "new_pin": "${enc_pin_1234}",
        "confirm_pin": "${enc_pin_1234}",
        "session_otp": "${session_otp}"
      }
      """
    Then the response status should be 403
    And the response JSON path 'error' should equal 'CARD_BLOCKED'

  @api @security @TC-PIN-05
  Scenario Outline: Set PIN requires session_otp and rejects missing/incorrect OTP
    Given I am authenticated as 'test+pin05@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked'
    And I have RSA-OAEP encrypted '1234' as 'enc_pin_1234'
    When I send a PUT request to '/v2/cards/${card_id}/pin' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      <payload>
      """
    Then the response status should be <status>

    Examples:
      | payload                                                                                              | status |
      | {"new_pin":"${enc_pin_1234}","confirm_pin":"${enc_pin_1234}"}                                        | 400    |
      | {"new_pin":"${enc_pin_1234}","confirm_pin":"${enc_pin_1234}","session_otp":"000000"}                 | 401    |

  @api @security @TC-PIN-06
  Scenario: Set PIN transmits new_pin encrypted (client payload does not contain plaintext PIN)
    Given I am authenticated as 'test+pin06@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' not in status 'Blocked'
    And I have obtained a valid 6-digit session_otp as 'session_otp' from '/v2/auth/otp/request'
    And I have RSA-OAEP encrypted '1234' as 'enc_pin_1234'
    When I send a PUT request to '/v2/cards/${card_id}/pin' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "new_pin": "${enc_pin_1234}",
        "confirm_pin": "${enc_pin_1234}",
        "session_otp": "${session_otp}"
      }
      """
    Then the response status should be 200
    And the last sent request JSON path 'new_pin' should not equal '1234'
    And the last sent request body should not contain '1234'

  # ---------------------------------------------------------------------------
  # Statements / Billing rules / Rewards / Accuracy
  # ---------------------------------------------------------------------------

  @api @functional @TC-STMT-01
  Scenario: Retrieve statement defaults to JSON and returns required statement fields
    Given I am authenticated as 'test+stmt01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response header 'Content-Type' should contain 'application/json'
    And the response JSON should contain:
      | path                |
      | statement_date      |
      | total_spend         |
      | adb                 |
      | interest_charged    |
      | late_fee            |
      | rewards_earned      |
      | minimum_payment_due |
      | due_date            |

  @api @functional @TC-STMT-02
  Scenario: Retrieve statement in PDF when format=PDF
    Given I am authenticated as 'test+stmt02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=PDF' with headers:
      | Header        | Value                |
      | Authorization | Bearer ${access_token} |
      | Accept        | application/pdf      |
    Then the response status should be 200
    And the response header 'Content-Type' should contain 'application/pdf'
    And the response body should start with '%PDF'

  @api @negative @TC-STMT-03
  Scenario Outline: Retrieve statement returns 404 NOT_FOUND when statement missing (JSON or PDF)
    Given I am authenticated as 'test+stmt03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/00000000-1111-2222-3333-444444444444<query>' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 404
    And the response JSON path 'error' should equal 'NOT_FOUND'

    Examples:
      | query        |
      |              |
      | ?format=JSON |

  @api @functional @TC-INT-01
  Scenario: Interest computed using ADB formula for a known statement fixture
    Given I am authenticated as 'test+int01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with statement fixture adb=1000.00 apr=0.1999 days_in_billing_cycle=30
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON path 'adb' should equal '1000.00'
    And the response JSON path 'interest_charged' should equal '16.43'

  @api @boundary @TC-INT-02
  Scenario Outline: Interest scales with Days_in_Billing_Cycle boundaries (28/30/31)
    Given I am authenticated as 'test+int02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have a generated statement_id '<statement_id>' with fixture adb=2500.00 apr=0.2499 days_in_billing_cycle=<days>
    When I send a GET request to '/v2/accounts/${account_id}/statements/<statement_id>?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON path 'interest_charged' should equal '<expected_interest>'

    Examples:
      | statement_id                              | days | expected_interest |
      | ${STMT_ID_28_DAY}                          | 28   | 47.91             |
      | ${STMT_ID_30_DAY}                          | 30   | 51.33             |
      | ${STMT_ID_31_DAY}                          | 31   | 53.04             |

  @api @functional @TC-LATEFEE-01
  Scenario: Late fee charged when payment_received_date > due_date + 2 days
    Given I am authenticated as 'test+latefee01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with statement fixture due_date=2026-04-10 payment_received_date=2026-04-13
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON path 'late_fee' should equal '35.00'

  @api @boundary @TC-LATEFEE-02
  Scenario: Late fee boundary - no late fee when payment_received_date equals due_date + 2 days
    Given I am authenticated as 'test+latefee02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with statement fixture due_date=2026-04-10 payment_received_date=2026-04-12
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON path 'late_fee' should not equal '35.00'

  @api @functional @TC-REW-01
  Scenario: Rewards accrual for Travel MCC uses floor(amount × 3) (fixture-based)
    Given I am authenticated as 'test+rew01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And the statement fixture contains a Travel MCC transaction with amount 123.45 in the cycle for statement_id '${statement_id}'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON should contain:
      | path          |
      | rewards_earned |

  @api @boundary @TC-REW-02
  Scenario: Rewards rounding uses floor() and never round/ceil (fixture-based)
    Given I am authenticated as 'test+rew02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And the statement fixture contains exactly two transactions in the cycle:
      | category   | amount |
      | TRAVEL_MCC | 0.34   |
      | OTHER      | 1.99   |
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response JSON path 'rewards_earned' should equal '2'

  @api @functional @TC-STMTACC-01
  Scenario: Statement accuracy - sum(transaction_amount[]) equals total_spend within ±0.01
    Given I am authenticated as 'test+stmtacc01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have an existing generated statement_id stored as 'statement_id' with cycle start '${CYCLE_START}' and cycle end '${CYCLE_END}'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    When I store the response JSON path 'total_spend' as 'total_spend'
    And I send a GET request to '/v2/accounts/${account_id}/transactions?from_date=${CYCLE_START}&to_date=${CYCLE_END}&per_page=100&page=1' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the computed sum of transaction_amount in the response should be within 0.01 of '${total_spend}'

  # ---------------------------------------------------------------------------
  # Payments
  # ---------------------------------------------------------------------------

  @api @functional @TC-PAY-01
  Scenario: Make immediate payment (scheduled_date omitted) returns payment_id and new_balance_estimate (CSRF enforced)
    Given I am authenticated as 'test+pay01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have a linked bank_account_id stored as 'bank_account_id'
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "payment_amount": 25.00,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should not be 200
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 25.00,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path                |
      | payment_id          |
      | new_balance_estimate |

  @api @functional @TC-PAY-02
  Scenario Outline: Make scheduled payment returns scheduled_date in response
    Given I am authenticated as 'test+pay02@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have a linked bank_account_id stored as 'bank_account_id'
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 50.00,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}",
        "scheduled_date": "<scheduled_date>"
      }
      """
    Then the response status should be 200
    And the response JSON path 'scheduled_date' should equal '<scheduled_date>'
    And the response JSON should contain:
      | path                |
      | payment_id          |
      | new_balance_estimate |

    Examples:
      | scheduled_date |
      | 2026-05-15     |
      | 2026-05-16     |

  @api @boundary @TC-PAY-03
  Scenario Outline: Payment amount minimum boundary (1.00 accepted; 0.99 rejected)
    Given I am authenticated as 'test+pay03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have a linked bank_account_id stored as 'bank_account_id'
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": <payment_amount>,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should be <status>
    And for status 200 the response JSON should contain:
      | path                |
      | payment_id          |
      | new_balance_estimate |

    Examples:
      | payment_amount | status |
      | 1.00           | 200    |
      | 0.99           | 400    |

  @api @negative @TC-PAY-04
  Scenario: Payment below minimum_payment_due returns 400 BELOW_MINIMUM with minimum_payment_due
    Given I am authenticated as 'test+pay04@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have a linked bank_account_id stored as 'bank_account_id'
    And I have an existing generated statement_id stored as 'statement_id'
    When I send a GET request to '/v2/accounts/${account_id}/statements/${statement_id}?format=JSON' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    When I store the response JSON path 'minimum_payment_due' as 'minimum_payment_due'
    And I compute 'below_min' as '${minimum_payment_due} - 0.01'
    And I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": ${below_min},
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should be 400
    And the response JSON path 'error' should equal 'BELOW_MINIMUM'
    And the response JSON should contain:
      | path                |
      | minimum_payment_due |
    And the response JSON should not contain:
      | path       |
      | payment_id |

  @api @functional @TC-PAY-05
  Scenario: Payment requires bank_account_id from /v2/bank-accounts
    Given I am authenticated as 'test+pay05@example.com' with password 'Str0ng!Passw0rd'
    When I send a GET request to '/v2/bank-accounts' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    When I store a bank_account_id from the response as 'bank_account_id'
    And I have an owned account_id stored as 'account_id'
    And I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 25.00,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path       |
      | payment_id |

  @api @negative @TC-PAY-06
  Scenario: Payment rejects unlinked bank_account_id with 422 INVALID_BANK_ACCOUNT
    Given I am authenticated as 'test+pay06@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 50.00,
        "payment_type": "CUSTOM",
        "bank_account_id": "11111111-2222-4333-8444-555555555555"
      }
      """
    Then the response status should be 422
    And the response JSON path 'error' should equal 'INVALID_BANK_ACCOUNT'

  @api @boundary @TC-PAY-07
  Scenario Outline: Payment_type enum validation
    Given I am authenticated as 'test+pay07@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    And I have a linked bank_account_id stored as 'bank_account_id'
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 10.00,
        "payment_type": "<payment_type>",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should be <status>

    Examples:
      | payment_type       | status |
      | MINIMUM            | 200    |
      | STATEMENT_BALANCE  | 200    |
      | CUSTOM             | 200    |
      | FULL_BALANCE       | 200    |
      | UNKNOWN_TYPE       | 400    |

  @api @boundary @TC-PAY-08
  Scenario: Payment amount max equals total_balance (at-max accepted; just-over rejected)
    Given I am authenticated as 'test+pay08@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id' with total_balance fixture value 250.00
    And I have a linked bank_account_id stored as 'bank_account_id'
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 250.00,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should be 200
    When I send a POST request to '/v2/accounts/${account_id}/payments' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "payment_amount": 250.01,
        "payment_type": "CUSTOM",
        "bank_account_id": "${bank_account_id}"
      }
      """
    Then the response status should not be 200

  # ---------------------------------------------------------------------------
  # CSRF enforcement (API)
  # ---------------------------------------------------------------------------

  @api @security @TC-CSRF-01
  Scenario Outline: State-changing endpoints reject missing/invalid X-CSRF-Token
    Given I am authenticated as 'test+csrf01@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | <csrf_token>           |
    And payload:
      """
      {
        "status": "Frozen",
        "reason": "QA CSRF test",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be <status>

    Examples:
      | csrf_token      | status |
      |                 | 403    |
      | invalid-token   | 403    |
      | ${CSRF_TOKEN}   | 200    |

  @api @security @TC-CSRF-03
  Scenario: CSRF token required even when Authorization uses Bearer token
    Given I am authenticated as 'test+csrf03@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "status": "Frozen",
        "reason": "QA CSRF+Bearer",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should not be 200
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "status": "Frozen",
        "reason": "QA CSRF+Bearer",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be 200

  # ---------------------------------------------------------------------------
  # Security: PAN not transmitted (UI + API observations)
  # ---------------------------------------------------------------------------

  @ui @security @TC-PAN-02
  Scenario: Full PAN never transmitted to frontend (HAR scan)
    Given I open a clean browser context
    And I start network recording
    When I log in via the portal UI with email 'test+pan02@example.com' and password 'Str0ng!Passw0rd'
    And I navigate through dashboard areas that load card/account data
    Then the exported HAR should not contain PAN-like digit sequences of 13 to 19 digits
    And the exported HAR should not contain keys 'pan' or 'card_number' with unmasked values

  @api @security @TC-PAN-02
  Scenario Outline: Selected API responses do not include raw PAN fields or PAN-like sequences
    Given I am authenticated as 'test+panapi@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a <method> request to '<endpoint>' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the response body should not match the regex '\d{13,19}'
    And the response body should not contain '"pan"'
    And the response body should not contain '"card_number"'

    Examples:
      | method | endpoint                                      |
      | GET    | /v2/accounts/${account_id}/summary            |
      | GET    | /v2/accounts/${account_id}/statements/${STATEMENT_ID}?format=JSON |

  # ---------------------------------------------------------------------------
  # Webhooks: Notifications
  # ---------------------------------------------------------------------------

  @api @functional @TC-WEBHOOK-01
  Scenario: Notifications webhook accepts valid payload and returns notification_id and delivered_at
    Given I generate a UUIDv4 as 'idempotency_key'
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "${ACCOUNT_ID}",
        "alert_type": "STATEMENT_READY",
        "channel": "IN_APP",
        "message_body": "Statement is ready",
        "severity": "INFO",
        "idempotency_key": "${idempotency_key}"
      }
      """
    Then the response status should be 200
    And the response JSON should contain:
      | path            |
      | notification_id |
      | delivered_at    |
      | channel         |
    And the response JSON path 'channel' should equal 'IN_APP'

  @api @negative @TC-WEBHOOK-02
  Scenario Outline: Notifications webhook rejects unknown alert_type or channel with 400 INVALID_ALERT_TYPE
    Given I generate a UUIDv4 as 'idempotency_key'
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "${ACCOUNT_ID}",
        "alert_type": "<alert_type>",
        "channel": "<channel>",
        "message_body": "Test",
        "severity": "INFO",
        "idempotency_key": "${idempotency_key}"
      }
      """
    Then the response status should be 400
    And the response JSON path 'error' should equal 'INVALID_ALERT_TYPE'

    Examples:
      | alert_type     | channel |
      | UNKNOWN_TYPE   | EMAIL   |
      | LATE_PAYMENT   | FAX     |

  @api @boundary @TC-WEBHOOK-03
  Scenario Outline: Notifications webhook enforces message_body max length boundary
    Given I generate a UUIDv4 as 'idempotency_key'
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "${ACCOUNT_ID}",
        "alert_type": "STATEMENT_READY",
        "channel": "IN_APP",
        "message_body": "<message_body>",
        "severity": "INFO",
        "idempotency_key": "${idempotency_key}"
      }
      """
    Then the response status should be <status>

    Examples:
      | message_body        | status |
      | ${STRING_LEN_500}   | 200    |
      | ${STRING_LEN_501}   | 400    |

  @api @resilience @TC-IDEMP-01
  Scenario: Notifications webhook idempotency duplicate idempotency_key returns 409 DUPLICATE_NOTIFICATION
    Given I generate a UUIDv4 as 'idempotency_key'
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "${ACCOUNT_ID}",
        "alert_type": "FRAUD_FLAG",
        "channel": "SMS",
        "message_body": "Potential fraud detected",
        "severity": "CRITICAL",
        "idempotency_key": "${idempotency_key}"
      }
      """
    Then the response status should be 200
    When I send the same POST request to '/v2/notifications/webhook' again with the same payload
    Then the response status should be 409
    And the response JSON path 'error' should equal 'DUPLICATE_NOTIFICATION'

  @api @boundary @TC-NOTIF-01
  Scenario Outline: Notifications webhook enforces idempotency_key UUID v4 format
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee",
        "alert_type": "STATEMENT_READY",
        "channel": "IN_APP",
        "message_body": "Statement is ready.",
        "severity": "INFO",
        "idempotency_key": "<idempotency_key>"
      }
      """
    Then the response status should be <status>

    Examples:
      | idempotency_key                            | status |
      | 3fa85f64-5717-4562-b3fc-2c963f66afa6       | 200    |
      | not-a-uuid                                  | 400    |
      | 6ba7b810-9dad-11d1-80b4-00c04fd430c8       | 400    |

  @api @boundary @TC-NOTIF-02
  Scenario Outline: Notifications webhook enforces alert_type enum
    Given I generate a UUIDv4 as 'idempotency_key'
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "${ACCOUNT_ID}",
        "alert_type": "<alert_type>",
        "channel": "EMAIL",
        "message_body": "Statement is ready for viewing.",
        "severity": "INFO",
        "idempotency_key": "${idempotency_key}"
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'error' should equal 'INVALID_ALERT_TYPE'

    Examples:
      | alert_type        | status |
      | STATEMENT_READY   | 200    |
      | OVER_LIMIT        | 200    |
      | OVERLIMIT         | 400    |
      | STATEMENT_READY   | 200    |

  @api @boundary @TC-NOTIF-03
  Scenario Outline: Notifications webhook enforces severity enum INFO/WARNING/CRITICAL
    Given I generate a UUIDv4 as 'idempotency_key'
    When I send a POST request to '/v2/notifications/webhook' with payload:
      """
      {
        "account_id": "${ACCOUNT_ID}",
        "alert_type": "FRAUD_FLAG",
        "channel": "IN_APP",
        "message_body": "Security alert.",
        "severity": "<severity>",
        "idempotency_key": "${idempotency_key}"
      }
      """
    Then the response status should be <status>
    And for status 400 the response JSON path 'error' should equal 'INVALID_ALERT_TYPE'

    Examples:
      | severity  | status |
      | INFO      | 200    |
      | WARNING   | 200    |
      | CRITICAL  | 200    |
      | HIGH      | 400    |
      | critical  | 400    |

  # ---------------------------------------------------------------------------
  # WebSocket
  # ---------------------------------------------------------------------------

  @api @functional @TC-WS-01
  Scenario: WebSocket endpoint reachable for live transaction feed
    Given the DNS name 'realtime.aegiscard.com' resolves to at least one IP address
    When I open a WebSocket connection to '${REALTIME_WS_URL}'
    Then the WebSocket handshake should result in one of:
      | status |
      | 101    |
      | 401    |
      | 403    |
    And I capture the handshake response headers for evidence

  # ---------------------------------------------------------------------------
  # Right to rescind
  # ---------------------------------------------------------------------------

  @api @functional @TC-RESCIND-01
  Scenario: Right to rescind allowed within 14 days via DELETE /v2/accounts/{id}
    Given I am authenticated as the owner of account '${RESCIND_ACCOUNT_ID_WITHIN_14_DAYS}'
    And the account issuance age is 13 days
    When I send a DELETE request to '/v2/accounts/${RESCIND_ACCOUNT_ID_WITHIN_14_DAYS}' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    Then the response status should be one of:
      | status |
      | 200    |
      | 204    |
    When I send a GET request to '/v2/accounts/${RESCIND_ACCOUNT_ID_WITHIN_14_DAYS}/summary' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should not be 200

  @api @boundary @TC-RESCIND-02
  Scenario: Right to rescind rejected after day 14
    Given I am authenticated as the owner of account '${RESCIND_ACCOUNT_ID_AFTER_14_DAYS}'
    And the account issuance age is 15 days
    When I send a DELETE request to '/v2/accounts/${RESCIND_ACCOUNT_ID_AFTER_14_DAYS}' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    Then the response status should not be one of:
      | status |
      | 200    |
      | 204    |
    When I send a GET request to '/v2/accounts/${RESCIND_ACCOUNT_ID_AFTER_14_DAYS}/summary' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200

  # ---------------------------------------------------------------------------
  # Architecture / OAuth / TLS form submissions (UI + observable security)
  # ---------------------------------------------------------------------------

  @ui @security @TC-PCI-01
  Scenario: Portal and API used by forms negotiate TLS 1.3 (no TLS 1.2 downgrade)
    Given I open a clean browser context
    When I am on the '${PORTAL_BASE_URL}' page
    Then the portal security details should show TLS version 'TLS 1.3'
    When I attempt a TLS handshake to host 'api.aegiscard.com' on port 443 forcing TLS1.2
    Then the TLS handshake result should be FAILURE
    When I attempt a TLS handshake to host 'api.aegiscard.com' on port 443 forcing TLS1.3
    Then the TLS handshake result should be SUCCESS

  @ui @security @TC-AUTH-01
  Scenario: OAuth 2.0 Authorization Code Flow with PKCE is observable during portal login
    Given I open a clean browser context
    And I start network recording
    When I click the 'Log in' control on the portal
    Then I should see an authorization request that includes PKCE parameters 'code_challenge' and 'code_challenge_method'
    When I complete login with valid credentials
    Then I should see a token exchange request that includes a PKCE parameter 'code_verifier'

  # ---------------------------------------------------------------------------
  # Non-functional: performance / scaling / autoscaling / audit trail (high-level)
  # ---------------------------------------------------------------------------

  @performance @api @TC-APISLA-01
  Scenario: API p95 latency meets ≤ 1500 ms target for GET /summary under representative load
    Given a load test profile is configured for endpoint '/v2/accounts/${ACCOUNT_ID}/summary' at 50 rps for 10 minutes
    When I execute the load test and collect latency metrics
    Then the p95 latency should be less than or equal to 1500 milliseconds
    And the non-2xx error rate should be less than or equal to 1 percent

  @performance @ui @TC-TTI-01
  Scenario: Portal Time-to-Interactive (TTI) meets ≤ 3s on 4G (5 runs)
    Given I configure network throttling to a 4G profile
    When I run 5 TTI measurements against '${PORTAL_BASE_URL}'
    Then each run should have TTI less than or equal to 3.0 seconds

  @performance @api @TC-SCALE-01
  Scenario: API gateway sustains 5000 requests/sec while maintaining response correctness for GET /summary
    Given a load test profile is configured for endpoint '/v2/accounts/${ACCOUNT_ID}/summary' at 5000 rps for 5 minutes
    When I execute the load test and sample 100 responses during the run
    Then all sampled responses should be HTTP 200
    And all sampled responses should be valid JSON containing required summary keys

  @resilience @api @TC-AUTOSCALE-01
  Scenario: Auto-scaling triggers at 70% CPU utilization and service remains available
    Given I have access to infrastructure metrics for CPU utilization and scaling events
    And I have a continuous availability probe running against '/v2/accounts/${ACCOUNT_ID}/summary'
    When I ramp load until CPU utilization reaches 70 percent
    Then a scale-out event should be observed
    And the availability probe should continue to receive HTTP 200 responses during scale-out

  @audit @api @TC-AUDIT-01
  Scenario: Credit_limit changes create immutable audit log entry with required fields
    Given I have privileged access to perform a controlled credit_limit change for account '${AUDIT_ACCOUNT_ID}'
    When I change the credit_limit from 5000.00 to 6000.00 for account '${AUDIT_ACCOUNT_ID}'
    Then an audit log entry should exist for the credit_limit change
    And the audit log entry should contain:
      | field         |
      | user_id       |
      | session_id    |
      | ip_address    |
      | timestamp_utc |
    And the audit log entry should be immutable on re-query

  # ---------------------------------------------------------------------------
  # E2E flows (API-led)
  # ---------------------------------------------------------------------------

  @api @e2e @TC-E2E-01
  Scenario: E2E Register -> Login -> Step1 -> Step2 -> Step3 approved
    Given I have generated a unique email 'test+e2e01-${RUN_ID}@example.com'
    When I send a POST request to '/v2/auth/register' with payload:
      """
      {
        "first_name": "E2E",
        "last_name": "User",
        "email": "test+e2e01-${RUN_ID}@example.com",
        "password": "Str0ng!Passw0rd",
        "date_of_birth": "1990-01-15",
        "phone_number": "+14165550101",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
    Then the response status should be 201
    When I send a POST request to '/v2/auth/login' with payload:
      """
      {
        "email": "test+e2e01-${RUN_ID}@example.com",
        "password": "Str0ng!Passw0rd"
      }
      """
    Then the response status should be 200
    When I store the response JSON path 'access_token' as 'access_token'
    And I send a POST request to '/v2/applications/start' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "full_legal_name": "E2E User",
        "email": "test+e2e01-${RUN_ID}@example.com",
        "phone_number": "+14165550101",
        "residential_address": {
          "street": "100 King St W",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M5H 1J9"
        },
        "id_type": "PASSPORT",
        "id_number": "A1B2C3D4"
      }
      """
    Then the response status should be 201
    When I store the response JSON path 'application_id' as 'application_id'
    And I store the response JSON path 'session_token' as 'session_token'
    And I send a POST request to '/v2/applications/${application_id}/financials' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "employment_status": "SELF_EMPLOYED",
        "gross_annual_income": 85000.00,
        "monthly_rent": 1800.00,
        "existing_debt_payments": 250.00,
        "sin_consent": true
      }
      """
    Then the response status should be 200
    And the decisioning stub is configured for application '${application_id}' with FICO value 700
    When I send a POST request to '/v2/applications/${application_id}/submit' with headers:
      | Header        | Value                    |
      | Authorization | Bearer ${access_token}   |
      | X-App-Session | ${session_token}         |
    And payload:
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "Sm9obiBEb2U="
      }
      """
    Then the response status should be 200
    And the response JSON path 'decision' should equal 'APPROVED'
    And the response JSON should contain:
      | path               |
      | credit_limit       |
      | card_number_masked |

  @api @e2e @TC-E2E-04
  Scenario: E2E Login -> Initiate transaction -> Verify it appears in list
    Given I am authenticated as 'test+e2e04@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned account_id stored as 'account_id'
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 12.34,
        "merchant_name": "Test Coffee Shop",
        "merchant_id": "TESTMERCH12345",
        "mcc_code": "5814",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE",
        "description": "E2E purchase"
      }
      """
    Then the response status should be 200
    When I store the response JSON path 'transaction_id' as 'transaction_id'
    And I send a GET request to '/v2/accounts/${account_id}/transactions?from_date=${TODAY}&to_date=${TODAY}&page=1&per_page=25' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    Then the response status should be 200
    And the transactions list should include an item with transaction_id '${transaction_id}'

  @api @e2e @TC-E2E-06
  Scenario: E2E Freeze card -> attempt transaction -> 403 CARD_INACTIVE with card_status -> unfreeze cleanup
    Given I am authenticated as 'test+e2e06@example.com' with password 'Str0ng!Passw0rd'
    And I have an owned card_id stored as 'card_id' in status 'Active'
    And I have an owned account_id stored as 'account_id'
    And I have a valid 6-digit confirm_otp as 'confirm_otp'
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "status": "Frozen",
        "reason": "E2E freeze test",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be 200
    When I send a POST request to '/v2/accounts/${account_id}/transactions' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
    And payload:
      """
      {
        "transaction_amount": 5.00,
        "merchant_name": "Freeze Test Merchant",
        "merchant_id": "FRZ0001",
        "mcc_code": "5999",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be 403
    And the response JSON path 'error' should equal 'CARD_INACTIVE'
    And the response JSON should contain:
      | path        |
      | card_status |
    When I send a PATCH request to '/v2/cards/${card_id}/status' with headers:
      | Header        | Value                  |
      | Authorization | Bearer ${access_token} |
      | X-CSRF-Token  | ${CSRF_TOKEN}          |
    And payload:
      """
      {
        "status": "Active",
        "reason": "E2E unfreeze cleanup",
        "confirm_otp": "${confirm_otp}"
      }
      """
    Then the response status should be 200
    And the response JSON path 'new_status' should equal 'Active'
