Feature: Aegis Card Portal - Security, Authentication, Applications, Transactions, Billing, and Compliance

  # Background common to most API tests
  Background:
    Given the API base URL is 'https://api.aegiscard.com/v2'
    And the portal URL is 'https://portal.aegiscard.com'
    And the realtime WebSocket URL is 'wss://realtime.aegiscard.com/v2/stream'
    And the client enforces TLS 1.3 with HSTS and no mixed content
    And the default request headers include 'Content-Type: application/json'
    And no tokens are stored in localStorage or sessionStorage

  # API Tests

  @api @e2e @security
  Scenario: End-to-End Applicant Journey with Security Controls (Register -> Verify -> Login MFA -> Application -> APPROVED -> Token Rotation -> CSRF Enforcement -> PIN -> Summary -> Session Timeout)
    Given there is no existing account for 'user@example.com' and MFA seed is provisioned
    When I send a POST request to '/auth/register' with JSON payload
      """
      {
        "first_name":"Jane",
        "last_name":"Public",
        "email":"user@example.com",
        "password":"Str0ng-P@ssword!2026",
        "date_of_birth":"<today_minus_18y>",
        "phone_number":"+14165550123",
        "ssn_last4":"1234",
        "agree_terms":true
      }
      """
    Then the response status should be 201
    And the response JSON should contain fields 'user_id' and 'verification_token'

    When I send a POST request to '/auth/verify' with JSON payload
      """
      { "verification_token": "<verification_token>" }
      """
    Then the response status should be 200

    When I send a POST request to '/auth/login' with JSON payload
      """
      {
        "email":"user@example.com",
        "password":"Str0ng-P@ssword!2026",
        "device_id":"550e8400-e29b-41d4-a716-446655440000",
        "remember_me":true,
        "mfa_code":"<valid_totp>"
      }
      """
    Then the response status should be 200
    And HttpOnly, Secure, SameSite=Strict cookies for access_token and refresh_token should be set
    And no tokens should exist in localStorage or be accessible to JavaScript

    When I send a GET request to '/auth/csrf'
    Then the response status should be 200
    And I save the 'X-CSRF-Token' value for subsequent requests

    When I send a POST request to '/applications/start' with headers 'X-CSRF-Token' and JSON payload
      """
      {
        "full_legal_name":"Jane Q Public",
        "email":"user@example.com",
        "phone_number":"+14165550123",
        "residential_address":{
          "street":"123 King St",
          "city":"Toronto",
          "province":"ON",
          "postal_code":"A1A 1A1"
        },
        "id_type":"PASSPORT",
        "id_number":"X1234567"
      }
      """
    Then the response status should be 201
    And the response JSON should contain fields 'application_id' and 'session_token'

    When I immediately resend the same POST to '/applications/start' with the same payload and CSRF
    Then the response status should be 409
    And the error code should be 'DUPLICATE_APPLICATION'

    When I send a POST request to '/auth/otp/request' with JSON payload
      """
      {"channel":"SMS","purpose":"PHONE_VERIFY"}
      """
    And I send a POST request to '/auth/otp/verify' with JSON payload
      """
      {"code":"<valid_otp>"}
      """
    Then the response status should be 200

    When I wait for autosave interval to elapse and reload the application page
    Then only non-sensitive draft fields should be restored in the UI
    And no ssn_last4, tokens, or PAN should be present in DOM or localStorage

    When I send a POST request to '/applications/<application_id>/financials' with headers 'X-CSRF-Token' and 'X-App-Session' and JSON payload
      """
      {
        "employment_status":"EMPLOYED",
        "employer_name":"Aegis Ltd",
        "gross_annual_income":85000.00,
        "monthly_rent":1500.00,
        "existing_debt_payments":300.00,
        "sin_consent":true
      }
      """
    Then the response status should be 200
    And the response JSON should contain fields 'status' with value 'PENDING_REVIEW' and 'fico_pull_id'

    When I send a POST request to '/applications/<application_id>/financials' with headers 'X-CSRF-Token' and 'X-App-Session' and JSON payload
      """
      {
        "employment_status":"EMPLOYED",
        "gross_annual_income":85000.00,
        "monthly_rent":1500.00,
        "existing_debt_payments":300.00,
        "sin_consent":true
      }
      """
    Then the response status should be 400
    And the error field should indicate 'employer_name' is required

    When I send a POST request to '/applications/<application_id>/submit' with headers 'X-CSRF-Token' and 'X-App-Session' and JSON payload
      """
      {
        "card_product_id":"AEGIS_GOLD",
        "e_signature":"SmFuZSBRIFB1YmxpYw=="
      }
      """
    Then the response status should be 200
    And the decision should be 'APPROVED'
    And the response should include 'credit_limit' and 'card_number_masked' matching '**** **** **** ####'
    And no full PAN should be present in the response or DOM

    When I send a POST request to '/auth/token/refresh'
    Then the response status should be 200
    And new rotated refresh_token and access_token cookies should be set

    When I send a POST request to '/auth/token/refresh' reusing the previous refresh_token
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'

    When I send a PUT request to '/cards/<card_id>/pin' without 'X-CSRF-Token' and JSON payload
      """
      {"new_pin":"1234","confirm_pin":"1234","session_otp":"<valid_otp>"}
      """
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'

    When I send a PUT request to '/cards/<card_id>/pin' with headers 'X-CSRF-Token' and JSON payload
      """
      {"new_pin":"1234","confirm_pin":"4321","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    And the error code should be 'PIN_MISMATCH'

    When I send a PUT request to '/cards/<card_id>/pin' with headers 'X-CSRF-Token' and JSON payload
      """
      {"new_pin":"1234","confirm_pin":"1234","session_otp":"<valid_otp>"}
      """
    Then the response status should be 200
    And the response JSON should contain 'updated_at'

    When I send a GET request to '/accounts/<account_id>/summary'
    Then the response status should be 200
    And 'available_credit', 'credit_limit', and 'account_status' should be present
    And rewards are excluded by default

    When I send a GET request to '/accounts/<account_id>/summary?include_rewards=true'
    Then the response status should be 200
    And 'points_balance' should be present

    When I remain idle in the portal for 13 minutes
    Then a session-timeout warning modal should appear

    When I remain idle until 15 minutes and invoke a protected API
    Then the response status should be 401
    And the UI should be auto-logged out

    When I login again with MFA and fetch the application/account artifacts
    Then previously created application and account are accessible
    And no sensitive data is persisted in frontend storage

  @api
  Scenario Outline: Registration Validations and Case-Insensitive Email Uniqueness
    Given the API enforces registration field rules
    When I send a POST request to '/auth/register' with JSON payload
      """
      {
        "first_name":"John",
        "last_name":"Public",
        "email":"<email>",
        "password":"<password>",
        "date_of_birth":"<date_of_birth>",
        "phone_number":"<phone>",
        "ssn_last4":"<ssn_last4>",
        "agree_terms":<agree_terms>
      }
      """
    Then the response status should be <status>
    And the response should contain or omit 'verification_token' as '<verification_token_expected>'
    And the error code should be '<error_code>'

    Examples:
      | email               | password             | date_of_birth      | phone         | ssn_last4 | agree_terms | status | verification_token_expected | error_code        |
      | new_user@example.com| Str0ngPass!2026     | 2008-01-01         | +14165550123  | 1234     | false       | 400    | absent                      | TERMS_REQUIRED    |
      | new_user@example.com| Short1!             | 2000-01-01         | +14165550123  | 1234     | true        | 422    | absent                      | WEAK_PASSWORD     |
      | new_user@example.com| Str0ngPass!2026     | <17y_364d_ago>     | +14165550123  | 1234     | true        | 400    | absent                      | DOB_INVALID       |
      | new_user@example.com| Str0ngPass!2026     | 2000-01-01         | 4165550123    | 1234     | true        | 400    | absent                      | PHONE_INVALID     |
      | new_user@example.com| Str0ngPass!2026     | 2000-01-01         | +14165550123  | 123      | true        | 400    | absent                      | SSN_LAST4_INVALID |
      | user@example.com    | Str0ngPass!2026     | <today_minus_18y>  | +14165550123  | 1234     | true        | 201    | present                     |                   |
      | USER@EXAMPLE.COM    | Str0ngPass!2026     | <today_minus_18y>  | +14165550123  | 1234     | true        | 409    | absent                      | EMAIL_EXISTS      |

  @api @auth
  Scenario: Authentication Lockout, Rate Limit, Remember Me TTL, Logout Invalidation
    Given the user 'user@example.com' exists with MFA enabled
    When I perform 4 POST requests to '/auth/login' with wrong password within 60 seconds
    Then each response status should be 401
    And the error code should be 'INVALID_CREDENTIALS'
    When I perform a 5th POST to '/auth/login' with wrong password
    Then the response status should be 403
    And the error code should be 'ACCOUNT_LOCKED'
    When I attempt a correct login with valid TOTP during lockout
    Then the response status should be 403
    And the error code should be 'ACCOUNT_LOCKED'
    When I wait until 'unlock_at' plus 1 minute and login with remember_me true
    Then the response status should be 200
    And refresh cookie expiry should be approximately 30 days
    When I send 10 more login requests within a minute and a 11th attempt
    Then the 11th response status should be 429
    And the error code should be 'RATE_LIMITED'
    And the 'retry_after' header should be present
    When I send a POST to '/auth/logout' with a valid 'X-CSRF-Token'
    Then the response status should be 200
    And access and refresh cookies should be cleared
    When I send POST '/auth/token/refresh' using the pre-logout refresh token
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'
    When I GET '/accounts/<account_id>/summary' without fresh login
    Then the response status should be 401

  @api @auth
  Scenario: Refresh Token Rotation Concurrency Across Tabs and CSRF Session Binding
    Given Tab A and Tab B share an initial authenticated session for 'user@example.com'
    When Tab A sends POST '/auth/token/refresh'
    Then Tab A receives 200 and rotated refresh_token R1-new
    When Tab B sends POST '/auth/token/refresh' with the now-stale refresh token
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'
    When Tab A GETs '/auth/csrf' and stores CSRF-A and sends POST '/auth/logout' with CSRF-A
    Then Tab A receives 200 and cookies are expired
    When Tab B sends POST '/auth/logout' using CSRF-A
    Then the response status should be 403
    And the error code should be 'CSRF_INVALID'
    When Tab B logs in and obtains CSRF-B then calls POST '/auth/token/refresh' twice in quick succession
    Then the first refresh returns 200 and rotates tokens
    And the second refresh returns 401 with 'TOKEN_INVALID'
    And no tokens are present in localStorage or sessionStorage in either tab

  @api @csrf
  Scenario: Access Control and CSRF Enforcement Matrix with SameSite=Strict
    Given I am logged out
    When I GET '/accounts/<owned_account_id>/summary' without auth
    Then the response status should be 401
    When I login and GET '/auth/csrf' and store CSRF-1
    And I GET '/accounts/<owned_account_id>/summary'
    Then the response status should be 200
    When I GET '/accounts/<other_account_id>/summary'
    Then the response status should be 403
    And the error code should be 'FORBIDDEN'
    When I POST '/accounts/<owned_account_id>/transactions' without 'X-CSRF-Token' and JSON payload
      """
      {"transaction_amount":5.00,"mcc_code":5999,"merchant_name":"Test","merchant_id":"T001","transaction_type":"PURCHASE"}
      """
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'
    When I retry the same POST with 'X-CSRF-Token' CSRF-1
    Then the response status should be 200
    And 'transaction_id' should be present
    When a cross-site form POST is submitted from a different origin without credentials
    Then the API returns 401 and no side effects occur
    And all cookies have Secure, HttpOnly, SameSite=Strict flags

  @api @transactions
  Scenario: Foreign Currency Purchase, Rewards, Pagination, CSRF, Rate Limit, Statements and Grace
    Given I am authenticated with a valid 'X-CSRF-Token' and rewards baseline captured
    And I connect to the WebSocket stream with a valid JWT and subscribe to 'account:<account_id>:transactions'
    When I POST '/accounts/<account_id>/transactions' with 'X-CSRF-Token' and JSON payload
      """
      {
        "transaction_amount":100.00,
        "currency_code":"USD",
        "exchange_rate":1.250000,
        "mcc_code":3000,
        "merchant_name":"Aegis Air",
        "merchant_id":"AA123",
        "transaction_type":"PURCHASE",
        "description":"Flight"
      }
      """
    Then the response status should be 200
    And 'foreign_fee_amount' should equal 3.75 and 'total_cad' should equal 128.75
    And a WebSocket event for the transaction should be received with masked PAN and no PII
    When I disconnect and reconnect the WebSocket without JWT
    Then the connection is rejected with 401 or 403
    When I POST another PURCHASE in CAD with JSON payload
      """
      {
        "transaction_amount":10.99,
        "mcc_code":5999,
        "merchant_name":"Shop",
        "merchant_id":"S001",
        "transaction_type":"PURCHASE"
      }
      """
    Then the response status should be 200
    And rewards expected increment is Travel=floor(128.75*3)=386 and Other=floor(10.99*1)=10
    When I POST a transaction without 'X-CSRF-Token'
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'
    When I GET '/accounts/<account_id>/transactions?from_date=<cycle_start>&to_date=<now>&page=1&per_page=100&category=PURCHASE'
    Then the response status should be 200
    And 'transactions', 'total_count', and 'total_pages' should be present
    When I GET '/accounts/<other_account_id>/transactions'
    Then the response status should be 403
    And the error code should be 'FORBIDDEN'
    When I rapidly POST 10 more small PURCHASES within 60 minutes
    Then all 10 responses should be 200
    When I POST an 11th within the same window
    Then the response status should be 429
    And the error code should be 'FREQ_EXCEEDED'
    And 'mfa_required' is true and 'Retry-After' header is present
    When I GET '/accounts/<account_id>/statements/<statement_id>?format=JSON' after cycle close
    Then 'total_spend' equals the sum of transaction amounts within ±0.01
    And if 'prev_statement_balance_paid_in_full' is true then 'interest_charged' equals 0 else it matches REQ-009 formula rounded to cents
    When I GET '/accounts/<account_id>/statements/<statement_id>?format=PDF'
    Then the response status should be 200 and content type is application/pdf

  @api @transactions
  Scenario Outline: Transaction Field Validation and FX Precision
    Given available_credit is at least $50.00
    When I POST '/accounts/<account_id>/transactions' with JSON payload
      """
      { "transaction_amount": <amount>, "currency_code": "<currency>", "exchange_rate": <rate>, "mcc_code": <mcc>, "merchant_name": "X", "merchant_id":"Y", "transaction_type":"PURCHASE" }
      """
    Then the response status should be <status>
    And the error code should be '<error_code>'

    Examples:
      | amount | currency | rate      | mcc  | status | error_code           |
      | 0.00   | CAD      | null      | 5999 | 422    | INVALID_AMOUNT       |
      | 5.00   | USD      | null      | 5999 | 400    | EXCHANGE_RATE_MISSING|
      | 1.23   | USD      | 1.3333337 | 3000 | 400    | EXCHANGE_RATE_PREC   |

  @api @transactions
  Scenario: Valid Small-Value FX with Rounding and Listing Page Validation
    Given available_credit baseline is recorded
    When I POST '/accounts/<account_id>/transactions' with JSON payload
      """
      {
        "transaction_amount":1.23,
        "currency_code":"USD",
        "exchange_rate":1.333333,
        "mcc_code":3000,
        "merchant_name":"MiniTravel",
        "merchant_id":"MT001",
        "transaction_type":"PURCHASE"
      }
      """
    Then the response status should be 200
    And 'foreign_fee_amount' equals 0.05 and 'total_cad' equals 1.69
    When I POST '/accounts/<account_id>/transactions' with JSON payload
      """
      {"transaction_amount":10.00,"mcc_code":6010,"merchant_name":"CashPoint","merchant_id":"CA001","transaction_type":"CASH_ADVANCE"}
      """
    Then the response status should be 200
    When I POST '/accounts/<account_id>/transactions' with JSON payload
      """
      {"transaction_amount":15.00,"mcc_code":6012,"merchant_name":"BalanceXfer","merchant_id":"BT001","transaction_type":"BALANCE_TRANSFER"}
      """
    Then the response status should be 200
    When I GET '/accounts/<account_id>/transactions?page=0&per_page=25'
    Then the response status should be 400
    And the error describes 'page must be >= 1'
    When I GET '/accounts/<account_id>/transactions?page=1&per_page=25&category=PURCHASE'
    Then the response status should be 200

  @api @transactions
  Scenario: Transactions Date/Time Boundaries, UTC/DST, per_page Max, Stable Pagination
    Given I have created transactions at T1=2026-03-14T00:00:00Z, T2=2026-03-14T23:59:59Z, T3=2026-03-15T12:00:00Z
    When I GET '/accounts/<account_id>/transactions?from_date=2026-03-14&to_date=2026-03-14&page=1&per_page=25'
    Then results include T1 and T2 only
    When I GET '/accounts/<account_id>/transactions?from_date=2026-03-15&to_date=2026-03-15&page=1&per_page=25'
    Then results include T3 only
    When I ensure UTC around DST by creating transactions at 2026-03-08T01:59:59Z and 2026-03-08T03:00:01Z
    And I GET '/accounts/<account_id>/transactions?from_date=2026-03-08&to_date=2026-03-08'
    Then both are included
    When I GET '/accounts/<account_id>/transactions?per_page=101'
    Then the response status should be 400
    And the error describes 'per_page max 100'
    When I populate more than 25 transactions and list page 1 and page 2 with per_page=25
    Then no duplicate items appear across pages and ordering is stable
    And response contains 'total_count','page','total_pages'
    And masked PAN is shown and no PII leaked

  @api @rewards
  Scenario: Rewards Accrual Boundary and MCC Classification with Floor Rounding
    Given I capture baseline points P0 via GET '/accounts/<account_id>/summary?include_rewards=true'
    When I POST four CAD PURCHASES for MCC 3000 with 1.00, MCC 3000 with 0.99, MCC 5999 with 1.00, MCC 5999 with 0.01
    Then each response status should be 200
    When I POST a transaction with invalid mcc_code '123' (3 digits)
    Then the response status should be 400
    When I GET '/accounts/<account_id>/transactions?category=PURCHASE&page=1&per_page=25'
    Then the four purchases are present
    When I GET '/accounts/<account_id>/summary?include_rewards=true'
    Then points increment equals 6 over P0 (or appears on next statement per accrual policy)
    When I GET '/accounts/<account_id>/statements/<statement_id>'
    Then rewards_earned includes +6 and total_spend reconciles to ±0.01

  @api @transactions @mfa
  Scenario: Transaction Rate-Limit Recovery via MFA
    Given I have posted 10 small PURCHASES within 60 minutes successfully
    When I POST an 11th transaction within the same window
    Then the response status should be 429
    And 'mfa_required' is true and 'Retry-After' header is present
    When I POST '/auth/otp/request' with JSON payload
      """
      {"channel":"SMS","purpose":"TRANSACTION_RATE_LIMIT"}
      """
    And I POST '/auth/otp/verify' with JSON payload
      """
      {"code":"<valid_otp>"}
      """
    Then the response status should be 200
    When I retry the previously blocked transaction
    Then the response status should be 200
    And available_credit is updated accordingly
    When I submit an invalid OTP before success in a new attempt
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'

  @api @realtime
  Scenario: WebSocket Live Feed Resilience and Authorization
    Given I connect to the WebSocket with Authorization: Bearer <access_token> and subscribe to 'account:<account_id>:transactions'
    Then I receive a subscription ack
    When I POST a CAD PURCHASE to '/accounts/<account_id>/transactions'
    Then a single WebSocket event is received with masked PAN and correct amounts
    When I keep the socket open until JWT expiry and send a ping
    Then the server closes the connection or emits an unauthorized event
    When I POST '/auth/token/refresh' to obtain a new access_token and reconnect the socket and resubscribe
    Then I receive a new subscription ack and heartbeats
    When I attempt to subscribe to 'account:<other_account_id>:transactions'
    Then subscription is rejected with 403 FORBIDDEN and no events delivered
    When I attempt to pass JWT in query string on connect
    Then the connection is rejected
    And all frames remain over TLS 1.3 without downgrade

  @api @card
  Scenario: Card Controls Freeze/Unfreeze with OTP and CSRF, Transactions Blocked While Frozen
    Given account summary shows card is Active
    When I PATCH '/cards/<card_id>/status' to Frozen with headers 'X-CSRF-Token' and JSON payload
      """
      {"status":"Frozen","reason":"Travel","confirm_otp":"<valid_otp>"}
      """
    Then the response status should be 200
    And 'new_status' is 'Frozen'
    When I POST '/accounts/<account_id>/transactions' while card is Frozen
    Then the response status should be 403
    And the error code should be 'CARD_INACTIVE'
    When I PATCH '/cards/<card_id>/status' to Active with valid OTP and CSRF
    Then the response status should be 200
    And 'new_status' is 'Active'
    When I attempt unfreeze with wrong OTP
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'

  @api @card
  Scenario: Report Card STOLEN with Delivery Address Override, OTP, Audit, Irreversibility
    Given card is Active and masked PAN is visible in summary only
    When I POST '/cards/<card_id>/report-lost' without 'X-CSRF-Token'
      """
      {"loss_type":"STOLEN"}
      """
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'
    When I POST '/auth/otp/request' with JSON payload
      """
      {"channel":"SMS","purpose":"CARD_REPORT_STOLEN"}
      """
    And I POST '/cards/<card_id>/report-lost' with headers 'X-CSRF-Token' and JSON payload
      """
      {
        "loss_type":"STOLEN",
        "confirm_otp":"<valid_otp>",
        "delivery_address":{"street":"123 King","city":"Toronto","province":"Ontario","postal_code":"12345"}
      }
      """
    Then the response status should be 400
    And address validation errors for 'province' and 'postal_code' are returned
    When I POST '/cards/<card_id>/report-lost' with valid address override and last_known_use
      """
      {
        "loss_type":"STOLEN",
        "confirm_otp":"<valid_otp>",
        "delivery_address":{"street":"123 King","city":"Toronto","province":"ON","postal_code":"A1A 1A1"},
        "last_known_use":"2026-03-01T12:00:00Z"
      }
      """
    Then the response status should be 200
    And 'blocked_card_id','new_card_eta','case_number' are present
    When I PATCH '/cards/<card_id>/status' to Active or Frozen after Blocked
    Then the response status should be 400
    And the error code should be 'INVALID_TRANSITION'
    When I PUT '/cards/<card_id>/pin' while Blocked
      """
      {"new_pin":"1234","confirm_pin":"1234","session_otp":"<valid_otp>"}
      """
    Then the response status should be 403
    And the error code should be 'CARD_BLOCKED'
    When I POST '/cards/<card_id>/report-lost' again
    Then the response status should be 409
    And the error code should be 'ALREADY_BLOCKED'

  @api @payments @billing
  Scenario: Payments, Late Fee, Interest/Grace, Scheduling, CSRF, Rescind Window
    Given I GET '/accounts/<account_id>/statements/<statement_id>' and capture due_date, minimum_payment_due, total_balance
    When system time is advanced to due_date + 3 days and I GET the statement
    Then 'late_fee' equals 35.00
    When I POST '/accounts/<account_id>/payments' with 'X-CSRF-Token' and JSON payload
      """
      {"payment_type":"MINIMUM","payment_amount":49.99,"bank_account_id":"00000000-0000-0000-0000-000000000000"}
      """
    Then the response status should be 422
    And the error code should be 'INVALID_BANK_ACCOUNT'
    When I POST '/accounts/<account_id>/payments' with JSON payload
      """
      {"payment_type":"MINIMUM","payment_amount":45.00,"bank_account_id":"11111111-2222-3333-4444-555555555555"}
      """
    Then the response status should be 400
    And the error code should be 'BELOW_MINIMUM'
    When I POST a valid FULL_BALANCE payment
      """
      {"payment_type":"FULL_BALANCE","bank_account_id":"11111111-2222-3333-4444-555555555555"}
      """
    Then the response status should be 200
    And 'payment_id' is present
    When I POST a scheduled payment with past scheduled_date
      """
      {"payment_type":"CUSTOM","payment_amount":10.00,"scheduled_date":"2000-01-01","bank_account_id":"11111111-2222-3333-4444-555555555555"}
      """
    Then the response status should be 400
    And the error code should be 'INVALID_SCHEDULED_DATE'
    When I POST '/auth/token/refresh' and then POST '/auth/token/refresh' again using the same refresh token
    Then the second response status should be 401
    And the error code should be 'TOKEN_INVALID'
    When I POST '/accounts/<id>' DELETE to exercise Right to Rescind within 14 days with 'X-CSRF-Token'
    Then the response status should be 200
    And subsequent GET '/accounts/<account_id>/summary' returns 404 or 403

  @api @payments
  Scenario Outline: Payments CUSTOM Boundary and CSRF
    Given total_balance and an active bank_account_id are known
    When I POST '/accounts/<account_id>/payments' with headers '<csrf_header>' and JSON payload
      """
      {"payment_type":"CUSTOM","payment_amount":<amount>,"bank_account_id":"<bank_id>","scheduled_date":<scheduled>}
      """
    Then the response status should be <status>
    And the error code should be '<error_code>'

    Examples:
      | csrf_header    | amount  | bank_id                                 | scheduled       | status | error_code           |
      | X-CSRF-Token   | 1.00    | 11111111-2222-3333-4444-555555555555    | null            | 200    |                      |
      | X-CSRF-Token   | 0.999   | 11111111-2222-3333-4444-555555555555    | null            | 400    | SCALE_INVALID        |
      | X-CSRF-Token   | <tb+0.01>| 11111111-2222-3333-4444-555555555555   | null            | 400    | ABOVE_MAX            |
      | X-CSRF-Token   | <tb>    | 11111111-2222-3333-4444-555555555555    | "tomorrow"      | 200    |                      |
      | (missing)      | 5.00    | 11111111-2222-3333-4444-555555555555    | null            | 403    | CSRF_MISSING         |

  @api @statements
  Scenario: Statement Calculations Boundary: Interest Rounding, Grace, Late Fee UTC Boundary, Not Found
    Given I GET the previous statement to read 'prev_statement_balance_paid_in_full' and 'due_date'
    When I set prev_statement_balance_paid_in_full to true and GET current statement after cycle close
    Then 'interest_charged' equals 0
    When I set prev_statement_balance_paid_in_full to false with $0.01 remainder and GET current statement
    Then 'interest_charged' matches (ADB × APR / 365) × Days formula rounded to cents
    And 'total_spend' equals the sum of transactions within ±0.01
    When payment_received_date is exactly due_date + 2 days 23:59:59Z and I GET recalculated statement
    Then 'late_fee' equals 0
    When payment_received_date is due_date + 2 days + 1 second and I GET recalculated statement
    Then 'late_fee' equals 35.00
    When I GET '/accounts/<account_id>/statements/<nonexistent_statement_id>'
    Then the response status should be 404

  @api @applications
  Scenario: Application Step Order Enforcement, Session Token Validation, PENDING and DECLINED
    Given userA starts Step 1 via POST '/applications/start' and receives application_id_A and session_token_A
    When userA POSTs '/applications/<application_id_A>/submit' skipping Step 2 with valid e_signature
    Then the response status should be 400
    And the error code should be 'INVALID_STEP_ORDER'
    When userA POSTs '/applications/<application_id_A>/financials' with tampered 'X-App-Session'
    Then the response status should be 401
    And the error code should be 'SESSION_EXPIRED'
    When userA POSTs Step 2 with employment_status EMPLOYED but missing employer_name
    Then the response status should be 400
    When corrected Step 2 is submitted with sin_consent true and bureau is configured for FICO=620
    Then the response status should be 200
    And status is 'PENDING_REVIEW'
    When userA submits Step 3 with valid e_signature and marketing_opt_in omitted
    Then decision is 'PENDING' and marketing_opt_in defaults to false
    When userB completes Step 1 and Step 2 with FICO=580 and submits Step 3 with malformed e_signature
    Then the response status should be 400
    And the error code should be 'SIGNATURE_REQUIRED'
    When userB corrects e_signature and resubmits
    Then the decision is 'DECLINED' with 'reason_code'
    When userB attempts to start another application immediately
    Then the response status should be 409 or 201 per business rule
    And no cross-user data leakage occurs

  @api @applications
  Scenario: Application Step 2 Credit Pull: sin_consent Enforcement, 503 Retry Idempotency, Session Expiry
    Given application_id and session_token for user@example.com are available
    When I POST Step 2 with EMPLOYED and missing employer_name
    Then the response status should be 400
    And field 'employer_name' is required
    When I POST Step 2 with employer_name but sin_consent=false
    Then the response status should be 400
    And error indicates sin_consent must be true
    When I POST Step 2 valid and bureau returns 503
    Then the response status should be 200
    And status is 'PENDING_REVIEW' with a 'fico_pull_id' queued
    When I resubmit identical Step 2
    Then the response status should be 200
    And the same 'fico_pull_id' is returned (idempotent)
    When I POST Step 2 with a tampered X-App-Session
    Then the response status should be 401
    And the error code should be 'SESSION_EXPIRED'
    When the session_token expires and I retry Step 2
    Then the response status should be 401
    And the error code should be 'SESSION_EXPIRED'
    When I obtain a fresh session_token and submit Step 2 then Step 3 with FICO=650
    Then the decision is 'PENDING'

  @api @applications @privacy
  Scenario: Application Step 1 Validation, Autosave Privacy and Cross-User Isolation
    Given userA is logged in with CSRF token and opens Step 1
    When userA POSTs Step 1 with email userB@example.com
    Then the response status should be 400
    And error 'email must match authenticated user'
    When userA POSTs Step 1 with invalid province 'Ontario'
    Then the response status should be 400
    And field 'address.province' invalid
    When userA POSTs Step 1 with invalid postal_code '12345'
    Then the response status should be 400
    And field 'address.postal_code' invalid
    When userA POSTs Step 1 with id_type 'NATIONAL_ID'
    Then the response status should be 400
    When userA POSTs Step 1 with id_type DRIVERS_LICENSE and overlength id_number
    Then the response status should be 400
    When userA submits valid Step 1
    Then the response status should be 201
    And 'application_id' and 'session_token' are returned
    When autosave triggers and the page reloads
    Then only non-sensitive fields are restored and no ssn_last4 or tokens appear in DOM/storage
    When userA logs out and userB logs in
    Then userB sees no draft from userA
    When userB attempts to POST '/applications/start' again immediately
    Then the response status should be 409
    And the error code should be 'DUPLICATE_APPLICATION'
    When userA attempts to POST '/applications/start' again
    Then the response status should be 409
    And no cross-user leakage of application_id is observed

  @api @webhook @notifications
  Scenario: Notifications Webhook Validation, PII Masking, Severity Rendering
    Given the notifications webhook endpoint is reachable
    When I POST '/notifications/webhook' with JSON payload
      """
      {"account_id":"<account_id>","alert_type":"UNKNOWN_EVENT","channel":"IN_APP","message_body":"Test","severity":"INFO","idempotency_key":"<uuid1>"}
      """
    Then the response status should be 400
    And the error code should be 'INVALID_ALERT_TYPE'
    When I POST '/notifications/webhook' with invalid channel
      """
      {"account_id":"<account_id>","alert_type":"LATE_PAYMENT","channel":"PAGER","message_body":"Test","severity":"INFO","idempotency_key":"<uuid2>"}
      """
    Then the response status should be 400
    When I POST a valid STATEMENT_READY IN_APP alert
      """
      {"account_id":"<account_id>","alert_type":"STATEMENT_READY","channel":"IN_APP","message_body":"Your statement is ready","severity":"INFO","idempotency_key":"<uuid3>"}
      """
    Then the response status should be 200
    When I POST an OVER_LIMIT EMAIL alert with masked PAN
      """
      {"account_id":"<account_id>","alert_type":"OVER_LIMIT","channel":"EMAIL","message_body":"Over-limit used on card **** **** **** 1234","severity":"WARNING","idempotency_key":"<uuid4>"}
      """
    Then the response status should be 200
    When I POST a FRAUD_FLAG IN_APP alert containing a PAN-like string
      """
      {"account_id":"<account_id>","alert_type":"FRAUD_FLAG","channel":"IN_APP","message_body":"Suspicious charge on card 4111 1111 1111 1111 at Merchant X","severity":"CRITICAL","idempotency_key":"<uuid5>"}
      """
    Then the response status should be 200
    And stored/rendered message masks to '**** **** **** 1111'
    When I POST an alert with message_body > 500 chars
    Then the response status should be 400
    When I resend STATEMENT_READY with a different idempotency_key and same content
    Then a distinct alert is created

  @api @transactions
  Scenario: Transaction Currency and Field Validation with Success at Precision Boundaries
    Given available_credit baseline is recorded
    When I POST with invalid currency_code
      """
      {"transaction_amount":10.00,"currency_code":"USDX","exchange_rate":1.250000,"mcc_code":3000,"merchant_name":"A","merchant_id":"B","transaction_type":"PURCHASE"}
      """
    Then the response status should be 400
    When I POST with USD and zero exchange_rate
      """
      {"transaction_amount":5.00,"currency_code":"USD","exchange_rate":0.000000,"mcc_code":3000,"merchant_name":"A","merchant_id":"B","transaction_type":"PURCHASE"}
      """
    Then the response status should be 400
    When I POST with USD and negative exchange_rate
      """
      {"transaction_amount":5.00,"currency_code":"USD","exchange_rate":-1.230000,"mcc_code":3000,"merchant_name":"A","merchant_id":"B","transaction_type":"PURCHASE"}
      """
    Then the response status should be 400
    When I POST with CAD amount scale > 2
      """
      {"transaction_amount":10.999,"mcc_code":5999,"merchant_name":"A","merchant_id":"B","transaction_type":"PURCHASE"}
      """
    Then the response status should be 400
    When I POST a valid EUR FX at max precision
      """
      {"transaction_amount":2.50,"currency_code":"EUR","exchange_rate":0.999999,"mcc_code":3000,"merchant_name":"EuroTravel","merchant_id":"ET001","transaction_type":"PURCHASE"}
      """
    Then the response status should be 200
    And 'foreign_fee_amount' and 'total_cad' are correctly rounded and available_credit decremented
    When I GET '/accounts/<account_id>/transactions?category=GIFT'
    Then the response status should be 400
    When I GET '/accounts/<account_id>/transactions?category=PURCHASE&page=1&per_page=25'
    Then the response status should be 200
    When I GET '/accounts/<other_account_id>/transactions'
    Then the response status should be 403

  @api @csrf @auth
  Scenario: CSRF Regeneration After Refresh Rotation
    Given I GET '/auth/csrf' and store CSRF-0
    When I POST '/accounts/<account_id>/transactions' with CSRF-0
      """
      {"transaction_amount":1.00,"mcc_code":5999,"merchant_name":"T","merchant_id":"T01","transaction_type":"PURCHASE"}
      """
    Then the response status should be 200
    When I POST '/auth/token/refresh'
    Then the response status should be 200
    When I PUT '/cards/<card_id>/pin' using stale CSRF-0
      """
      {"new_pin":"1234","confirm_pin":"1234","session_otp":"<valid_otp>"}
      """
    Then the response status should be 403
    And the error code should be 'CSRF_INVALID' or 'CSRF_MISSING'
    When I GET '/auth/csrf' and store CSRF-1
    Then CSRF-1 differs from CSRF-0
    When I PUT '/cards/<card_id>/pin' with CSRF-1 and mismatched pins
      """
      {"new_pin":"1234","confirm_pin":"4321","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    And the error code should be 'PIN_MISMATCH'
    When I PATCH '/cards/<card_id>/status' to Frozen with CSRF-1 and valid OTP
      """
      {"status":"Frozen","confirm_otp":"<valid_otp>"}
      """
    Then the response status should be 200
    When I POST '/auth/token/refresh' reusing the previous refresh token
    Then the response status should be 401
    And the error code should be 'TOKEN_INVALID'
    When I PATCH '/cards/<card_id>/status' to Active with CSRF-1 and valid OTP
    Then the response status should be 200

  @api @otp
  Scenario: Phone OTP Verification Flow with Expiry, Resend Throttle, Attempts Remaining
    Given I POST '/auth/otp/request' with
      """
      {"channel":"SMS","purpose":"PHONE_VERIFY"}
      """
    Then the response status should be 200
    When I POST '/auth/otp/verify' with non-numeric code
      """
      {"code":"12A45B"}
      """
    Then the response status should be 400
    When I POST '/auth/otp/verify' with wrong code '000000'
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'
    When I POST '/auth/otp/request' twice within 60 seconds
    Then the second response status should be 429 or 400 per throttle policy
    When I wait for expiry and POST '/auth/otp/verify' with an expired but correct code
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'
    When I POST '/auth/otp/request' again and then verify with the new correct code
    Then the response status should be 200
    And 'phone_verified' is true
    When I reuse the same OTP code again
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'

  @api @pin
  Scenario: Web-Based PIN Set Edge Cases: Numeric Format, Leading Zeros, OTP Expiry, Attempts Throttle, CSRF
    Given card is not Blocked and I have a valid session
    When I PUT '/cards/<card_id>/pin' without 'X-CSRF-Token'
      """
      {"new_pin":"1234","confirm_pin":"1234","session_otp":"<valid_otp>"}
      """
    Then the response status should be 403
    And the error code should be 'CSRF_MISSING'
    When I PUT with whitespace in PIN
      """
      {"new_pin":"12 4","confirm_pin":"12 4","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    And the error code should be 'PIN_FORMAT'
    When I PUT with non-numeric PIN
      """
      {"new_pin":"12A4","confirm_pin":"12A4","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    And the error code should be 'PIN_FORMAT'
    When I PUT with 3-digit PIN and then 5-digit PIN
      """
      {"new_pin":"123","confirm_pin":"123","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    When I PUT with 5-digit PIN
      """
      {"new_pin":"12345","confirm_pin":"12345","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    When I PUT with leading zeros but expired OTP
      """
      {"new_pin":"0000","confirm_pin":"0000","session_otp":"<expired_otp>"}
      """
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'
    When I request a fresh OTP and PUT with mismatched confirm_pin
      """
      {"new_pin":"0000","confirm_pin":"0001","session_otp":"<valid_otp>"}
      """
    Then the response status should be 400
    And the error code should be 'PIN_MISMATCH'
    When I submit two more attempts with wrong OTPs until attempts throttle
    Then the response status should be 401
    And the error code should be 'OTP_FAILED'
    When after cooldown I PUT with valid OTP and matching '0000'
    Then the response status should be 200
    And no PIN or OTP appears in any UI or storage

  @api @admin @audit
  Scenario: Audit Trail for Credit Limit Changes and Access Control
    Given as cardholder I GET '/accounts/<account_id>/summary' and record L0, A0, B0
    When as admin I PATCH '/admin/accounts/<account_id>/credit-limit' with
      """
      {"credit_limit": "<L0_plus_1000>"}
      """
    Then the response status should be 200
    When as cardholder I GET '/accounts/<account_id>/summary'
    Then 'credit_limit' equals L0+1000 and 'available_credit' increased accordingly
    When as admin I GET '/admin/audit?entity=credit_limit&account_id=<account_id>'
    Then an audit record exists with old_value L0 and new_value L0+1000 and immutable metadata
    When as cardholder I GET the same audit endpoint
    Then the response status should be 403
    And the error code should be 'FORBIDDEN'
    When as cardholder I try PATCH '/accounts/<account_id>/credit-limit'
    Then the response status should be 404 or 403
    And PAN masking is enforced in any payloads
    When as admin I patch credit_limit down by 500 and re-check summary and audit
    Then a second immutable audit entry exists and summary reflects the new limit

  @api @rescind @realtime
  Scenario: Right to Rescind Security Sweep Post-Delete
    Given the account is within 14 days of issuance and Active
    And I have an active WebSocket subscription to 'account:<account_id>:transactions'
    When I POST a small PURCHASE and observe one realtime event
    Then the event contains masked PAN only
    When I DELETE '/accounts/<id>' with 'X-CSRF-Token'
    Then the response status should be 200
    When I GET '/accounts/<account_id>/summary' after rescind
    Then the response status should be 404 or 403
    When I POST '/accounts/<account_id>/transactions' after rescind
    Then the response status should be 403
    When I POST '/accounts/<account_id>/payments' after rescind
    Then the response status should be 403
    And the WebSocket is terminated or receives an unauthorized event
    When I POST '/notifications/webhook' targeting the rescinded account
      """
      {"account_id":"<account_id>","alert_type":"STATEMENT_READY","channel":"IN_APP","message_body":"Test","severity":"INFO","idempotency_key":"<uuidX>"}
      """
    Then the response is a safe suppression (404 or 200 no-op) and no in-portal alert appears
    When I DELETE '/accounts/<id>' again
    Then the response is idempotent (404 NOT_FOUND or 409 ALREADY_CLOSED)

  # UI Tests

  @ui @session
  Scenario: Session Timeout Warning - Stay Signed In Flow and Auto-Logout
    Given I am on the portal and logged in with MFA with Secure, HttpOnly, SameSite=Strict cookies set
    And I have an active application Step 1 draft saved
    When I remain idle for 13 minutes
    Then I should see a session-timeout warning modal with 2-minute countdown
    When I click the 'Stay Signed In' button
    Then my session should remain active and a silent token refresh should occur
    And I can proceed to Step 2 without re-authenticating
    When I reload the page
    Then non-sensitive draft fields should be restored and ssn_last4 should not be present in localStorage or the DOM
    When I ignore the warning on a subsequent cycle and remain idle past 15 minutes
    Then I should be logged out automatically
    And any protected API requests should result in 401

  @ui @pci
  Scenario: PAN Masking and Iframe Tokenization Compliance Across Portal Surfaces
    Given I am on the account dashboard
    Then I should see the card number masked as '**** **** **** 1234'
    And no full PAN appears in any DOM element or data attribute
    When I open browser devtools and review Network responses
    Then no API response contains a full PAN and caching does not store PAN
    And localStorage and sessionStorage contain no PAN, ssn_last4, or tokens
    When I navigate to card management
    Then any card input fields are within a third-party iframe tokenization component loaded over TLS 1.3
    And the host page never receives raw PAN
    When a WebSocket transaction event arrives
    Then the payload shows masked PAN only and no tokens or PII
    When I open the latest statement JSON and PDF
    Then no full PAN is present in either format
    When a notification is rendered that originally contained a PAN-like string
    Then the UI displays a masked PAN and no full PAN appears anywhere
    And CSP headers restrict iframe/script sources appropriately
