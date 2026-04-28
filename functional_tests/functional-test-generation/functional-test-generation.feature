Feature: Aegis Card Platform - End-to-End, Security, Transactions, Payments, Notifications, WebSocket, and Compliance

  Background:
    Given the API base URL is 'https://api.aegiscard.com/v2'
    And the Portal URL is 'https://portal.aegiscard.com'
    And the WebSocket URL is 'wss://realtime.aegiscard.com/v2/stream'
    And the Content-Type header is 'application/json'
    And cookies are expected to be HttpOnly, Secure with SameSite=Strict
    And all times are considered in UTC

  # End-to-End Happy Path and Major Workflows
  @api @ui @e2e @AEGIS-E2E-001
  Scenario: Approved end-to-end: Registration to rescind with card controls, FX transaction, payments, notifications, and rescind window
    Given I am on the registration page at 'https://portal.aegiscard.com/register' and a CSRF token is loaded
    When I send a POST request to '/auth/register' with JSON payload
      """
      {
        "first_name":"Alice",
        "last_name":"Reid",
        "email":"alice.qa+20260428@example.com",
        "password":"S0mething-Str0ng!V3ry",
        "date_of_birth":"1998-04-28",
        "phone_number":"+14165550123",
        "ssn_last4":"1234",
        "agree_terms":true
      }
      """
    Then the response status should be 201
    And I should see 'Verification email sent' in the UI
    And no PAN appears in the DOM or network responses

    Given email verification is simulated complete via internal harness
    When I send a POST request to '/auth/login' with JSON payload
      """
      {
        "email":"alice.qa+20260428@example.com",
        "password":"S0mething-Str0ng!V3ry",
        "mfa_code":"123456",
        "device_id":"11111111-1111-4111-8111-111111111111",
        "remember_me":true
      }
      """
    Then the response status should be 200
    And JWT cookies should be set as HttpOnly, Secure with SameSite=Strict
    And no tokens should be present in localStorage or sessionStorage

    When I send a POST request to '/auth/token/refresh' with current refresh_token cookie
    Then the response status should be 200
    And a new refresh_token should be issued and rotated
    When I immediately retry POST '/auth/token/refresh' using the old refresh_token
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'

    When I send a POST request to '/applications/start' with JSON payload and X-CSRF-Token
      """
      {
        "full_legal_name":"Alice Marie Reid",
        "email":"alice.qa+20260428@example.com",
        "phone_number":"+14165550123",
        "residential_address":{
          "street":"100 King St W",
          "city":"Toronto",
          "province":"ON",
          "postal_code":"M5H 1J9"
        },
        "id_type":"DRIVERS_LICENSE",
        "id_number":"R3ID12345"
      }
      """
    Then the response status should be 201
    And the response JSON should contain 'application_id' and 'session_token'
    And the UI should show 'Resume later' link and auto-save drafts every 60s

    When I send a POST request to '/applications/{application_id}/financials' with headers X-App-Session and X-CSRF-Token and JSON payload
      """
      {
        "employment_status":"EMPLOYED",
        "employer_name":"Aegis QA Labs",
        "gross_annual_income":95000.00,
        "monthly_rent":1800.00,
        "existing_debt_payments":250.00,
        "sin_consent":true
      }
      """
    Then the response status should be 200
    And the response JSON field 'status' should equal 'PENDING_REVIEW'
    And the response should contain 'fico_pull_id'

    When I send a POST request to '/applications/{application_id}/submit' with X-CSRF-Token and JSON payload
      """
      {
        "card_product_id":"AEGIS_GOLD",
        "e_signature":"QWxpY2UgTSBSZWlk"
      }
      """
    Then the response status should be 200
    And the decision should be 'APPROVED'
    And the response should include 'credit_limit' and 'card_number_masked' matching '**** **** **** 1234'
    And no full PAN should appear in DOM or API responses
    And an audit log entry should exist for credit_limit change with user_id, session_id, ip_address, timestamp_utc

    When I send a PATCH request to '/cards/{card_id}/status' with X-CSRF-Token and JSON payload
      """
      { "status":"Frozen","reason":"Traveling","confirm_otp":"123456" }
      """
    Then the response status should be 200
    And the response JSON field 'new_status' should equal 'Frozen'
    When I send a PATCH request to '/cards/{card_id}/status' with X-CSRF-Token and JSON payload
      """
      { "status":"Active","reason":"Back from travel","confirm_otp":"123456" }
      """
    Then the response status should be 200
    And an audit log should include freeze/unfreeze entries

    When I send a PUT request to '/cards/{card_id}/pin' with X-CSRF-Token and JSON payload
      """
      { "new_pin":"2580","confirm_pin":"2580","session_otp":"123456" }
      """
    Then the response status should be 200
    And the response should include 'updated_at'
    And the PIN should not be echoed in UI or logs

    When I send a POST request to '/accounts/{account_id}/transactions' with X-CSRF-Token and JSON payload
      """
      {
        "transaction_amount":150.00,
        "merchant_name":"Maple Books",
        "merchant_id":"MB123",
        "mcc_code":"5942",
        "transaction_type":"PURCHASE",
        "description":"Books"
      }
      """
    Then the response status should be 200
    And the response should include 'transaction_id' and 'auth_code'

    When I send a POST request to '/accounts/{account_id}/transactions' with X-CSRF-Token and JSON payload
      """
      {
        "transaction_amount":100.00,
        "merchant_name":"Hotel Euro",
        "merchant_id":"HTL4722",
        "mcc_code":"4722",
        "currency_code":"USD",
        "exchange_rate":1.250000,
        "transaction_type":"PURCHASE",
        "description":"Hotel"
      }
      """
    Then the response status should be 200
    And the response should include 'foreign_fee_amount' equal to 3.75 and 'total_cad' equal to 128.75

    When I perform 10 approved micro-transactions of $1.00 within 60 minutes
    And I attempt an 11th transaction of $1.00
    Then the response status should be 429
    And the error code should be 'FREQ_EXCEEDED'
    And the response should indicate 'mfa_required' is true
    When I retry the 11th transaction with step-up MFA satisfied
    Then the response status should be 200

    When I send a GET request to '/accounts/{account_id}/transactions?from_date={cycle_start}&to_date={cycle_end}&page=1&per_page=25&category=PURCHASE'
    Then the response status should be 200
    And only 'PURCHASE' category transactions should be returned
    When I send a GET request to '/accounts/{account_id}/transactions?from_date={cycle_start}&to_date={cycle_end}&page=999&per_page=25&category=PURCHASE'
    Then the response status should be 200
    And an empty list should be returned with valid pagination metadata

    When I send a GET request to '/accounts/{account_id}/summary?include_rewards=true'
    Then the response status should be 200
    And the response should include 'current_balance','available_credit','credit_limit','account_status','billing_cycle_end','points_balance'
    And rewards for MCC 4722 should use floor(amount×3) on CAD-converted amount

    When I send a POST request to '/accounts/{account_id}/payments' with X-CSRF-Token and JSON payload
      """
      { "payment_amount":200.00,"payment_type":"CUSTOM","bank_account_id":"BANK123" }
      """
    Then the response status should be 200
    And the response should include 'new_balance_estimate'

    When I send a POST request to '/accounts/{account_id}/payments' with X-CSRF-Token and JSON payload
      """
      { "payment_amount":100.00,"payment_type":"CUSTOM","bank_account_id":"BANK123","scheduled_date":"{+10d}" }
      """
    Then the response status should be 200
    And the response should echo the scheduled_date

    When I send a POST request to '/notifications/webhook' with service authorization and JSON payload
      """
      {
        "account_id":"{account_id}",
        "alert_type":"STATEMENT_READY",
        "channel":"IN_APP",
        "severity":"INFO",
        "message_body":"Your statement is ready",
        "idempotency_key":"11111111-2222-4333-8444-555555555555"
      }
      """
    Then the response status should be 200
    When I resend the same webhook payload with the same idempotency_key
    Then the response status should be 409
    And the error code should be 'DUPLICATE_NOTIFICATION'
    And a single in-app toast should appear

    When I send a DELETE request to '/accounts/{account_id}' with X-CSRF-Token
    Then the response status should be 200 or 204
    And subsequent UI and API should reflect account_status 'Closed'
    And card access should be disabled
    And an immutable audit trail should record the rescind action
    And no full PAN appears in any response or UI element

  @api @ui @AEGIS-E2E-002
  Scenario: Application session expiration with save/resume and Step 3 signature validation
    Given I have registered and logged in as 'Bob' with MFA and have a CSRF token
    When I send a POST request to '/applications/start' with valid Step 1 JSON and receive application_id and session_token
    Then a draft should be present in localStorage and UI should show 'Resume later'
    When I wait more than 30 minutes to expire X-App-Session
    And I send a POST request to '/applications/{application_id}/financials' with expired X-App-Session
    Then the response status should be 401
    And the error code should be 'SESSION_EXPIRED'
    When I use the UI to 'Resume Application' and restart Step 1
    Then a new application_id and session_token should be issued with 201
    When I send a POST request to '/applications/{application_id}/financials' with valid data and X-App-Session
    Then the response status should be 200
    And the response should indicate 'PENDING_REVIEW'
    When I send a POST request to '/applications/{application_id}/submit' without e_signature
    Then the response status should be 400
    And the error code should be 'SIGNATURE_REQUIRED'
    When I resubmit Step 3 with a valid e_signature
    Then for Bob (FICO 681) the decision should be 'APPROVED' with masked PAN only

  @api @AEGIS-E2E-002
  Scenario Outline: Application decision boundaries for FICO thresholds
    Given an authenticated user '<user_email>' with configured FICO '<fico>'
    And a new application_id and session_token are obtained via POST '/applications/start'
    When I send POST '/applications/{application_id}/financials' with valid data and X-App-Session
    Then the response status should be 200 and status 'PENDING_REVIEW'
    When I send POST '/applications/{application_id}/submit' with valid e_signature
    Then the response status should be 200
    And the decision should be '<expected_decision>'
    And masked PAN should be present only for APPROVED
    And audit trail for credit_limit should exist only if decision is APPROVED

    Examples:
      | user_email                        | fico | expected_decision |
      | bob.qa+20260428@example.com       | 681  | APPROVED          |
      | cara.qa+20260428@example.com      | 680  | PENDING           |
      | dan.qa+20260428@example.com       | 600  | PENDING           |
      | eve.qa+20260428@example.com       | 599  | DECLINED          |

  # Registration Validation
  @api @AEGIS-AUTH-REG-007
  Scenario Outline: Registration invalid field validations and weak password handling
    Given I am on the registration page and have a CSRF token
    When I send a POST request to '/auth/register' with JSON payload
      """
      {
        "first_name":"<first_name>",
        "last_name":"Rivera",
        "email":"<email>",
        "password":"<password>",
        "date_of_birth":"<dob>",
        "phone_number":"<phone>",
        "ssn_last4":"<ssn_last4>",
        "agree_terms":<agree_terms>
      }
      """
    Then the response status should be <status>
    And the error code should be '<error_code>'
    And no PAN or unmasked SSN should be present in the response

    Examples:
      | first_name | email                          | password              | dob         | phone          | ssn_last4 | agree_terms | status | error_code        |
      | Alex       | user@@example..com             | S0mething-Str0ng!V3ry | 2008-04-29  | +14165551234   | 1234     | true        | 400    | INVALID_EMAIL     |
      | Alex       | new.qa+20260428@example.com    | Short1!               | 1990-04-28  | +14165551234   | 1234     | true        | 422    | WEAK_PASSWORD     |
      | Alex       | new.qa+20260428@example.com    | S0mething-Str0ng!V3ry | 2009-04-29  | +14165551234   | 1234     | true        | 400    | DOB_UNDER_18      |
      | Alex       | new.qa+20260428@example.com    | S0mething-Str0ng!V3ry | 1990-04-28  | 4165551234     | 1234     | true        | 400    | INVALID_PHONE     |
      | Alex       | new.qa+20260428@example.com    | S0mething-Str0ng!V3ry | 1990-04-28  | +14165551234   | 12A4     | true        | 400    | INVALID_SSN_LAST4 |
      | Alex       | new.qa+20260428@example.com    | S0mething-Str0ng!V3ry | 1990-04-28  | +14165551234   | 123      | true        | 400    | INVALID_SSN_LAST4 |
      | Alex       | new.qa+20260428@example.com    | S0mething-Str0ng!V3ry | 1990-04-28  | +14165551234   | 1234     | false       | 400    | TERMS_REQUIRED    |

  @api @AEGIS-AUTH-REG-007
  Scenario: Registration valid then duplicate email rejection
    Given I am on the registration page and have a CSRF token
    When I send a POST request to '/auth/register' with JSON payload
      """
      {
        "first_name":"Alex",
        "last_name":"Rivera",
        "email":"new.qa+20260428@example.com",
        "password":"V3ry-Str0ng!Pass",
        "date_of_birth":"2008-04-28",
        "phone_number":"+14165551234",
        "ssn_last4":"1234",
        "agree_terms":true
      }
      """
    Then the response status should be 201
    And the response should include 'user_id'
    When I resend the same POST to '/auth/register' with the same email
    Then the response status should be 409
    And the error code should be 'EMAIL_EXISTS'

  # Transactions Validation and Business Rules
  @api @AEGIS-TXN-VAL-010 @AEGIS-TXN-003
  Scenario Outline: Transactions validation errors and CSRF enforcement
    Given I am authenticated with JWT cookies and have X-CSRF-Token '<csrf_header>'
    When I send a POST request to '/accounts/{account_id}/transactions' with JSON payload
      """
      {
        "transaction_amount":<amount>,
        "merchant_name":"<merchant_name>",
        "merchant_id":"<merchant_id>",
        "mcc_code":"<mcc>",
        "currency_code":"<currency>",
        "exchange_rate":<exchange_rate>,
        "transaction_type":"<type>",
        "description":"<description>"
      }
      """
    Then the response status should be <status>
    And the error code should be '<error_code>'

    Examples:
      | csrf_header | amount  | merchant_name | merchant_id                          | mcc  | currency | exchange_rate | type     | description     | status | error_code          |
      | MISSING     | 10.00   | Test          | TST1                                 | 5942 | CAD      | null          | PURCHASE | CSRF missing    | 403    | CSRF_MISSING        |
      | PRESENT     | 1051.00 | OverNonEss    | BOOKS1                               | 5942 | CAD      | null          | PURCHASE | Over non-ess    | 402    | INSUFFICIENT_FUNDS  |
      | PRESENT     | 0.00    | ZeroAmt       | ZERO                                 | 5942 | CAD      | null          | PURCHASE | Zero amount     | 422    | INVALID_AMOUNT      |
      | PRESENT     | -10.00  | NegAmt        | NEG                                  | 5942 | CAD      | null          | PURCHASE | Negative amount | 422    | INVALID_AMOUNT      |
      | PRESENT     | 100.00  | FXMissing     | FXM1                                 | 4722 | USD      | null          | PURCHASE | FX missing      | 400    | EXCHANGE_RATE_REQD  |
      | PRESENT     | 10.00   | BadMCC        | BADMCC                               | 123  | CAD      | null          | PURCHASE | Bad MCC         | 400    | INVALID_MCC         |
      | PRESENT     | 10.00   | LongMerchant  | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA A | 5942 | CAD      | null          | PURCHASE | Long merchant   | 400    | INVALID_MERCHANT_ID |

  @api @AEGIS-TXN-VAL-010
  Scenario Outline: Essential buffer boundary and FX fee precision
    Given I am authenticated with JWT cookies and have a valid X-CSRF-Token
    When I send a POST request to '/accounts/{account_id}/transactions' with JSON payload
      """
      {
        "transaction_amount":<amount>,
        "merchant_name":"<merchant_name>",
        "merchant_id":"<merchant_id>",
        "mcc_code":"<mcc>",
        "currency_code":"<currency>",
        "exchange_rate":<exchange_rate>,
        "transaction_type":"PURCHASE",
        "description":"<description>"
      }
      """
    Then the response status should be <status>
    And the field '<flag_field>' should equal '<flag_value>'
    And if '<currency>' is 'USD' then 'foreign_fee_amount' should equal <fee> and 'total_cad' should equal <total_cad>

    Examples:
      | amount   | merchant_name | merchant_id | mcc  | currency | exchange_rate | description       | status | flag_field       | flag_value | fee  | total_cad |
      | 1050.00  | GroceryMax    | GROC5411    | 5411 | CAD      | null          | Essential boundary| 200    | over_limit_flag  | true       | null | null      |
      | 1050.01  | GroceryOver   | GROC5411    | 5411 | CAD      | null          | Above boundary    | 402    | error_code       | INSUFFICIENT_FUNDS | null | null      |
      | 100.00   | USDHotel      | HTL4722     | 4722 | USD      | 1.250000      | FX fee compute    | 200    | over_limit_flag  | false      | 3.75 | 128.75    |

  @api @AEGIS-TXN-003
  Scenario: Transaction frequency rate limiting with step-up MFA retry
    Given I am authenticated with JWT cookies and have a valid X-CSRF-Token
    When I submit 10 approved transactions of $1.00 within 60 minutes
    And I submit an 11th $1.00 transaction
    Then the response status should be 429
    And the error code should be 'FREQ_EXCEEDED'
    And 'mfa_required' should be true
    When I retry the 11th transaction with step-up MFA satisfied
    Then the response status should be 200

  # Owner-only Enforcement Across Endpoints
  @api @AEGIS-AUTHZ-006
  Scenario Outline: Cross-account/card owner-only enforcement returns 403 with no leakage
    Given User B is authenticated and owns different resources
    When User B sends a <method> request to '<endpoint>'
    Then the response status should be 403
    And the error code should be 'FORBIDDEN'
    And the response body should not leak resource fields or PAN

    Examples:
      | method | endpoint                                                       |
      | GET    | /accounts/{account_id_A}/summary                               |
      | GET    | /accounts/{account_id_A}/transactions?from_date=2026-04-01     |
      | POST   | /accounts/{account_id_A}/transactions                          |
      | PATCH  | /cards/{card_id_A}/status                                      |
      | PUT    | /cards/{card_id_A}/pin                                         |
      | GET    | /accounts/{account_id_A}/statements/{statement_id_A}           |
      | POST   | /accounts/{account_id_A}/payments                              |
      | POST   | /notifications/webhook                                         |

  @api @AEGIS-AUTHZ-006
  Scenario: Owner can access own summary while non-owner cannot
    Given User A is authenticated and owns account_id_A
    When User A sends a GET request to '/accounts/{account_id_A}/summary'
    Then the response status should be 200
    And masked PAN should only appear if referenced
    When User B sends a GET request to '/accounts/{account_id_A}/summary'
    Then the response status should be 403
    And no data leakage should occur

  # Notifications Webhook Validation and Idempotency
  @api @AEGIS-NOTIF-011
  Scenario Outline: Notifications webhook invalid inputs and authorization checks
    Given I have a service authorization token '<service_auth>'
    When I send a POST request to '/notifications/webhook' with JSON payload
      """
      {
        "account_id":"<account_id>",
        "alert_type":"<alert_type>",
        "channel":"<channel>",
        "severity":"<severity>",
        "message_body":"<message_body>",
        "idempotency_key":"<idempotency_key>"
      }
      """
    Then the response status should be <status>
    And the error code should be '<error_code>'

    Examples:
      | service_auth | account_id | alert_type        | channel  | severity | message_body             | idempotency_key                       | status | error_code           |
      | VALID        | A          | PAYMENT_REMINDER  | IN_APP   | INFO     | Invalid alert            | 11111111-2222-4333-8444-555555555555  | 400    | INVALID_ALERT_TYPE   |
      | VALID        | A          | STATEMENT_READY   | FAX      | INFO     | Invalid channel          | 11111111-2222-4333-8444-555555555556  | 400    | INVALID_ALERT_TYPE   |
      | VALID        | A          | STATEMENT_READY   | IN_APP   | INFO     | Missing idempotency key  |                                       | 400    | VALIDATION_ERROR     |
      | MISSING      | A          | STATEMENT_READY   | IN_APP   | INFO     | Unauthorized             | 11111111-2222-4333-8444-555555555557  | 401    | FORBIDDEN            |

  @api @AEGIS-NOTIF-011
  Scenario: Notifications webhook idempotency scoping per account and across channels
    Given I have a valid service authorization token
    When I send a POST request to '/notifications/webhook' with JSON payload
      """
      {
        "account_id":"A",
        "alert_type":"STATEMENT_READY",
        "channel":"IN_APP",
        "severity":"INFO",
        "message_body":"Your statement is ready",
        "idempotency_key":"K1"
      }
      """
    Then the response status should be 200
    When I resend the same payload with idempotency_key 'K1'
    Then the response status should be 409
    And the error code should be 'DUPLICATE_NOTIFICATION'
    When I send the same logical alert to account 'B' with the same idempotency_key 'K1'
    Then the response status should be 200
    And only account 'B' should receive the new delivery

  @api @AEGIS-NOTIF-LIMITS-030
  Scenario: Notifications webhook message length and channel-scoped idempotency per account
    Given I have a valid service authorization token
    When I send a POST request to '/notifications/webhook' with JSON payload exceeding 500 chars in message_body
    Then the response status should be 400
    When I send a valid payload with exactly 500-char message_body and idempotency_key 'K-OVERLIM-2'
    Then the response status should be 200
    And the in-app notification should render safely without scripts
    When I resend the same payload with the same idempotency_key 'K-OVERLIM-2' but channel 'EMAIL'
    Then the response status should be 409
    And the error code should be 'DUPLICATE_NOTIFICATION'

  # Email Verification and Login Enforcement
  @api @ui @AEGIS-AUTH-VER-012
  Scenario: Email verification lifecycle with blocked pre-verification login and resend
    Given I am on the registration page and have a CSRF token
    When I send a POST request to '/auth/register' with JSON payload
      """
      {
        "first_name":"Verity",
        "last_name":"Quinn",
        "email":"verify.qa+20260428@example.com",
        "password":"Str0ng!Verify-Token",
        "date_of_birth":"1990-04-28",
        "phone_number":"+14165550199",
        "ssn_last4":"1234",
        "agree_terms":true
      }
      """
    Then the response status should be 201
    When I send a POST request to '/auth/login' with JSON payload
      """
      { "email":"verify.qa+20260428@example.com","password":"Str0ng!Verify-Token" }
      """
    Then the response status should be 403
    And the error code should be 'ACCOUNT_UNVERIFIED'
    When I send a GET request to '/auth/verify-email?token={valid_verification_token}'
    Then the response status should be 200
    And the response should indicate 'VERIFIED'
    When I resend GET '/auth/verify-email?token={valid_verification_token}'
    Then the response status should be 409
    And the error code should be 'ALREADY_VERIFIED'
    When I send a POST request to '/auth/verification/resend' with JSON payload
      """
      { "email":"verify.qa+20260428b@example.com" }
      """
    Then the response status should be 200
    When I send a GET request to '/auth/verify-email?token=abc.def.ghi'
    Then the response status should be 400
    And the error code should be 'INVALID_TOKEN' or 'TOKEN_EXPIRED'
    When I send a POST request to '/auth/login' with valid MFA after verification
    Then the response status should be 200
    And JWT cookies should be HttpOnly, Secure with SameSite=Strict
    And no tokens should be stored in localStorage/sessionStorage

  # Refresh Rotation and Concurrency
  @api @AEGIS-AUTH-REF-013
  Scenario: Refresh token rotation under multi-tab concurrency with CSRF continuity
    Given Tab A is logged in with remember_me and has refresh_token 'R1' in cookies
    And Tab B is opened with the same cookie jar
    When Tab A sends POST '/auth/token/refresh' using 'R1'
    Then the response status should be 200 and a new refresh_token 'R2' is set in cookies
    When Tab B sends POST '/auth/token/refresh' using 'R1'
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'
    When Tab B sends GET '/accounts/{account_id}/summary' with current cookies
    Then the response status should be 200
    When Tab B sends POST '/auth/token/refresh' using 'R2'
    Then the response status should be 200 and a new refresh_token 'R3' is set
    When either tab retries refresh with 'R2'
    Then the response status should be 401 and error 'TOKEN_INVALID'
    When I send a POST request to '/accounts/{account_id}/transactions' without X-CSRF-Token
    Then the response status should be 403 and error 'CSRF_MISSING'
    When I retry the same POST with a valid X-CSRF-Token
    Then the response status should be 200 and a 'transaction_id' is returned

  # Transactions History Filters and Pagination
  @api @AEGIS-TXN-HIST-014
  Scenario Outline: Transactions history category filters, date-range validation, and paging
    Given I am authenticated as the account owner
    When I send a GET request to '/accounts/{account_id}/transactions<query>'
    Then the response status should be <status>
    And the results should match '<expectation>'

    Examples:
      | query                                                                                      | status | expectation                          |
      |                                                      | 200    | Default cycle with mixed categories |
      | ?category=PURCHASE                                   | 200    | Only PURCHASE                        |
      | ?category=REFUND                                     | 200    | Only REFUND                          |
      | ?from_date=2026-05-10&to_date=2026-05-01             | 400    | INVALID_DATE_RANGE                   |
      | ?from_date=2026-04-01&to_date=2026-04-30             | 200    | Only in-range items                  |
      | ?per_page=100&page=1                                 | 200    | Up to 100 items                      |
      | ?per_page=25&page=9999                               | 200    | Empty list with valid metadata       |
      | ?page=0                                              | 400    | Validation error for page min 1      |

  # Security and Session Management
  @api @ui @AEGIS-SEC-004
  Scenario: Login lockout, per-IP rate limiting, refresh rotation, CSRF cross-site protection, inactivity timeout, and PAN masking
    Given I am on the login page
    When I attempt to login with wrong password 5 times within a short window
    Then the first 4 responses should be 401 'INVALID_CREDENTIALS' and the 5th should be 403 'ACCOUNT_LOCKED' with 'unlock_at'
    When I continue login attempts from the same IP exceeding 10/min
    Then the response status should be 429 and error 'RATE_LIMITED' with 'retry_after'
    When the unlock_at passes and I login with correct credentials and valid MFA
    Then the response status should be 200 and cookies are HttpOnly, Secure, SameSite=Strict with no localStorage tokens
    When I rotate the refresh token and immediately reuse the old refresh
    Then the reuse response should be 401 'TOKEN_INVALID' and the session remains valid on the latest tokens
    When I attempt a cross-site POST '/accounts/{account_id}/payments' without X-CSRF-Token
    Then the response status should be 401 or 403 and no payment is created
    When I include a valid X-CSRF-Token on a benign POST and submit
    Then the response status should be 200
    When I idle for 13 minutes
    Then a 2-minute warning modal should appear
    When I reach 15 minutes of inactivity
    Then I am auto-logged out and API calls return 401 requiring re-auth
    And PAN is masked everywhere as '**** **** **** 1234' and never appears in DOM or logs

  # WebSocket Real-time Stream
  @ws @AEGIS-WS-STREAM-015
  Scenario: Authorized subscription to own account, forbidden cross-account, schema validation, reconnect and dedupe
    Given I logged in and have JWT cookies
    When I connect to 'wss://realtime.aegiscard.com/v2/stream' with JWT
    Then I should receive a 'connected' acknowledgment
    When I subscribe to topic 'account:{account_id}'
    Then I should receive a 'subscribed' confirmation
    When a transaction event is published with message_id 'MSG-2001', type 'transaction.authorized', amount 42.50, mcc 5942, masked_pan '**** **** **** 1234'
    Then I should see the event in the UI with required fields
    When I attempt to subscribe to 'account:{other_account_id}'
    Then I should receive 'SUBSCRIPTION_FORBIDDEN' and no data from that topic
    When a malformed event is published
    Then the client should ignore it without crashing
    When the socket disconnects and reconnects with backoff
    And the same event with message_id 'MSG-2001' and a new 'MSG-2002' are published
    Then I should see exactly one instance of MSG-2001 and one of MSG-2002

  @ws @AEGIS-WS-UNAUTH-029
  Scenario: WebSocket unauthorized handshake and subscribe/unsubscribe lifecycle
    Given there is no JWT present
    When I attempt to connect to 'wss://realtime.aegiscard.com/v2/stream'
    Then the handshake should be rejected with 401 or 'auth_failed'
    Given I login and have JWT cookies
    When I connect and subscribe to 'account:{account_id}'
    Then I receive a 'subscribed' ack
    When I publish message_id 'MSG-1001' and verify one UI entry
    And I unsubscribe from 'account:{account_id}'
    And publish message_id 'MSG-1002'
    Then no new entries should appear while unsubscribed
    When I re-subscribe and publish 'MSG-1002' again and 'MSG-1003'
    Then I should see one 'MSG-1002' and one 'MSG-1003'
    And no tokens are stored in localStorage

  # Payments Scheduling and Types
  @api @AEGIS-PAY-SCHED-016
  Scenario: Payment scheduling boundaries: min amount, past-date rejection, same-day immediate, and FULL_BALANCE
    Given I am authenticated with JWT cookies and have a valid X-CSRF-Token
    And I have retrieved '/accounts/{account_id}/summary' to capture total_balance and minimum_payment_due
    When I send a POST request to '/accounts/{account_id}/payments' with JSON payload
      """
      { "payment_amount":0.99,"payment_type":"CUSTOM","bank_account_id":"BANK123" }
      """
    Then the response status should be 400
    And the error code should be 'BELOW_MINIMUM'
    When I send a POST request to '/accounts/{account_id}/payments' with JSON payload
      """
      { "payment_amount":5.00,"payment_type":"CUSTOM","bank_account_id":"BANK123","scheduled_date":"{yesterday}" }
      """
    Then the response status should be 400
    And the error code should be 'SCHEDULED_DATE_INVALID'
    When I send a POST request to '/accounts/{account_id}/payments' with JSON payload
      """
      { "payment_amount":5.00,"payment_type":"CUSTOM","bank_account_id":"BANK123","scheduled_date":"{today}" }
      """
    Then the response status should be 200
    And the response should treat it as immediate (no scheduled_date echoed)
    When I send a POST request to '/accounts/{account_id}/payments' with JSON payload
      """
      { "payment_type":"FULL_BALANCE","payment_amount":{total_balance},"bank_account_id":"BANK123" }
      """
    Then the response status should be 200
    And 'new_balance_estimate' should be 0.00
    When I send a POST request to '/accounts/{account_id}/payments' without X-CSRF-Token
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'

  @api @AEGIS-PAY-TYPES-025
  Scenario: MINIMUM and STATEMENT_BALANCE payments and precision enforcement
    Given I captured 'minimum_payment_due' and 'statement_balance' from the current statement
    When I send POST '/accounts/{account_id}/payments' with JSON
      """
      { "payment_amount":10.999,"payment_type":"CUSTOM","bank_account_id":"BANK123" }
      """
    Then the response status should be 400
    When I send POST '/accounts/{account_id}/payments' with JSON
      """
      { "payment_amount":{total_balance_plus_one_cent},"payment_type":"CUSTOM","bank_account_id":"BANK123" }
      """
    Then the response status should be 400 or 422
    When I send POST '/accounts/{account_id}/payments' with JSON
      """
      { "payment_type":"MINIMUM","bank_account_id":"BANK123" }
      """
    Then the response status should be 200
    And the response should include 'payment_id' and 'new_balance_estimate'
    When I send POST '/accounts/{account_id}/payments' with JSON
      """
      { "payment_type":"STATEMENT_BALANCE","bank_account_id":"BANK123" }
      """
    Then the response status should be 200
    And 'new_balance_estimate' should reflect the statement balance reduction
    When I resend the last POST without X-CSRF-Token
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'

  # Card Controls: Lost/Stolen and Delivery Address Override
  @api @AEGIS-CARD-LOST-009
  Scenario: Report lost/stolen irreversible flow, OTP failures, invalid transitions, and PIN format enforcement
    Given I am authenticated with JWT cookies and have a valid X-CSRF-Token and an Active card
    When I send a PATCH request to '/cards/{card_id}/status' with JSON
      """
      { "status":"Frozen","reason":"Traveling","confirm_otp":"000000" }
      """
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'
    When I send a PUT request to '/cards/{card_id}/pin' with JSON
      """
      { "new_pin":"12345","confirm_pin":"12345","session_otp":"123456" }
      """
    Then the response status should be 400
    And the error code should be 'PIN_FORMAT'
    When I send a PUT request to '/cards/{card_id}/pin' with JSON
      """
      { "new_pin":"1234","confirm_pin":"4321","session_otp":"123456" }
      """
    Then the response status should be 400
    And the error code should be 'PIN_MISMATCH'
    When I send a POST request to '/cards/{card_id}/report-lost' with JSON
      """
      { "loss_type":"STOLEN","last_known_use":"2026-04-28T10:00:00Z" }
      """
    Then the response status should be 200
    And the response should include 'blocked_card_id','new_card_eta','case_number'
    When I attempt to PATCH '/cards/{card_id}/status' back to 'Active' with valid OTP
    Then the response status should be 400
    And the error code should be 'INVALID_TRANSITION'
    When I send a PUT request to '/cards/{card_id}/pin' with JSON
      """
      { "new_pin":"2580","confirm_pin":"2580","session_otp":"123456" }
      """
    Then the response status should be 403
    And the error code should be 'CARD_BLOCKED'
    When I resend POST '/cards/{card_id}/report-lost'
    Then the response status should be 409
    And the error code should be 'ALREADY_BLOCKED'
    When I send a POST request to '/accounts/{account_id}/transactions' after block
      """
      {
        "transaction_amount":5.00,"merchant_name":"Books","merchant_id":"BK1",
        "mcc_code":"5942","transaction_type":"PURCHASE","description":"Test"
      }
      """
    Then the response status should be 403
    And the error code should be 'CARD_INACTIVE'
    And all responses should mask PAN if referenced

  @api @AEGIS-CARD-DELIV-019
  Scenario: Report lost/stolen with delivery address override validation and replacement confirmation
    Given I am authenticated with JWT cookies and have a valid X-CSRF-Token and an Active card
    When I send a POST request to '/cards/{card_id}/report-lost' with JSON
      """
      {
        "loss_type":"LOST",
        "last_known_use":"2026-04-28T10:00:00Z",
        "delivery_address":{"street":"100 King St W","city":"Toronto","province":"Ontario","postal_code":"M5H 1J9"}
      }
      """
    Then the response status should be 400
    When I send a POST request to '/cards/{card_id}/report-lost' with JSON
      """
      {
        "loss_type":"LOST",
        "last_known_use":"2026-04-28T10:00:00Z",
        "delivery_address":{"street":"100 King St W","city":"Toronto","province":"ON","postal_code":"123 456"}
      }
      """
    Then the response status should be 400
    When I send a POST request to '/cards/{card_id}/report-lost' with JSON
      """
      {
        "loss_type":"STOLEN",
        "last_known_use":"2026-04-28T10:00:00Z",
        "delivery_address":{"street":"100 King St W","city":"Toronto","province":"ON","postal_code":"M5H 1J9"}
      }
      """
    Then the response status should be 200
    And the response should include 'blocked_card_id','new_card_eta','case_number'
    And the UI should show Blocked banner and replacement to the override address

  # Refresh Token Expiry and Recovery
  @api @AEGIS-AUTH-EXPIRE-020
  Scenario: Refresh token TTL expiry, 401 on refresh, re-authentication, and CSRF continuity
    Given I login with remember_me false and have refresh_token 'R1'
    And I fast-forward time beyond refresh TTL
    When I send POST '/auth/token/refresh' using expired 'R1'
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'
    When I send GET '/accounts/{account_id}/summary' with expired access token
    Then the response status should be 401
    When I re-login with valid MFA and obtain fresh tokens 'R2'
    Then POST '/auth/token/refresh' with 'R2' returns 200 and rotates to 'R3'
    And reusing 'R2' returns 401 'TOKEN_INVALID'
    When I send POST '/accounts/{account_id}/payments' without X-CSRF-Token
    Then the response status should be 403 'CSRF_MISSING'
    When I resend the POST with a valid X-CSRF-Token
    Then the response status should be 200 and includes 'payment_id' and 'new_balance_estimate'

  # Account Summary and Rewards Toggle
  @api @AEGIS-SUMMARY-REW-021
  Scenario: Summary include_rewards toggle, rewards floor verification, and owner-only enforcement
    Given I am authenticated and have a valid X-CSRF-Token
    When I post a Travel PURCHASE of 88.88 CAD (MCC 4722) and a non-Travel PURCHASE of 19.99 CAD (MCC 5942)
    Then both responses should be 200
    When I send GET '/accounts/{account_id}/summary'
    Then the response status should be 200 and 'points_balance' should be absent
    When I send GET '/accounts/{account_id}/summary?include_rewards=true'
    Then the response status should be 200
    And 'points_balance' should reflect floor(88.88*3)+floor(19.99*1)=266+19=285 over baseline
    When I send GET '/accounts/{other_account_id}/summary'
    Then the response status should be 403 and no data leakage

  # Application Step 2 Idempotency and Session Misuse
  @api @AEGIS-APP-IDEMP-022
  Scenario: Step 2 idempotency and cross-application session token misuse
    Given I started application A1 and received session_token S1
    When I send POST '/applications/A1/financials' with X-App-Session S1
    Then the response status should be 200 with 'PENDING_REVIEW' and 'fico_pull_id' F1
    When I resend the same POST for A1 with S1
    Then the response status should be 200 and 'fico_pull_id' equals F1 (idempotent)
    When I fire two concurrent POSTs for A1 with S1
    Then at most one soft pull should be created (same F1 reused)
    When I start application A2 and receive session_token S2
    And I attempt POST '/applications/A2/financials' with X-App-Session S1
    Then the response status should be 401 and error 'SESSION_EXPIRED'
    When I resend for A2 with X-App-Session S2
    Then the response status should be 200 with 'fico_pull_id' F2 different from F1
    When I complete Step 3 for A1 via POST '/applications/A1/submit'
    Then no additional credit pull occurs
    When I attempt Step 2 for A1 again with S1 post-decision
    Then the response status should be 401 or 400 invalid state

  # CSRF Token Binding Across Session Changes
  @api @AEGIS-CSRF-BIND-023
  Scenario: CSRF token binding and invalid-token rejection across endpoints
    Given I login and load CSRF token T1 from bootstrap
    When I send POST '/accounts/{account_id}/transactions' with X-CSRF-Token T1
      """
      { "transaction_amount":1.00,"merchant_name":"Books","merchant_id":"BK1","mcc_code":"5942","transaction_type":"PURCHASE","description":"Test" }
      """
    Then the response status should be 200
    When I log out and log back in to obtain CSRF token T2
    Then T2 should differ from T1
    When I send POST '/accounts/{account_id}/payments' with X-CSRF-Token T1
      """
      { "payment_amount":5.00,"payment_type":"CUSTOM","bank_account_id":"BANK123" }
      """
    Then the response status should be 403 and error 'CSRF_INVALID'
    When I resend with X-CSRF-Token T2
    Then the response status should be 200
    When I send PATCH '/cards/{card_id}/status' with X-CSRF-Token T1
      """
      { "status":"Frozen","reason":"Pause","confirm_otp":"123456" }
      """
    Then the response status should be 403 and error 'CSRF_INVALID'
    When I resend PATCH with X-CSRF-Token T2 and valid OTP
    Then the response status should be 200 and new_status 'Frozen'
    When I send PUT '/cards/{card_id}/pin' with X-CSRF-Token T1
      """
      { "new_pin":"1234","confirm_pin":"1234","session_otp":"123456" }
      """
    Then the response status should be 403 and error 'CSRF_INVALID'
    When I resend PUT with X-CSRF-Token T2
    Then the response status should be 200
    When I send DELETE '/accounts/{id}' with X-CSRF-Token T1
    Then the response status should be 403 and error 'CSRF_INVALID'

  # Essential Buffer Lifecycle
  @api @AEGIS-TXN-BUFFER-LIFE-024
  Scenario: Essential over-limit buffer lifecycle with recovery after payment
    Given available_credit is exactly 1,000.00 CAD on '/accounts/{account_id}/summary'
    When I POST an essential PURCHASE of 600.00 (MCC 5411) with CSRF
    Then the response status should be 200 and over_limit_flag false
    When I POST an essential PURCHASE of 450.00 (MCC 4900) with CSRF
    Then the response status should be 200 and over_limit_flag true and available_credit near -50.00
    When I POST a non-essential PURCHASE of 5.00 (MCC 5942)
    Then the response status should be 402 and error 'INSUFFICIENT_FUNDS'
    When I POST an essential PURCHASE of 51.00 (MCC 5411)
    Then the response status should be 402 and error 'INSUFFICIENT_FUNDS'
    When I POST a payment of 60.00 CUSTOM with CSRF
    Then the response status should be 200
    When I GET '/accounts/{account_id}/summary'
    Then available_credit should be >= 10.00
    When I POST a non-essential PURCHASE of 5.00 (MCC 5942)
    Then the response status should be 200
    When I POST any transaction without X-CSRF-Token
    Then the response status should be 403 and error 'CSRF_MISSING'
    And cross-account attempts should return 403 'FORBIDDEN' with no leakage

  # Transactions High-Value and FX Precision
  @api @AEGIS-TXN-MAXFX-028
  Scenario: Transactions maximum amount and FX exchange_rate precision with REQ-006 rounding
    Given I am authenticated with sufficient available_credit (>= 10,000,000.00) and have CSRF
    When I POST a CAD PURCHASE with transaction_amount 10000000.00 (MCC 5942)
    Then the response status should be 400 or 422 for amount exceeding Decimal(10,2) max
    When I POST a CAD PURCHASE with transaction_amount 9999999.99 (MCC 5942)
    Then the response status should be 200 and no foreign_fee_amount present
    When I POST an EUR PURCHASE with amount 1234.56 and exchange_rate 1.2345678 (7 dp)
    Then the response status should be 400 for exchange_rate precision violation
    When I POST an EUR PURCHASE with amount 1234.56 and exchange_rate 1.234567 (6 dp) (MCC 4722)
    Then the response status should be 200
    And foreign_fee_amount and total_cad are computed per REQ-006 and rounded to two decimals
    When I POST an FX PURCHASE with exchange_rate 0.000000
    Then the response status should be 400 for invalid exchange_rate > 0
    When I POST a minimal positive CAD PURCHASE of 0.01
    Then the response status should be 200 if credit allows

  # Trusted Device and remember_me TTL
  @api @AEGIS-AUTH-TRUST-017
  Scenario: Trusted device remember_me 30-day TTL and MFA suppression on known device
    Given I attempt login from Device D1 with remember_me true and provide MFA
    Then the response status should be 200
    And refresh_token cookie TTL should be approximately 30 days
    When I login again from Device D1 with remember_me true and omit MFA
    Then the response status should be 200 due to trusted device
    When I login from Device D2 with remember_me false and omit MFA
    Then MFA is required and upon submission the response is 200
    And refresh_token TTL is shorter than 30 days
    When I rotate refresh on D1 and reuse the old refresh
    Then the reuse returns 401 'TOKEN_INVALID'
    When I POST a $1.00 PURCHASE with CSRF
    Then the response status should be 200
    When I retry the same POST without CSRF
    Then the response status should be 403 'CSRF_MISSING'

  # Right to Rescind Day-14 Boundary
  @api @AEGIS-RESCIND-BOUND-018
  Scenario: Rescind on exact Day 14 with CSRF enforcement and post-closure behavior
    Given the account issuance date is exactly 14 days ago and I have CSRF
    When I send DELETE '/accounts/{id}' without X-CSRF-Token
    Then the response status should be 403 'CSRF_MISSING'
    When I resend DELETE '/accounts/{id}' with X-CSRF-Token
    Then the response status should be 200 or 204
    When I GET '/accounts/{id}/summary'
    Then account_status should be 'Closed'
    When I POST '/accounts/{account_id}/transactions' with CSRF
    Then the response status should be 403 'FORBIDDEN' or 'CARD_INACTIVE'
    When I PATCH '/cards/{card_id}/status' with CSRF
    Then the response status should be 400 'INVALID_TRANSITION'
    When I POST '/accounts/{account_id}/payments' with CSRF
    Then the response status should be 403 'FORBIDDEN'
    And the audit trail should record the rescind event with required fields

  # Global PII Leakage Sweep
  @api @ui @AEGIS-PII-SWEEP-026
  Scenario: Ensure no PII leakage on error payloads and UI across modules
    Given I prepare invalid and cross-account requests
    When I POST '/auth/register' with invalid email and underage DOB
    Then the response status should be 400 with field errors and no PAN/SSN (only masked)
    When I POST '/auth/login' with wrong password
    Then the response status should be 401 'INVALID_CREDENTIALS' and no PII in body
    When I POST '/accounts/{account_id}/transactions' with transaction_amount 0.00
    Then the response status should be 422 'INVALID_AMOUNT' and no PII
    When I GET '/accounts/{other_account_id}/summary'
    Then the response status should be 403 'FORBIDDEN' with no leakage
    When I GET '/accounts/{account_id}/statements/{random_id}'
    Then the response status should be 404 'NOT_FOUND' with no PII
    When I POST '/accounts/{account_id}/payments' with invalid bank_account_id
    Then the response status should be 422 'INVALID_BANK_ACCOUNT' and no PAN
    When I PATCH '/cards/{card_id}/status' with bad OTP
    Then the response status should be 401 'OTP_FAILED' and no PII
    When I PUT '/cards/{card_id}/pin' with non-numeric PIN
    Then the response status should be 400 'PIN_FORMAT' and no PII
    When I POST '/applications/{application_id}/submit' without CSRF
    Then the response status should be 403 'CSRF_MISSING' with no PII
    And browser console/network logs should show no full PAN or SSN

  # Application Draft Auto-save and Resume (UI-centric with API submit)
  @ui @api @AEGIS-APP-AUTOSAVE-027
  Scenario: Draft auto-save at 60s, sanitized localStorage, resume, submit clears draft, and inactivity warning
    Given I am on Credit Application Step 1 and a CSRF token is loaded
    And there are no tokens in localStorage/sessionStorage
    When I fill in Step 1 fields without submitting
    And I wait at least 60 seconds
    Then a draft key (e.g., 'aegis.application.draft') should appear in localStorage
    And the draft JSON should contain only Step 1 data with no SSN or PAN and a recent lastSaved timestamp
    When I restart the browser and return to the application
    Then I should be prompted to 'Resume draft' and fields should repopulate
    When I stay idle for 13 minutes
    Then a 2-minute warning modal appears
    When I click 'Stay signed in'
    Then the modal closes and form data remains intact
    When I click Continue to submit Step 1 and the portal sends POST '/applications/start' with X-CSRF-Token
    Then the response status should be 201 with 'application_id' and 'session_token'
    And the draft key should be cleared or marked consumed
    And reloading the page should not offer resume

