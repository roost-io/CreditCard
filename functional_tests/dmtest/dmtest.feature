Feature: EvolvePay core user journeys and compliance coverage

  # Shared environment setup for both UI and API tests
  Background:
    Given the EvolvePay test environment is available
    And the API base URL is configured in environment variable 'API_BASE_URL'
    And a clean test browser session is started

  # UI Tests

  @ui @registration @authentication @tier-status
  Scenario Outline: New user registration and immediate login shows Tier 1 status
    Given I am on the Registration screen
    When I enter email "<email>" and password "<password>" on the Registration form
    And I submit the registration form
    And I navigate to the Login screen if not auto-directed
    And I log in with email "<email>" and password "<password>"
    And I navigate to the Profile page
    Then I should see the Verification Status value exactly "<expected_status>"
    And I sign out and should return to a public state

    Examples:
      | email                     | password       | expected_status |
      | test+reg01@example.com    | P@ssw0rd!123   | Tier 1          |
      | test+reg03@example.com    | P@ssw0rd!123   | Tier 1          |

  @ui @registration @negative
  Scenario Outline: Registration requires both email and password
    Given I am on the Registration screen
    When I enter email "<email_input>" and password "<password_input>" on the Registration form
    And I submit the registration form
    Then I should see a validation error indicating "<expected_error>"
    And I navigate to Login and attempt to log in with "<login_email>" and any password
    Then I should remain unauthenticated on the Login page

    Examples:
      | email_input               | password_input | expected_error      | login_email               |
      |                           | P@ssw0rd!123   | Email is required   | test+reg02@example.com    |
      | test+reg02@example.com    |                | Password is required| test+reg02@example.com    |

  @ui @authentication @session
  Scenario: Existing registered user can log in, maintain session, and sign out
    Given I am on the Login screen
    When I log in with email "test+auth01@example.com" and password "P@ssw0rd!123"
    Then I should land on the dashboard
    When I navigate to the Profile page
    Then I should remain authenticated
    When I refresh the page
    Then my session should persist
    When I navigate to another authenticated page "Card"
    Then the page should load normally
    When I sign out
    Then I should be redirected to the Login page and cannot access Profile via back navigation

  @ui @authentication @negative
  Scenario Outline: Unregistered users cannot log in
    Given I am on the Login screen
    When I log in with email "<unknown_email>" and password "WrongPass!234"
    Then I should see an authentication error and remain on the Login page
    When I navigate directly to Profile via deep link
    Then I should be redirected back to Login

    Examples:
      | unknown_email                      |
      | test+auth02-unknown@example.com    |
      | test+auth02-unknown2@example.com   |

  @ui @kyc @document-upload
  Scenario Outline: KYC submission validation for passport/selfie, unsupported types, and selfie required
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to the KYC submission form
    When I select document type "<doc_type>"
    And I upload document image file "<doc_image_path>"
    And I upload selfie image file "<selfie_image_path>"
    And I submit the KYC application
    Then I should see "<expected_ui_outcome>"
    And I navigate to the Profile page
    Then my verification status should reflect "<expected_profile_state>"
    And I sign out

    Examples:
      | email                     | password     | doc_type         | doc_image_path                | selfie_image_path             | expected_ui_outcome               | expected_profile_state |
      | test+kyc01@example.com    | P@ssw0rd!123 | Passport         | /tmp/passport_kyc01.png       | /tmp/selfie_kyc01.png         | Submission accepted               | Pending               |
      | test+kyc03@example.com    | P@ssw0rd!123 | Student ID       | /tmp/studentid_kyc03.png      | /tmp/selfie_kyc03.png         | Validation error: unsupported doc | Tier 1                |
      | test+kyc04@example.com    | P@ssw0rd!123 | Passport         | /tmp/passport_kyc04.png       |                               | Validation error: selfie required | Tier 1                |

  @ui @kyc @tier2 @status-transition
  Scenario: Tier 2 status after completing full KYC with government ID
    Given I am logged in as "test+kyc05@example.com" with password "P@ssw0rd!123"
    And I navigate to the Profile page
    Then I should see the Verification Status value exactly "Tier 1"
    When I navigate to the KYC submission form
    And I select document type "Driver's license"
    And I upload document image file "/tmp/license_kyc05.png"
    And I upload selfie image file "/tmp/selfie_kyc05.png"
    And I submit the KYC application
    Then I should see a submission acknowledgment
    When I navigate to the Profile page and wait for verification to complete
    Then I should see the Verification Status value exactly "Tier 2"
    And I sign out

  @ui @profile @status-display @enumeration
  Scenario Outline: Profile shows only allowed verification status values
    Given I am on the Login screen
    When I log in with email "<email>" and password "<password>"
    And I navigate to the Profile page
    Then I should see the Verification Status value exactly "<expected_status>"
    And no unsupported status strings are displayed
    And I sign out

    Examples:
      | email                          | password     | expected_status |
      | tier1_user+01@example.com      | ****         | Tier 1          |
      | pending_user+02@example.com    | ****         | Pending         |
      | tier2_user+03@example.com      | ****         | Tier 2          |

  @ui @virtual-card @eligibility
  Scenario Outline: Virtual prepaid card application access by user state/tier
    Given I start from a "<user_state>" session
    When I navigate to the Virtual Prepaid Card section
    Then the option to apply should be "<availability>"
    When I attempt to apply if available and confirm when "<submit>" is "true"
    Then I should see the outcome "<expected_outcome>"
    And I log out if authenticated

    Examples:
      | user_state      | availability | submit | expected_outcome              |
      | unauthenticated | hidden       | false  | Access blocked (login needed) |
      | tier1           | visible      | true   | Application accepted          |
      | tier2           | visible      | false  | Flow accessible               |

  @ui @physical-card @authorization
  Scenario Outline: Physical prepaid card ordering is allowed only for Tier 2
    Given I am logged in as "<email>" with password "<password>"
    When I navigate to Card Management and look for "Order physical prepaid card"
    Then the option should be "<visibility>"
    When I attempt to proceed if visible and confirm when "<should_submit>" is "true"
    Then I should see "<expected_result>"
    And I sign out

    Examples:
      | email                       | password | visibility | should_submit | expected_result                               |
      | tier1_user+01@example.com   | ****     | hidden     | false         | Action blocked/unavailable for Tier 1         |
      | tier2_user+03@example.com   | ****     | visible    | true          | Order accepted for mailing to user address    |

  @ui @physical-card @tier-gating @kyc
  Scenario: Tier 1 blocked from physical card order until KYC completes, then access enabled
    Given I am logged in as "test+t1@example.com" with password "****"
    When I navigate to Card Management > Physical Card
    Then I should not be able to initiate an order (blocked for Tier 1)
    When I navigate to Profile and confirm Verification Status is "Tier 1"
    And I complete KYC by selecting "passport", uploading "doc_passport_test.png" and "selfie_test.png", and submitting
    And I wait until the Profile shows Verification Status "Tier 2"
    When I navigate back to Card Management > Physical Card
    Then I should be able to start the order flow
    And I cancel the flow and sign out

  @ui @topup @transactions
  Scenario Outline: Top-up behavior with and without a linked bank account
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to Card > Details and record the current balance as "<balance_alias>"
    When I go to Card > Top-Up
    Then the linked bank account list should be "<funding_availability>"
    When I select funding source "<funding_source>" if available
    And I enter the top-up amount "<amount>" and confirm if "<can_proceed>" is "true"
    Then the top-up outcome should be "<expected_outcome>"
    And I return to Card > Details and verify the balance change "<balance_change_expectation>"
    And I check Recent Transactions reflects the top-up when "<should_create_txn>" is "true"
    And I sign out

    Examples:
      | email                         | password | balance_alias | funding_availability | funding_source          | amount | can_proceed | expected_outcome            | balance_change_expectation | should_create_txn |
      | test+t2@example.com           | ****     | B             | available            | Test Bank ••••1234      | 25.00  | true        | Success confirmation shown  | increases by $25.00        | true              |
      | test+t1topup@example.com      | ****     | B1            | available            | Test Bank ••••1234      | 10.00  | true        | Success confirmation shown  | increases by $10.00        | true              |
      | test+nolink@example.com       | ****     | B0            | unavailable          |                          | 20.00  | false       | Cannot proceed (blocked)    | unchanged                  | false             |

  @ui @balance @transactions
  Scenario: User can check current balance and view a non-empty recent transactions list
    Given I am logged in as "test+bal01@example.com" with password "****"
    When I navigate to Card > Details
    Then I should see the current balance displayed
    When I click "Recent Transactions"
    Then I should see a non-empty list of recent transactions
    And I can scroll the list without errors
    And I navigate back to Card > Details and still see the balance
    And I sign out

  @ui @transactions
  Scenario: A top-up transaction appears in recent transactions and increments count by one
    Given I am logged in as "test+txn02@example.com" with password "****"
    And I navigate to Card > Recent Transactions and record the count as N
    When I go to Card > Top-Up and select funding source "Test Bank ••••1234" and enter amount "12.34" and confirm
    Then I should see a success confirmation
    When I return to Card > Recent Transactions
    Then the list count should be N+1 and the most recent item should correspond to the top-up
    And I sign out

  @ui @transactions @pagination @boundary
  Scenario Outline: Transaction history pagination boundaries at various total counts
    Given I am logged in as "<email>" with password "****"
    When I navigate to Card > Transaction History
    Then I should see exactly "<page1_count>" items on page 1
    And pagination controls should be "<pagination_visible>"
    When I navigate to page 2 if "<has_page2>" is "true"
    Then I should see exactly "<page2_count>" items on page 2
    And navigating back to page 1 should still show "<page1_count>" items
    And I sign out

    Examples:
      | email                      | page1_count | pagination_visible | has_page2 | page2_count |
      | test+hist01@example.com    | 25          | visible            | true      | 15          |
      | test+hist24@example.com    | 24          | hidden             | false     | 0           |
      | test+tx26@example.com      | 25          | visible            | true      | 1           |

  @ui @transactions @filtering
  Scenario Outline: Transaction history filtering by date range, type, and combined
    Given I am logged in as "<email>" with password "****"
    When I navigate to Card > Transaction History
    And I open Filters
    And I set Start Date "<start_date>" and End Date "<end_date>" if provided
    And I select Transaction Type "<txn_type>" if provided
    And I apply the filters
    Then I should see only transactions matching the applied "<filter_mode>" criteria
    And out-of-range or non-matching types should be excluded
    And I clear filters and should see the full list again
    And I sign out

    Examples:
      | email                          | start_date  | end_date    | txn_type | filter_mode          |
      | test+dtrange@example.com       | 2025-10-10  | 2025-10-20  |          | date-range-only      |
      | test+loadfilter@example.com    |             |             | load     | type-only            |
      | test+combo@example.com         | 2025-10-01  | 2025-10-31  | purchase | date-and-type-combo  |

  @ui @transactions @filtering @negative
  Scenario: Invalid transaction type filter value is rejected
    Given I am logged in as "test+typeinvalid@example.com" with password "****"
    When I navigate to Card > Transaction History and open Filters
    Then I should see only 'load', 'purchase', and 'refund' as transaction type options
    When I attempt to enter "chargeback" as a transaction type
    Then I should not be able to apply the filter and results remain unchanged
    When I select a valid type "purchase" and apply
    Then the list should filter to only "purchase" transactions
    And I clear filters and sign out

  @ui @transactions @filtering @pagination @boundary
  Scenario: Pagination remains 25 per page after applying filters with >25 matches
    Given I am logged in as "test+filterpagesize@example.com" with password "****"
    When I navigate to Card > Transaction History and open Filters
    And I set a date range that includes 40 'purchase' transactions
    And I select Transaction Type "purchase" and apply
    Then I should see exactly 25 items on page 1
    When I navigate to page 2
    Then I should see the remaining 15 items
    And I navigate back to page 1 and still see 25 items
    And I sign out

  @ui @card-security @block
  Scenario Outline: Block card from the app and verify immediate and persistent Blocked state
    Given I am logged in as "<email>" with password "****"
    And I navigate to Card details and confirm the card is currently Active
    When I open Card controls and tap "Block Card"
    And I confirm the block action
    Then the Card details view should immediately show status "Blocked"
    And the Blocked state should persist without manual refresh
    And after refresh/navigation, the card remains "Blocked"
    And the Block control should no longer be available
    And I sign out

    Examples:
      | email                          |
      | test+blocknow@example.com      |
      | test+blockstate@example.com    |
      | test.user+blk03@example.com    |

  @ui @card-details @balance
  Scenario: Card details view shows current balance equals seeded amount
    Given I am logged in as "test.user+bal01@example.com" with password "****"
    When I navigate to the Card details screen
    Then I should see Current balance equal to "$1,250.00"
    And on refresh the balance should remain "$1,250.00"
    And I sign out

  @ui @card-details @limits
  Scenario: Card details view shows daily load limit and remaining allowance
    Given I am logged in as "test.user+limit02@example.com" with password "****"
    When I navigate to the Card details screen
    Then I should see Daily load limit equal to "$2,000.00"
    And I should see Remaining allowance equal to "$1,500.00"
    And the values persist on refresh
    And I sign out

  @ui @card-details @limits @formatting @boundary
  Scenario Outline: Usage display exact formatting across typical and boundary states
    Given I am logged in as "<email>" with password "****"
    When I navigate to the Card details screen
    Then I should see the usage display text exactly "<expected_usage_string>"
    And I sign out

    Examples:
      | email                                | expected_usage_string                   |
      | test.user+usage03@example.com        | $500.00 / $2000.00 daily limit used     |
      | test.user+usageA04@example.com       | $0.00 / $2000.00 daily limit used       |
      | test.user+usageB04@example.com       | $2000.00 / $2000.00 daily limit used    |

  @ui @remittance @tier2
  Scenario: Tier 2 user can send money to an international recipient
    Given I am logged in as "test.user+t2send01@example.com" with password "****"
    When I navigate to Send Money
    And I select or add a beneficiary in Country "Kenya"
    And I enter amount "$100.00" and proceed to review
    And I confirm the transfer
    Then I should see a success acknowledgment
    And the remittance history should include an entry for this transfer

  @ui @remittance @authorization @negative
  Scenario: Tier 1 user is prevented from sending international remittances
    Given I am logged in as "test.user+t1deny02@example.com" with password "****"
    When I navigate to Send Money
    And I attempt to select/add a beneficiary and enter amount "$50.00"
    Then I should be blocked from reaching confirmation/submission
    And no remittance should be created in history
    And I sign out

  @ui @remittance @funds-source
  Scenario: Sending money debits the user's account balance
    Given I am logged in as "test.user+t2funds03@example.com" with password "****"
    And I navigate to Card details and record the Current balance as "$1,000.00"
    When I navigate to Send Money and select an international beneficiary
    And I enter amount "$200.00" and confirm the transfer
    Then I return to Card details and should see the balance equals "$800.00"

  @ui @remittance @country
  Scenario: Send flow supports selecting an international recipient country and shows it on review
    Given I am logged in as "test.user+t2country04@example.com" with password "****"
    When I navigate to Send Money and add beneficiary "Luis Test" with Country "Philippines" and account "placeholder"
    And I start a send to "Luis Test" for "$25.00" and proceed to review
    Then I should see the beneficiary Country displayed as "Philippines" on the review screen
    And I cancel to avoid creating a transfer

  @ui @beneficiaries @crud
  Scenario: Add beneficiary requires Full Name, Country, and Bank Account/Mobile Money and persists
    Given I am logged in as "test.user+ben01@example.com" with password "****"
    When I navigate to Remittance > Beneficiaries and add "Maria Example" with Country "Ghana" and Account/MM "MM-233-123456"
    Then I should see "Maria Example" in the beneficiaries list with correct details
    When I navigate to Send Money
    Then I should be able to select "Maria Example" as a beneficiary

  @ui @beneficiaries @crud @persistence
  Scenario: Saved beneficiary persists across logout/login
    Given I am logged in as "test+t2user@example.com" with password "******"
    When I navigate to Remittance > Beneficiaries and add "Asha K. Test" with Country "Kenya" and Account/MM "MM-****6789"
    Then I should see "Asha K. Test" in the list
    When I sign out and log back in as "test+t2user@example.com" with password "******"
    And I navigate to Remittance > Beneficiaries
    Then I should still see "Asha K. Test" in the list
    When I optionally delete "Asha K. Test"
    Then it should be removed from the list

  @ui @beneficiaries @crud @delete
  Scenario: A saved beneficiary can be deleted and remains deleted
    Given I am logged in as "test+t2user@example.com" with password "******"
    And I navigate to Remittance > Beneficiaries and confirm "Ben RemoveMe" exists
    When I delete "Ben RemoveMe" and confirm
    Then "Ben RemoveMe" should disappear from the list
    When I navigate to Send Money
    Then "Ben RemoveMe" should not be available for selection
    When I log out and back in as "test+t2user@example.com" with password "******"
    And I navigate to Remittance > Beneficiaries
    Then "Ben RemoveMe" should still be absent

  @ui @beneficiaries @validation @negative
  Scenario Outline: Saving a beneficiary is prevented when required fields are missing
    Given I am logged in as "test+t2user@example.com" with password "******"
    When I navigate to Remittance > Beneficiaries and open Add Beneficiary
    And I attempt to save a beneficiary with Full Name "<full_name>", Country "<country>", and Account/MM "<account>"
    Then saving should be blocked and no new record should appear in the list

    Examples:
      | full_name       | country | account        |
      |                 | India   | MM-****3344    |
      | No Account Case | Nigeria |                |

  @ui @remittance @disclosures
  Scenario: Exchange rate and any transaction fees are visible together on review before confirmation
    Given I am logged in as "test+t2user@example.com" with password "******"
    When I navigate to Remittance > Send Money and select beneficiary "Both Disclosures"
    And I enter a valid amount and proceed to Review
    Then I should see a clearly labeled exchange rate
    And I should see a clearly labeled transaction fee
    And both should be visible before any Confirm action
    And I cancel the flow

  @ui @remittance @history @pagination
  Scenario: Remittance history is paginated and navigable
    Given I am logged in as "test+t2user@example.com" with password "******"
    When I navigate to Remittance > History
    Then I should see a non-empty list of past transfers
    And I should see pagination controls
    When I navigate to the next page and then back
    Then I should see different sets of transfers per page and no errors on navigation
    And I sign out

  @ui @remittance @history @status
  Scenario: A Pending remittance appears in history with correct status label
    Given I am logged in as "test+t2user@example.com" with password "******"
    When I navigate to Remittance > History
    Then I should see at least one transfer labeled "Pending"
    And after refresh/navigation the "Pending" label should remain
    And I sign out

  @ui @remittance @history @pagination
  Scenario: Remittance history shows additional records across multiple pages (>=26 total)
    Given I am logged in as "test+t2_many@example.com" with password "****"
    When I navigate to Remittance > History
    Then I should see pagination controls
    And I should see a finite non-zero row count on page 1
    When I navigate to page 2
    Then I should see additional records and a finite non-zero row count on page 2
    And the combined rows across pages 1 and 2 should be at least 26
    And I sign out

  @ui @access-control @tier2
  Scenario: Tier 2 users unlock all platform features
    Given I am logged in as "test+unlock_all@example.com" with password "****"
    When I navigate to Profile
    Then I should see the Verification Status value exactly "Tier 2"
    When I navigate to Card > Order Physical
    Then the physical card order flow should be accessible
    When I return to the dashboard and navigate to Remittance > Send Money
    Then the remittance send flow should be accessible
    And I sign out

  # API Tests

  @api @auth
  Scenario Outline: Auth service registration and login validations
    Given the API base URL is available in 'API_BASE_URL'
    When I send a <method> request to "<endpoint>" with JSON payload
      """
      <payload>
      """
    Then the response status should be <status>
    And the response should contain fields "<expected_fields>"

    Examples:
      | method | endpoint              | payload                                                                 | status | expected_fields        |
      | POST   | /api/auth/register    | {"email":"test+reg01@example.com","password":"P@ssw0rd!123"}            | 201    | id,tier                |
      | POST   | /api/auth/register    | {"email":"test+reg02@example.com"}                                      | 400    | error                  |
      | POST   | /api/auth/login       | {"email":"test+auth01@example.com","password":"P@ssw0rd!123"}           | 200    | token,user.id,tier     |
      | POST   | /api/auth/login       | {"email":"test+auth02-unknown@example.com","password":"WrongPass!234"}  | 401    | error                  |

  @api @kyc
  Scenario Outline: KYC submission API accepts only supported doc types and requires selfie
    Given the API base URL is available in 'API_BASE_URL'
    And I am authenticated with bearer token for "<email>" and password "<password>"
    When I send a POST request to "/api/kyc/submissions" with JSON payload
      """
      {
        "documentType": "<doc_type>",
        "documentImageId": "doc_<case_id>",
        "selfieImageId": "<selfie_id>"
      }
      """
    Then the response status should be <status>
    And the response should contain fields "<expected_fields>"

    Examples:
      | email                   | password     | doc_type         | case_id | selfie_id        | status | expected_fields     |
      | test+kyc01@example.com  | P@ssw0rd!123 | passport         | kyc01   | selfie_kyc01     | 202    | id,status           |
      | test+kyc03@example.com  | P@ssw0rd!123 | student_id       | kyc03   | selfie_kyc03     | 400    | error               |
      | test+kyc04@example.com  | P@ssw0rd!123 | passport         | kyc04   |                  | 400    | error               |

  @api @cards @block
  Scenario: Blocking a card via API updates status to Blocked
    Given the API base URL is available in 'API_BASE_URL'
    And I am authenticated with bearer token for "test+blockstate@example.com" and password "****"
    When I send a POST request to "/api/cards/4242/block" with JSON payload
      """
      {}
      """
    Then the response status should be 200
    And the response should contain fields "cardId,status"
    When I send a GET request to "/api/cards/4242"
    Then the response status should be 200
    And the response JSON path "$.status" should equal "Blocked"

  @api @transactions @pagination @filtering
  Scenario Outline: Transaction history API supports pagination (25/page) and filtering
    Given the API base URL is available in 'API_BASE_URL'
    And I am authenticated with bearer token for "<email>" and password "****"
    When I send a GET request to "/api/cards/4242/transactions?type=<type>&startDate=<start>&endDate=<end>&page=<page>&size=25"
    Then the response status should be 200
    And the response JSON path "$.items.length" should equal <expected_count>
    And the response JSON path "$.page.size" should equal 25

    Examples:
      | email                       | type     | start      | end        | page | expected_count |
      | test+hist01@example.com     |          |            |            | 1    | 25             |
      | test+hist24@example.com     |          |            |            | 1    | 24             |
      | test+tx26@example.com       |          |            |            | 2    | 1              |
      | test+dtrange@example.com    |          | 2025-10-10 | 2025-10-20 | 1    | 2              |
      | test+loadfilter@example.com | load     |            |            | 1    | 25             |

  @api @remittance @authorization
  Scenario Outline: Remittance send API authorization by tier
    Given the API base URL is available in 'API_BASE_URL'
    And I am authenticated with bearer token for "<email>" and password "****"
    When I send a POST request to "/api/remittances" with JSON payload
      """
      {
        "beneficiaryId": "<beneficiary_id>",
        "sourceAccountId": "acc_0001",
        "amount": 100.00,
        "currency": "USD"
      }
      """
    Then the response status should be <status>
    And the response should contain fields "<expected_fields>"

    Examples:
      | email                          | beneficiary_id | status | expected_fields       |
      | test.user+t2send01@example.com | ben_t2_001     | 201    | id,status             |
      | test.user+t1deny02@example.com | ben_t1_001     | 403    | error                 |

  @api @beneficiaries @crud
  Scenario Outline: Beneficiaries API create and validation
    Given the API base URL is available in 'API_BASE_URL'
    And I am authenticated with bearer token for "<email>" and password "****"
    When I send a POST request to "/api/beneficiaries" with JSON payload
      """
      {
        "fullName": "<full_name>",
        "country": "<country>",
        "accountOrMobile": "<account>"
      }
      """
    Then the response status should be <status>
    And the response should contain fields "<expected_fields>"

    Examples:
      | email                     | full_name       | country     | account        | status | expected_fields |
      | test+t2user@example.com   | Asha K. Test    | Kenya       | MM-****6789    | 201    | id,fullName     |
      | test+t2user@example.com   |                 | India       | MM-****3344    | 400    | error           |
      | test+t2user@example.com   | No Account Case | Nigeria     |                | 400    | error           |
