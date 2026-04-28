Feature: Aegis Card Portal and API End-to-End and Functional Validation

  # Common environment setup
  Background:
    Given the API base URL is 'https://api.aegiscard.com'
    And the Portal URL is 'https://portal.aegiscard.com'
    And transport security TLS 1.3 is enforced
    And WAF and rate limits are active
    And default request content type is 'application/json'
    And no tokens are stored in browser localStorage or sessionStorage by design

  # API Tests

  @api @e2e @registration @applications @security
  Scenario: End-to-end registration, verification, MFA login, 3-step application, approval for FICO > 680, and masked PAN returned by summary
    Given I navigate to the portal Registration page over TLS 1.3
    When I send a POST request to '/v2/auth/register' with JSON payload
      """
      {
        "first_name": "Jo",
        "last_name": "Tester",
        "email": "user+test@domain.com",
        "password": "weakPass1!",
        "date_of_birth": "YYYY-17yo",
        "phone_number": "+14165551234",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 422
      And the response should contain field errors for 'date_of_birth' and 'password'
    When I resend a POST request to '/v2/auth/register' with JSON payload
      """
      {
        "first_name": "Jo",
        "last_name": "Tester",
        "email": "user+test@domain.com",
        "password": "Stronger!Passw0rd",
        "date_of_birth": "YYYY-18y-1d",
        "phone_number": "+14165551234",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 201
      And the response should contain 'user_id' and 'verification_token'
      And Set-Cookie headers must include HttpOnly, Secure, SameSite=Strict
    When I send a GET request to '/v2/auth/verify?token=<verification_token>'
    Then the response status should be 200
      And the response should indicate 'verified' true
    When I send a POST request to '/v2/auth/login' with JSON payload
      """
      {
        "email": "user+test@domain.com",
        "password": "Stronger!Passw0rd",
        "device_id": "550e8400-e29b-41d4-a716-446655440000",
        "remember_me": true,
        "mfa_code": "123456"
      }
      """
    Then the response status should be 200
      And the response should contain 'access_token', 'refresh_token', 'expires_in'
      And Set-Cookie headers must include HttpOnly, Secure, SameSite=Strict
    When I acquire a CSRF token from the portal session
    And I send a POST request to '/v2/applications/start' with JSON payload
      """
      {
        "full_legal_name": "Jo Tester",
        "email": "user+test@domain.com",
        "phone_number": "+14165551234",
        "residential_address": {
          "street": "123 King St",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "A1A 1A1"
        },
        "id_type": "DRIVERS_LICENSE",
        "id_number": "DL123456"
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 201
      And the response should contain 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/<application_id>/financials' with JSON payload
      """
      {
        "employment_status": "EMPLOYED",
        "employer_name": "ACME Corp",
        "gross_annual_income": 85000.00,
        "monthly_rent": 1200.00,
        "existing_debt_payments": 300.00,
        "sin_consent": true
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'status' equal to 'PENDING_REVIEW' and 'fico_pull_id'
    When I send a POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_GOLD",
        "e_signature": "Ym9iIHRlc3Rlcg=="
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'decision' equal to 'APPROVED'
      And the response should contain 'credit_limit' and 'card_number_masked'
    When I send a GET request to '/v2/accounts/<account_id>/summary?include_rewards=true'
    Then the response status should be 200
      And the response should contain a masked PAN field matching '**** **** **** 1234'
      And the response should not contain any raw PAN
      And the response should contain 'points_balance'
      And all auth cookies remain HttpOnly, Secure, SameSite=Strict
      And no token is stored in localStorage

  @api @applications
  Scenario: Application decision PENDING and DECLINED with duplicate application control and signature requirement
    Given I am logged in as 'pending_user@domain.com' with valid MFA and have a CSRF token
    When I send a POST request to '/v2/applications/start' with valid Step 1 data and CSRF
    Then the response status should be 201
      And I capture 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/<application_id>/financials' with JSON payload
      """
      {
        "employment_status": "EMPLOYED",
        "employer_name": "ACME",
        "gross_annual_income": 60000.00,
        "monthly_rent": 1500.00,
        "existing_debt_payments": 400.00,
        "sin_consent": true
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'fico_pull_id' and 'status' equal to 'PENDING_REVIEW'
    When I send a POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER",
        "e_signature": "SmFuZSBTaWduYXR1cmU="
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'decision' equal to 'PENDING' and 'review_eta_hours'
    When I send a POST request to '/v2/applications/start' with valid Step 1 data and CSRF for the same user
    Then the response status should be 409
      And the response should contain error 'DUPLICATE_APPLICATION'
    When I logout and login as 'declined_user@domain.com' with valid MFA and CSRF
    And I send a POST request to '/v2/applications/start' with valid Step 1 data and CSRF
    Then the response status should be 201
      And I capture 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/<application_id>/financials' with JSON payload
      """
      {
        "employment_status": "UNEMPLOYED",
        "gross_annual_income": 12000.00,
        "monthly_rent": 800.00,
        "existing_debt_payments": 500.00,
        "sin_consent": true
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'fico_pull_id'
    When I send a POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER"
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 400
      And the response should contain error 'SIGNATURE_REQUIRED'
    When I resend the POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER",
        "e_signature": "SmFuZSBEb2U="
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'decision' equal to 'DECLINED'
      And the response should contain 'reason_code'
      And the response should have 'marketing_opt_in' false when omitted

  @api @auth
  Scenario: Login lockout after five failures, rate limiting, MFA enforcement, and remember_me cookie TTL
    Given the verified user 'user+lockout@domain.com' exists and the portal is reachable over TLS 1.3
    When I attempt 4 POST requests to '/v2/auth/login' within one minute with wrong password and no MFA
    Then each response status should be 401 with error 'INVALID_CREDENTIALS'
    When I attempt a 5th POST to '/v2/auth/login' with wrong password
    Then the response status should be 403
      And the response should contain 'unlock_at'
    When I immediately attempt a 6th login within the same minute
    Then the response status should be 429
      And the response should contain 'retry_after'
    When I wait until 'unlock_at' passes and login with correct password but missing 'mfa_code'
    Then the response status should be 401
      And the response should contain error 'INVALID_CREDENTIALS'
    When I login with correct password and incorrect 'mfa_code'
    Then the response status should be 401
      And the response should contain error 'INVALID_CREDENTIALS'
    When I login with correct password, valid TOTP, 'device_id' set, and 'remember_me' true
    Then the response status should be 200
      And the response should contain 'access_token', 'refresh_token', 'expires_in'
      And Set-Cookie headers must include HttpOnly, Secure, SameSite=Strict
      And the refresh token cookie expiry should be approximately 30 days in the future
      And the access token 'expires_in' should be approximately 900 seconds

  @api @auth
  Scenario: Refresh token rotation with single-use invalidation and concurrent refresh behavior
    Given I am logged in as 'user+refresh@domain.com' with valid MFA and captured cookies
    When I call GET '/v2/accounts/<account_id>/summary' with access token A1
    Then the response status should be 200
    When I wait until near expiry (~14 minutes) and send POST '/v2/auth/token/refresh' with refresh token R1
    Then the response status should be 200
      And I capture new access token A2 and refresh token R2
    When I attempt POST '/v2/auth/token/refresh' again with old refresh token R1
    Then the response status should be 401
      And the response should contain error 'TOKEN_INVALID'
    When I send two concurrent POST '/v2/auth/token/refresh' requests with R2
    Then one response status should be 200 with new tokens (A3,R3)
      And the other response status should be 401 with error 'TOKEN_INVALID'
    When I call GET '/v2/accounts/<account_id>/summary' with A3
    Then the response status should be 200
    When I attempt a protected GET with expired A1 after 15 minutes
    Then the response status should be 401
      And the response should indicate token expired
    And all auth cookies remain HttpOnly, Secure, SameSite=Strict
    And no tokens exist in localStorage

  @api @applications
  Scenario: Application sequencing, conditional employment fields, sin_consent enforcement, and X-App-Session 30-minute expiry
    Given I am logged in as 'userA@domain.com' with valid MFA and CSRF token
    When I send a POST request to '/v2/applications/00000000-0000-0000-0000-000000000000/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER",
        "e_signature": "SmFuZSBB"
      }
      """
    Then the response status should be 400
      And the response should contain error 'INVALID_SEQUENCE'
    When I send a POST request to '/v2/applications/start' with valid Step 1 data and CSRF
    Then the response status should be 201
      And I capture 'application_id' and 'session_token'
    When I send a POST request to '/v2/applications/<application_id>/financials' omitting 'employer_name' with 'employment_status' 'EMPLOYED'
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 400
      And the response should contain 'field' equal to 'employer_name'
    When I resend Step 2 with 'sin_consent' false
    Then the response status should be 400
      And the response should contain 'field' equal to 'sin_consent'
    When I resend Step 2 with 'employment_status' 'SELF_EMPLOYED', no 'employer_name', and 'sin_consent' true
    Then the response status should be 200
      And the response should contain 'fico_pull_id'
    When I wait 31 minutes and send POST '/v2/applications/<application_id>/submit' with valid card_product_id and e_signature using old X-App-Session
    Then the response status should be 401
      And the response should contain error 'SESSION_EXPIRED'
    When I send a POST request to '/v2/applications/start' again for the same user
    Then the response status should be 409
      And the response should contain error 'DUPLICATE_APPLICATION'
    When I logout and login as 'userB@domain.com' with valid MFA and CSRF
    And I complete Steps 1 and 2 with valid data using a fresh X-App-Session
    And I send POST '/v2/applications/<application_id>/submit' within 30 minutes
    Then the response status should be 200
      And the response should contain 'decision' and 'marketing_opt_in' false when omitted

  @api @applications
  Scenario Outline: Application Step 1 address and identity validation failures and success
    Given I am logged in as 'user+step1val@domain.com' with valid MFA and CSRF token
    When I send a POST request to '/v2/applications/start' with JSON payload
      """
      {
        "full_legal_name": "<full_name>",
        "email": "<email>",
        "phone_number": "<phone>",
        "residential_address": {
          "street": "100 Main St",
          "city": "Testville",
          "province": "<province>",
          "postal_code": "<postal_code>"
        },
        "id_type": "<id_type>",
        "id_number": "<id_number>"
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be <status>
      And the response should contain <expectation>

    Examples:
      | full_name         | email                          | phone         | province | postal_code | id_type         | id_number                  | status | expectation                                              |
      | Jane Applicant    | user+mismatch@domain.com       | +14165551234  | Ontario  | 12345       | DRIVERS_LICENSE | DL123456789012345678901    | 400    | field errors for 'residential_address.province' or 'postal_code' |
      | Jane Applicant    | user+step1val@domain.com       | +14165551234  | ON       | A1A1A1      | DRIVERS_LICENSE | DL123456789012345678901    | 400    | field 'residential_address.postal_code' A1A 1A1 format required |
      | Jane Applicant    | user+step1val@domain.com       | 14165551234   | ON       | A1A 1A1     | DRIVERS_LICENSE | DL12345678901234567890     | 400    | field 'phone_number' E.164 violation                         |
      | Jane Applicant    | user+step1val@domain.com       | +14165551234  | ON       | A1A 1A1     | DRIVERS_LICENSE | DL12345678901234567890     | 201    | 'application_id' and 'session_token' present                 |

  @api @applications
  Scenario: Application Step 3 validation for invalid product id, malformed e_signature, and marketing_opt_in default/explicit
    Given I am logged in as 'user+submit@domain.com' with valid MFA and CSRF token
    And I have created an application by completing Step 1 and Step 2 successfully
    When I send a POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "UNKNOWN_TIER",
        "e_signature": "SmFuZSBTaWdu"
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 400
      And the response should contain error 'INVALID_PRODUCT_ID'
    When I send a POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER",
        "e_signature": "not_base64@@@"
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 400
      And the response should contain error 'SIGNATURE_MALFORMED'
    When I send a POST request to '/v2/applications/<application_id>/submit' with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER",
        "e_signature": "SmFuZSBTaWduYXR1cmU="
      }
      """
      And I include header 'X-App-Session' with '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'decision'
      And the response should have 'marketing_opt_in' false
    When I create a new application instance and submit Step 3 with JSON payload
      """
      {
        "card_product_id": "AEGIS_SILVER",
        "e_signature": "SmFuZSBTaWduYXR1cmU=",
        "marketing_opt_in": true
      }
      """
      And I include header 'X-App-Session' with a fresh '<session_token>'
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should have 'marketing_opt_in' true

  @api @security @csrf
  Scenario: CSRF enforcement and SameSite=Strict cross-site POST rejection across endpoints
    Given I am logged in with secure HttpOnly, Secure, SameSite=Strict cookies and have a valid CSRF token
    When a cross-site client attempts a POST to 'https://api.aegiscard.com/v2/cards/<card_id>/status' without 'X-CSRF-Token'
    Then the request should be rejected with status 403
      And cookies should not be sent due to SameSite=Strict
    When I attempt a PATCH to '/v2/cards/<card_id>/status' without 'X-CSRF-Token'
    Then the response status should be 403
    When I attempt a POST to '/v2/applications/<application_id>/financials' with 'X-App-Session' but without 'X-CSRF-Token'
    Then the response status should be 403
    When I attempt a POST to '/v2/accounts/<account_id>/payments' without 'X-CSRF-Token'
    Then the response status should be 403
    When I attempt a PUT to '/v2/cards/<card_id>/pin' without 'X-CSRF-Token'
    Then the response status should be 403
    When I PATCH '/v2/cards/<card_id>/status' to Frozen with valid OTP and 'X-CSRF-Token'
    Then the response status should be 200
      And the response should contain 'new_status' equal to 'Frozen'
    When I PUT '/v2/cards/<card_id>/pin' with a valid OTP and 'X-CSRF-Token'
    Then the response status should be 200
      And the response should contain 'success' true
    When I PATCH '/v2/cards/<card_id>/status' to Active with valid OTP and 'X-CSRF-Token'
    Then the response status should be 200
      And the response should contain 'new_status' equal to 'Active'

  @api @transactions
  Scenario Outline: Transactions exchange rate precision, zero amount, foreign fee rounding, and non-essential over-limit rejection
    Given I have captured 'available_credit' from GET '/v2/accounts/<account_id>/summary' and card_status is Active
    When I send a POST request to '/v2/accounts/<account_id>/transactions' with JSON payload
      """
      {
        "transaction_amount": <amount>,
        "currency_code": "<currency>",
        "exchange_rate": <rate>,
        "mcc_code": "<mcc>",
        "merchant_name": "<merchant>",
        "merchant_id": "<mid>",
        "transaction_type": "PURCHASE"
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be <status>
      And the response should contain <expectation>

    Examples:
      | amount | currency | rate       | mcc  | merchant       | mid   | status | expectation                                                       |
      | 0.00   | CAD      | null       | 5812 | Test Zero      | T0    | 422    | error 'INVALID_AMOUNT'                                            |
      | 0.01   | USD      | 99.999999  | 7011 | Tiny Travel    | TT01  | 200    | 'foreign_fee_amount' present and totals rounded to 2 decimals     |
      | 10.00  | USD      | 100.000000 | 7011 | Bad Rate       | BR01  | 400    | error 'INVALID_EXCHANGE_RATE'                                     |
      | 5.00   | USD      | null       | 7011 | Missing Rate   | MR01  | 400    | field 'exchange_rate' required when currency != CAD               |
      | <ac+0.01> | CAD   | null       | 5812 | OverLimit Rstr | OL01  | 402    | error 'INSUFFICIENT_FUNDS' and 'available_credit' returned        |
      | 1.00   | CAD      | null       | 5411 | Normal OK      | OK01  | 200    | 'transaction_id' and 'auth_code' present                          |
      | 10.00  | USD      | 1.2345678  | 7011 | OverPrecision  | OP01  | 400    | precision validation error for 'exchange_rate'                    |

  @api @transactions @overlimit
  Scenario: Essential MCC 5% over-limit buffer boundary approvals and rejections vs non-essential MCC
    Given I have captured 'available_credit' from GET '/v2/accounts/<account_id>/summary' and card_status is Active
    And I compute 'boundary_amount' as 'available_credit * 1.05 rounded 2dp'
    And I compute 'beyond_amount' as 'available_credit * 1.051 rounded 2dp'
    When I POST a CAD transaction at 'boundary_amount' with mcc_code '5912' (pharmacy) and X-CSRF-Token
    Then the response status should be 200
      And the response should contain 'over_limit_flag' true
    When I POST a CAD transaction at 'beyond_amount' with mcc_code '5912' (pharmacy)
    Then the response status should be 402
      And the response should contain error 'INSUFFICIENT_FUNDS'
    When I POST a CAD transaction at 'boundary_amount' with mcc_code '8062' (medical)
    Then the response status should be 200
      And the response should contain 'over_limit_flag' true
    When I POST a CAD transaction at 'beyond_amount' with mcc_code '8062' (medical)
    Then the response status should be 402
      And the response should contain error 'INSUFFICIENT_FUNDS'
    When I POST a CAD transaction of 'available_credit + 0.01' with mcc_code '5812' (restaurant)
    Then the response status should be 402
      And the response should contain error 'INSUFFICIENT_FUNDS'
    When I POST a CAD transaction of 5.00 with mcc_code '5912'
    Then the response status should be 200
      And the response should not contain 'over_limit_flag' or it is false

  @api @cards @security
  Scenario: Freeze card prevents transactions, unfreeze via OTP, essential buffer boundary, and 60-minute frequency limit with MFA requirement
    Given I have captured 'available_credit' and card status Active via GET '/v2/accounts/<account_id>/summary'
    When I PATCH '/v2/cards/<card_id>/status' with JSON payload
      """
      { "status": "Frozen", "confirm_otp": "123456" }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'new_status' equal to 'Frozen'
    When I POST '/v2/accounts/<account_id>/transactions' for CAD 10.00 mcc_code 5411
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 403
      And the response should contain error 'CARD_INACTIVE'
    When I PATCH '/v2/cards/<card_id>/status' with JSON payload
      """
      { "status": "Active", "confirm_otp": "123456" }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'new_status' equal to 'Active'
    And I compute 'essential_boundary_amount' as 'available_credit * 1.05 rounded 2dp'
    When I POST an essential CAD transaction at 'essential_boundary_amount' with mcc_code 4900 (utilities)
    Then the response status should be 200
      And the response should contain 'over_limit_flag' true
    When I POST an essential CAD transaction at 'available_credit * 1.051 rounded 2dp' with mcc_code 4900 (utilities)
    Then the response status should be 402
      And the response should contain error 'INSUFFICIENT_FUNDS'
    When I execute 10 small CAD transactions within 60 minutes
    Then the tenth response status should be 200
    When I submit an 11th transaction within the same 60 minutes window
    Then the response status should be 429
      And the response should contain 'mfa_required' true
      And the 'Retry-After' header should be present
    When I complete the MFA challenge and retry the transaction with CSRF
    Then the response status should be 200
      And the response should contain 'auth_code'

  @api @cards @security
  Scenario: Report card stolen is irreversible, forbids PIN and status changes, denies transactions, schedules replacement, and handles duplicates
    Given I confirm card status Active via GET '/v2/accounts/<account_id>/summary'
    When I POST '/v2/cards/<card_id>/report-lost' with JSON payload
      """
      {
        "loss_type": "STOLEN",
        "last_known_use": "2026-04-01T23:59:59Z",
        "delivery_address": { "street": "1 New St", "city": "Toronto", "province": "ON", "postal_code": "A1A 1A1" }
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'blocked_card_id', 'new_card_eta', 'case_number'
    When I PATCH '/v2/cards/<card_id>/status' to Active with valid OTP
    Then the response status should be 400
      And the response should contain error 'INVALID_TRANSITION'
    When I PUT '/v2/cards/<card_id>/pin' with JSON payload
      """
      { "new_pin": "1234", "confirm_pin": "1234", "session_otp": "123456" }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 403
      And the response should contain error 'CARD_BLOCKED'
    When I POST '/v2/accounts/<account_id>/transactions' for CAD 5.00
    Then the response status should be 403
      And the response should contain error 'CARD_INACTIVE'
    When I POST '/v2/cards/<card_id>/report-lost' again with 'STOLEN'
    Then the response status should be 409
      And the response should contain error 'ALREADY_BLOCKED'

  @api @transactions @listing
  Scenario: List transactions with date boundaries, pagination limits, category filter, and owner-only access
    Given I am logged in as 'user+history@domain.com' with valid MFA
    When I GET '/v2/accounts/A-OWN/transactions' without query params
    Then the response status should be 200
      And the response should contain 'transactions', 'total_count', 'page', 'total_pages'
    When I GET '/v2/accounts/A-OWN/transactions?from_date=2026-03-01&to_date=2026-03-01'
    Then the response status should be 200
      And only transactions from 2026-03-01 are returned
    When I GET '/v2/accounts/A-OWN/transactions?from_date=2026-03-10&to_date=2026-03-05'
    Then the response status should be 400
      And the response should contain error 'INVALID_DATE_RANGE'
    When I GET '/v2/accounts/A-OWN/transactions?page=2&per_page=100'
    Then the response status should be 200
      And up to 100 items are returned and paging metadata is correct
    When I GET '/v2/accounts/A-OWN/transactions?per_page=101'
    Then the response status should be 400 or clamped behavior is documented as observed
    When I GET '/v2/accounts/A-OWN/transactions?category=REFUND'
    Then the response status should be 200
      And all items have 'category' equal to 'REFUND'
    When I GET '/v2/accounts/A-OTHER/transactions'
    Then the response status should be 403
      And no data leakage occurs
    And no raw PAN appears in any response payload

  @api @payments
  Scenario Outline: Payments validation for minimum amount, bank account validity, date scheduling, owner-only access, and success cases
    Given I am logged in as 'user+pay@domain.com' with valid MFA and CSRF token
    And I have captured 'total_balance' and 'minimum_payment_due' from account summary and statement
    When I send a POST request to '/v2/accounts/<account>/payments' with JSON payload
      """
      {
        "payment_amount": <amount>,
        "payment_type": "<ptype>",
        "bank_account_id": "<bank>",
        "scheduled_date": "<schedule>"
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be <status>
      And the response should contain <expectation>

    Examples:
      | account      | amount | ptype            | bank     | schedule    | status | expectation                                   |
      | <own>        | 0.99   | MINIMUM          | BANK-OK  | null        | 400    | error 'BELOW_MINIMUM' and 'minimum_payment_due' field |
      | <own>        | 5.00   | CUSTOM           | BANK-BAD | null        | 422    | error 'INVALID_BANK_ACCOUNT'                  |
      | <own>        | 2.00   | CUSTOM           | BANK-OK  | yesterday   | 400    | error 'PAST_DATE'                             |
      | <own>        | 1.00   | CUSTOM           | BANK-OK  | null        | 200    | 'payment_id' and 'new_balance_estimate'       |
      | <own>        | <stmt> | STATEMENT_BALANCE| BANK-OK  | tomorrow    | 200    | 'payment_id' and 'scheduled_date'             |
      | <other>      | 1.00   | CUSTOM           | BANK-OK  | null        | 403    | error 'FORBIDDEN'                              |
      | <own>        | <total>| FULL_BALANCE     | BANK-OK  | null        | 200    | 'payment_id' and 'new_balance_estimate' near zero |

  @api @accounts
  Scenario: Account summary include_rewards toggle, owner-only access enforcement, not-found and unauthorized handling
    Given I am logged in as 'user+summary@domain.com' with valid MFA
    When I GET '/v2/accounts/ACC-OWN/summary'
    Then the response status should be 200
      And 'points_balance' is absent by default
    When I GET '/v2/accounts/ACC-OWN/summary?include_rewards=true'
    Then the response status should be 200
      And 'points_balance' is present and numeric
      And no PAN is exposed in the response
    When I GET '/v2/accounts/ACC-OTHER/summary'
    Then the response status should be 403
    When I GET '/v2/accounts/ACC-NONE/summary'
    Then the response status should be 404
    When I retry GET '/v2/accounts/ACC-OWN/summary' without Authorization header
    Then the response status should be 401

  @api @statements @interest
  Scenario: Foreign purchase, fee and rewards, statements JSON/PDF, payment CSRF negative/positive, late fee webhook idempotency, session timeout and right to rescind
    Given I am logged in via POST '/v2/auth/login' with valid MFA and secure cookies
    When I POST '/v2/accounts/<account_id>/transactions' with JSON payload
      """
      {
        "transaction_amount": 100.00,
        "currency_code": "USD",
        "exchange_rate": 1.350000,
        "mcc_code": 7011,
        "merchant_name": "Hotel ABC",
        "transaction_type": "PURCHASE"
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'foreign_fee_amount' 4.05 and 'total_cad' 139.05
    When I GET '/v2/accounts/<account_id>/statements/<statement_id>?format=JSON'
    Then the response status should be 200
      And 'content-type' should be 'application/json'
      And 'total_spend' equals the sum of transactions within ±0.01
    When I GET '/v2/accounts/<account_id>/statements/<statement_id>?format=PDF'
    Then the response status should be 200
      And 'content-type' should be 'application/pdf'
    When I POST '/v2/accounts/<account_id>/payments' without 'X-CSRF-Token'
      """
      { "payment_type": "MINIMUM", "payment_amount": "minimum_payment_due", "bank_account_id": "BANK-OK" }
      """
    Then the response status should be 403
    When I POST '/v2/accounts/<account_id>/payments' with 'X-CSRF-Token'
      """
      { "payment_type": "MINIMUM", "payment_amount": "minimum_payment_due", "bank_account_id": "BANK-OK" }
      """
    Then the response status should be 200
      And the response should contain 'payment_id' and 'scheduled_date'
    When the system advances past due_date + 2 days and I GET the next statement
    Then the response should contain 'late_fee' 35.00 and 'interest_charged' per REQ-009 if previous balance not paid in full
    When I POST '/v2/notifications/webhook' with JSON payload
      """
      {
        "account_id": "<account_id>",
        "alert_type": "LATE_PAYMENT",
        "channel": "EMAIL",
        "severity": "WARNING",
        "idempotency_key": "00000000-0000-0000-0000-000000000001"
      }
      """
    Then the response status should be 200
    When I POST the same '/v2/notifications/webhook' with the same idempotency_key
    Then the response status should be 409
    When I remain idle for 13 minutes
    Then I should receive a session timeout warning at 13 minutes
    When I wait until 15 minutes and POST '/v2/accounts/<account_id>/payments' again
    Then the response status should be 401 due to session expiry
    When I re-login and retry the payment with CSRF
    Then the response status should be 200
    When I DELETE '/v2/accounts/<account_id>' with CSRF within 14-day window
    Then the response status should be 200
    When I simulate day 15 and DELETE '/v2/accounts/<account_id>' again
    Then the response status should be 403

  @api @statements @interest
  Scenario: ADB interest calculation and grace period across consecutive cycles
    Given I am logged in and the account 'ACC-ADB' has APR 19.99% and prior statement paid in full
    When I POST a CAD purchase of 300.00 on Cycle A Day 1 and a CAD purchase of 200.00 on Day 10 with CSRF
    And I advance to end of Cycle A and GET '/v2/accounts/ACC-ADB/statements/<stmtA>?format=JSON'
    Then the response should have 'interest_charged' 0.00 and 'total_spend' sum within ±0.01
    When I POST a payment of 200.00 during Cycle B with CSRF
    And I simulate daily balances: Days 1–14 previous_cycle_unpaid; Day 15 add 100.00 purchase; Day 20 subtract 50.00 payment
    And at Cycle B end I GET '/v2/accounts/ACC-ADB/statements/<stmtB>?format=JSON'
    Then I compute ADB = sum of daily balances / 30 and expected_interest = (ADB × 0.1999 / 365) × 30
      And 'interest_charged' equals expected_interest within 0.01 tolerance
      And 'late_fee' equals 0.00

  @api @rewards
  Scenario: Rewards accrual 1x with floor for non-travel and 3x for travel MCC in CAD
    Given I am logged in as 'user+rewards@domain.com' with valid MFA and CSRF token
    And I GET '/v2/accounts/<account_id>/summary?include_rewards=true' and record baseline 'points_balance' P0
    When I POST three CAD purchases: 0.99 (5411), 1.01 (5411), 2.99 (5812) with CSRF
    And I GET '/v2/accounts/<account_id>/summary?include_rewards=true'
    Then 'points_balance' equals P0 + floor(0.99*1) + floor(1.01*1) + floor(2.99*1) = P0 + 0 + 1 + 2
    When I POST a CAD travel purchase 10.00 (7011)
    And I GET '/v2/accounts/<account_id>/summary?include_rewards=true'
    Then 'points_balance' increased by an additional floor(10.00*3) = 30
    When I POST a micro CAD grocery purchase 0.49 (5411)
    And I GET '/v2/accounts/<account_id>/summary?include_rewards=true'
    Then 'points_balance' remains unchanged due to floor(0.49*1)=0

  @api @pin @security
  Scenario: Set PIN with OTP success, mismatch/format errors, OTP invalid, and allowed while Frozen
    Given I have a valid CSRF token and OTP for PIN action
    When I PUT '/v2/cards/<card_id>/pin' with JSON payload
      """
      { "new_pin": "2580", "confirm_pin": "2580", "session_otp": "123456" }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'success' true
    When I PUT '/v2/cards/<card_id>/pin' with mismatched confirm_pin using fresh valid OTP
      """
      { "new_pin": "2580", "confirm_pin": "2581", "session_otp": "123456" }
      """
    Then the response status should be 400
      And the response should contain error 'PIN_MISMATCH'
    When I PUT '/v2/cards/<card_id>/pin' with invalid format '12a4'
    Then the response status should be 400
      And the response should contain error 'PIN_FORMAT'
    When I PUT '/v2/cards/<card_id>/pin' with expired/invalid OTP and valid matching 4-digit PIN
    Then the response status should be 401
      And the response should contain error 'OTP_FAILED'
    When I PATCH '/v2/cards/<card_id>/status' to Frozen with valid OTP and CSRF
    Then the response status should be 200
    When I PUT '/v2/cards/<card_id>/pin' while status Frozen with valid OTP
    Then the response status should be 200
      And the response should contain 'success' true

  @api @otp @cards
  Scenario: Freeze/Unfreeze OTP attempt limits, resend OTP resets attempts, and successful transitions
    Given I am logged in as 'user+otp@domain.com' with valid MFA and CSRF token and card status Active
    When I PATCH '/v2/cards/CARD-OTP/status' to Frozen with invalid OTP '111111'
    Then the response status should be 401
      And the response should contain error 'OTP_FAILED' and 'attempts_remaining' 2
    When I PATCH '/v2/cards/CARD-OTP/status' to Frozen with invalid OTP '222222'
    Then the response status should be 401
      And the response should contain 'attempts_remaining' 1
    When I PATCH '/v2/cards/CARD-OTP/status' to Frozen with invalid OTP '333333'
    Then the response status should be 401
      And the response should contain 'attempts_remaining' 0
    When I PATCH '/v2/cards/CARD-OTP/status' to Frozen again without new OTP
    Then the response status should be 401
      And the response should contain 'attempts_remaining' 0
    When I POST '/v2/auth/otp/request' with JSON payload
      """
      { "purpose": "card_status", "channel": "SMS" }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'otp_sent' true
    When I PATCH '/v2/cards/CARD-OTP/status' to Frozen with the new valid OTP
    Then the response status should be 200
      And the response should contain 'new_status' 'Frozen'
    When I request a new OTP and PATCH '/v2/cards/CARD-OTP/status' to Active
    Then the response status should be 200
      And the response should contain 'new_status' 'Active'

  @api @idor @cards
  Scenario: Owner-only card controls and report-lost: IDOR prevention and invalid status value handling
    Given two users exist and I am logged in as 'user+idor1@domain.com' with CSRF token
    And I have card_id 'C-OWN' and another user's card_id 'C-OTHER'
    When I PATCH '/v2/cards/C-OTHER/status' to Frozen with OTP and CSRF
    Then the response status should be 403
    When I POST '/v2/cards/C-OTHER/report-lost' with 'LOST' and CSRF
    Then the response status should be 403
    When I PATCH '/v2/cards/C-OWN/status' with status 'Blocked' (invalid) and valid OTP
    Then the response status should be 400
      And the response should contain error 'INVALID_TRANSITION' with allowed 'Active'/'Frozen'
    When I PATCH '/v2/cards/C-OWN/status' to Frozen with invalid OTP
    Then the response status should be 401
      And the response should contain 'attempts_remaining'
    When I request a new OTP and PATCH '/v2/cards/C-OWN/status' to Frozen then to Active with valid OTPs
    Then both responses should be 200 with 'new_status' updated accordingly

  @api @websocket @transactions
  Scenario: WebSocket live transaction feed authentication, event delivery, unauthorized connection, and reconnect
    Given I am logged in as 'user+realtime@domain.com' with valid access token and CSRF token
    When I open a WebSocket to 'wss://realtime.aegiscard.com/v2/stream' with 'Authorization: Bearer <access_token>'
    Then the WebSocket handshake status should be 101 and I send subscription 'SUBSCRIBE <account_id>' and receive an ack
    When I POST '/v2/accounts/<account_id>/transactions' with CAD 20.00 (mcc_code 5411) and CSRF
    Then I should receive a WS event with 'event_type' 'TRANSACTION_POSTED' and fields 'transaction_id','amount','mcc_code','currency'
    When I POST '/v2/accounts/<account_id>/transactions' with USD 10.00 (mcc_code 7011) exchange_rate 1.250000 and CSRF
    Then I should receive a WS event including 'foreign_fee_amount' and 'total_cad' per REQ-006
    When I POST a USD transaction omitting 'exchange_rate'
    Then the response status should be 400 and no WS event should be emitted
    When I close the WebSocket connection
    Then no further events are received
    When I attempt to open WebSocket without Authorization header
    Then the connection is refused or closed with 401 equivalent
    When I reconnect WebSocket with valid Authorization and resubscribe
    And I POST a small CAD transaction
    Then I should receive a WS event for that transaction

  @api @registration @validation
  Scenario Outline: Registration field validations and duplicate email handling with secure cookie attributes
    Given I have obtained a valid CSRF token from the portal session
    When I send a POST request to '/v2/auth/register' with JSON payload
      """
      {
        "first_name": "<first_name>",
        "last_name": "Tester",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "<dob>",
        "phone_number": "<phone>",
        "ssn_last4": "<ssn4>",
        "agree_terms": <terms>
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be <status>
      And the response should contain <expectation>

    Examples:
      | first_name  | email                         | password           | dob         | phone         | ssn4 | terms | status | expectation                                                                |
      | Jo          | user..dots@domain.com         | ValidPass123!      | 1990-01-01  | +14165551234  | 1234 | true  | 400    | field 'email' invalid per RFC 5322                                         |
      | Jo          | user+edge@sub.domain.co.uk    | ValidPass123!      | 1990-01-01  | 14165551234   | 1234 | true  | 400    | field 'phone_number' E.164 violation                                       |
      | Jo          | user+edge@domain.co.uk        | ValidPass123!      | 1990-01-01  | +14165551234  | 123  | true  | 400    | field 'ssn_last4' exactly 4 digits required                                 |
      | Jo          | user+edge@domain.co.uk        | ValidPass123!      | 1990-01-01  | +14165551234  | 12a4 | true  | 400    | field 'ssn_last4' numeric-only                                              |
      | Jo          | user+edge@domain.co.uk        | ValidPass123!      | 1990-01-01  | +14165551234  | 1234 | false | 400    | field 'agree_terms' must be true                                            |
      | Jo          | user+edge@domain.co.uk        | ValidPass123!      | 1990-01-01  | +14165551234  | 1234 | true  | 201    | 'user_id' and 'verification_token' present; Set-Cookie HttpOnly Secure Strict |
      | Anne-Marie  | user+edge@domain.co.uk        | ValidPass123!      | 1990-01-01  | +14165551234  | 1234 | true  | 400    | field 'first_name' alpha-only rejects hyphens (if enforced)                 |

  @api @registration @passwords
  Scenario Outline: Registration password complexity and leap-year age validation
    Given I have a valid CSRF token and the sandbox date can be controlled
    When I send a POST request to '/v2/auth/register' with JSON payload
      """
      {
        "first_name": "John",
        "last_name": "Doe",
        "email": "user+leap@domain.com",
        "password": "<password>",
        "date_of_birth": "<dob>",
        "phone_number": "+14165551234",
        "ssn_last4": "1234",
        "agree_terms": true
      }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be <status>
      And the response should contain <expectation>

    Examples:
      | password         | dob         | status | expectation                                 |
      | Short11!         | 2008-03-01  | 422    | error 'WEAK_PASSWORD'                       |
      | alllowercase11!  | 1990-01-01  | 422    | error 'WEAK_PASSWORD' missing uppercase     |
      | NOLOWERCASE11!   | 1990-01-01  | 422    | error 'WEAK_PASSWORD' missing lowercase     |
      | NoDigits!!!!     | 1990-01-01  | 422    | error 'WEAK_PASSWORD' missing digit         |
      | NoSymbol1234     | 1990-01-01  | 422    | error 'WEAK_PASSWORD' missing symbol        |
      | OkPassw0rd!!     | <17y364d>   | 400    | field 'date_of_birth' age < 18              |
      | OkPassw0rd!!     | 2008-02-29  | 400    | age < 18 on non-leap-year Feb 28            |
      | OkPassw0rd!!     | 2008-02-29  | 201    | 'user_id' and 'verification_token' present after Mar 1 |

  @api @verify @auth
  Scenario: Email verification invalid/tampered, expired, resend rate-limit, and successful activation
    Given I have registered 'user+verify@domain.com' and captured 'verification_token'
    When I POST '/v2/auth/login' with correct credentials before verification
    Then the response status should be 403
      And the response should contain error 'EMAIL_NOT_VERIFIED'
    When I GET '/v2/auth/verify?token=<tampered_token>'
    Then the response status should be 400
      And the response should contain error 'INVALID_TOKEN'
    When I GET '/v2/auth/verify?token=<expired_token>'
    Then the response status should be 400
      And the response should contain error 'TOKEN_EXPIRED'
    When I POST '/v2/auth/verify/resend' with JSON payload
      """
      { "email": "user+verify@domain.com" }
      """
      And I include header 'X-CSRF-Token' with a valid CSRF token
    Then the response status should be 200
      And the response should contain 'resend_ack' true
    When I POST '/v2/auth/verify/resend' again immediately
    Then the response status should be 429
      And the response should contain 'retry_after'
    When I GET '/v2/auth/verify?token=<new_verification_token>'
    Then the response status should be 200
      And the response should indicate 'verified' true
    When I POST '/v2/auth/login' with correct credentials and valid MFA
    Then the response status should be 200
      And the response should contain 'access_token', 'refresh_token', 'expires_in'
      And Set-Cookie headers must include HttpOnly, Secure, SameSite=Strict

  @api @audit @admin
  Scenario: Credit limit change audit trail immutability and visibility, and role-based access
    Given I am logged in as Cardholder and record 'credit_limit' L1 from GET '/v2/accounts/<account_id>/summary'
    When an Admin posts to '/v2/admin/accounts/<account_id>/credit-limit' with JSON payload
      """
      { "new_limit": <L2> }
      """
      And the request includes 'X-CSRF-Token'
    Then the response status should be 200
    When the Cardholder GETs '/v2/accounts/<account_id>/summary'
    Then 'credit_limit' equals <L2> and 'available_credit' adjusted accordingly
    When I GET '/v2/admin/audit?account_id=<account_id>' as Admin
    Then the response status should be 200
      And an audit record exists with 'user_id'(admin), 'session_id', 'ip_address', 'field' 'credit_limit', 'old_value' L1, 'new_value' L2
    When I attempt to DELETE '/v2/admin/audit/<audit_id>' as Admin
    Then the response status should be 405 or 403 indicating immutability
    When Admin posts a second change to <L3> and I GET audit records
    Then a second immutable record exists with 'old_value' L2 and 'new_value' L3
    When the Cardholder attempts to POST '/v2/admin/accounts/<account_id>/credit-limit'
    Then the response status should be 403

  @api @webhook @notifications
  Scenario Outline: Notifications webhook validation, multi-channel delivery, and idempotency per-account scope
    Given the Notification Engine is authorized for '/v2/notifications/webhook'
    When I send a POST request to '/v2/notifications/webhook' with JSON payload
      """
      {
        "account_id": "<account_id>",
        "alert_type": "<alert_type>",
        "channel": "<channel>",
        "severity": "<severity>",
        "message_body": "<message_body>",
        "idempotency_key": "<key>"
      }
      """
    Then the response status should be <status>
      And the response should contain <expectation>

    Examples:
      | account_id | alert_type    | channel | severity  | message_body                        | key     | status | expectation                             |
      | A-ONE      | PIN_LOCKED    | SMS     | CRITICAL  | Your PIN has been locked.           | K-0001  | 200    | 'notification_id' and 'delivered_at'    |
      | A-ONE      | PIN_LOCKED    | SMS     | CRITICAL  | Your PIN has been locked.           | K-0001  | 409    | error 'DUPLICATE_NOTIFICATION'          |
      | A-TWO      | PIN_LOCKED    | SMS     | CRITICAL  | Your PIN has been locked.           | K-0001  | 200    | 'notification_id' and 'delivered_at'    |
      | A-ONE      | FRAUD_FLAG    | EMAIL   | WARNING   | Transaction flagged.                | K-0002  | 200    | 'channel' equals 'EMAIL'                |
      | A-ONE      | OVER_LIMIT    | IN_APP  | INFO      | You are over limit.                 | K-0003  | 200    | 'channel' equals 'IN_APP'               |
      | A-ONE      | UNKNOWN_TYPE  | SMS     | INFO      | Invalid type                        | K-0004  | 400    | error 'INVALID_ALERT_TYPE'              |
      | A-ONE      | STATEMENT_READY| FAX    | INFO      | Unsupported channel                 | K-0005  | 400    | channel validation error                |
      | A-ONE      | PIN_LOCKED    | SMS     | INFO      | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA | K-0006  | 400    | field 'message_body' length validation  |

  @api @right_to_rescind
  Scenario: Right to rescind deletion leads to 404 on subsequent endpoints and idempotent DELETE
    Given I am logged in as 'user+rescind@domain.com' with valid MFA and CSRF token and account 'ACC-RESC' is within 14-day window
    When I DELETE '/v2/accounts/ACC-RESC' with 'X-CSRF-Token'
    Then the response status should be 200
    When I GET '/v2/accounts/ACC-RESC/summary'
    Then the response status should be 404
    When I GET '/v2/accounts/ACC-RESC/transactions'
    Then the response status should be 404
    When I POST '/v2/accounts/ACC-RESC/transactions' with any valid payload
    Then the response status should be 404
    When I POST '/v2/accounts/ACC-RESC/payments' with valid payload
    Then the response status should be 404
    When I GET '/v2/accounts/ACC-RESC/statements/<statement_id>'
    Then the response status should be 404
    When I DELETE '/v2/accounts/ACC-RESC' again
    Then the response status should be 404

  # UI Tests

  @ui @dashboard @masking
  Scenario: Dashboard displays masked PAN and no PII leakage
    Given I am on the Dashboard page as a logged-in cardholder
    When the account summary loads
    Then I should see the card number masked as '**** **** **** 1234'
      And I should not see any raw PAN in the DOM
      And I should not find any tokens in localStorage or sessionStorage

  @ui @application @draft
  Scenario: Application Step 1 draft auto-save every 60 seconds, restore, sanitize, and cleanup after submission
    Given I am on the Credit Application Step 1 page and authenticated with secure cookies
    When I fill the form with non-sensitive fields (name, phone, address, id_type and masked id_number) and wait 60 seconds
    Then localStorage should contain a key 'aegis_app_step1_draft' with recent timestamp
      And the stored JSON should exclude or mask sensitive fields (id_number, ssn_last4) and contain no tokens
    When I refresh the page
    Then the form should auto-populate from the draft and prompt re-entry for any masked values
    When I update the city and phone and wait another 60 seconds
    Then the draft should reflect the updated values with an advanced timestamp
    When I close and reopen the tab to Step 1
    Then the draft should restore across navigation and the auto-save cadence remains ~60s (±5s)
    When I intentionally corrupt the draft JSON in localStorage and refresh
    Then the UI should handle the error gracefully, clear the bad draft, and show an empty form with a non-blocking notice
    When I submit Step 1 successfully from the UI
    Then the draft key should be removed from localStorage and no further auto-save writes should occur for Step 1

  @ui @session
  Scenario: Session timeout warning at 13 minutes and expiry at 15 minutes
    Given I am logged in on the Dashboard page and idle
    When I remain idle for 13 minutes
    Then I should see a session timeout warning modal
    When I remain idle until 15 minutes
    Then my session should expire and protected actions should prompt re-authentication
