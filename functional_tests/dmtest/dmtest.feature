Feature: EvolvePay - Registration, KYC, Cards, Transactions, Remittance, and Security

  # UI Tests

  @ui @registration @tier1
  Scenario Outline: Registration outcomes and immediate Tier 1 status
    Given I am on the Registration page
    When I enter email "<email>" in the Email field
    And I enter "<password>" in the Password field
    And I click the "Register" button
    Then I should <auth_result> be authenticated
    And I should <stay_on_reg> remain on the Registration page
    And I navigate to the "Profile" page <if_authed>
    And I should <see_status> see "Tier 1" as the Verification Status <status_context>
    And I should <no_kyc> not see any KYC artifacts yet
    And I log out if authenticated

    Examples:
      | email                      | password       | auth_result | stay_on_reg | if_authed               | see_status | status_context                                  | no_kyc |
      | test+reg01@example.com     | P@ssw0rd123!   |            |             | and the Profile is open | see        | after successful registration                    | should |
      |                            | P@ssw0rd123!   | not        | and I       |                         | not see    | because submission is blocked for missing email | should |

  @ui @login
  Scenario Outline: Secure login and profile access by tier
    Given I am on the Login page
    When I enter "<email>" in the Email field
    And I enter "<password>" in the Password field
    And I click the "Log In" button
    Then I should be authenticated
    And I navigate to the "Profile" page
    And I should see "<expected_tier>" as the Verification Status
    And I log out

    Examples:
      | email                       | password     | expected_tier |
      | test+auth01@example.com     | P@ssw0rd123! | Tier 1        |
      | test+auth02@example.com     | P@ssw0rd123! | Tier 2        |

  @ui @kyc
  Scenario Outline: KYC submission validation for Tier 1 user (Passport/Driver's License and selfie)
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to the "KYC submission" page
    When I select ID type "<idType>"
    And I upload the ID image "<idImage>" if provided
    And I upload the selfie image "<selfieImage>" if provided
    And I click the "Submit" button
    Then I should see "<ui_feedback>"
    And I navigate to the "Profile" page
    And I should see "<post_status>" as the Verification Status

    Examples:
      | email                      | password     | idType                    | idImage                 | selfieImage        | ui_feedback                         | post_status |
      | test+kyc01@example.com     | P@ssw0rd123! | Passport                  | sample-passport.jpg     | sample-selfie.jpg  | KYC submission received             | Pending     |
      | test+kyc03@example.com     | P@ssw0rd123! | Passport                  | sample-passport.jpg     |                    | A validation error for missing selfie | Tier 1     |
      | test+kyc04@example.com     | P@ssw0rd123! | National ID (unsupported) | sample-national-id.jpg  | sample-selfie.jpg  | ID type is not accepted             | Tier 1     |

  @ui @verification
  Scenario: Tier 2 (Verified) user sees Tier 2 status and can access Tier 2-only areas
    Given I am logged in as "test+ver03@example.com" with password "********"
    When I navigate to "Profile > Verification"
    Then I should see "Tier 2" as the Verification Status
    When I navigate to "Cards > Order Physical Card"
    Then the page should be accessible
    When I navigate to "Cards > Virtual"
    Then the virtual card Apply/Manage page should be accessible
    When I navigate to "Remittance > Send Money"
    Then the send flow entry screen should be accessible
    When I refresh the "Profile > Verification" page
    Then I should still see "Tier 2" as the Verification Status
    And I log out

  @ui @virtual-card
  Scenario Outline: Apply for a virtual prepaid card and verify immediate provisioning (Tier 1 and Tier 2)
    Given I am logged in as "<email>" with password "********"
    And I navigate to "Cards > Virtual"
    When I initiate the virtual card application
    And I confirm the application
    Then I should see a success confirmation
    And I navigate to "Card Details"
    And I should see a new virtual card entry listed immediately
    And I refresh the page
    Then the virtual card remains visible
    And I log out

    Examples:
      | email                        |
      | test+virt01@example.com      |
      | test+virt03@example.com      |
      | test+gate01-t1@example.com   |
      | test+gate01-t2@example.com   |

  @ui @physical-card @gating
  Scenario Outline: Physical card ordering gating (Tier 2 allowed, Tier 1 blocked)
    Given I am logged in as "<email>" with password "********"
    And I navigate to "Profile > Verification"
    Then I should see "<tier>" as the Verification Status
    When I navigate to "Cards > Order Physical Card"
    And I try to submit a physical card order
    Then I should see "<expected_outcome>"
    And I navigate to "Card Orders" or "Card Details"
    And I should <order_presence> see a physical card order entry
    And I log out

    Examples:
      | email                       | tier  | expected_outcome                      | order_presence |
      | test+phys01@example.com     | Tier 2 | Order submitted successfully           | see            |
      | test+phys02@example.com     | Tier 1 | Access is blocked for Tier 1 users     | not            |
      | test+gate02-t2@example.com  | Tier 2 | Order submitted successfully           | see            |
      | test+gate04-t1@example.com  | Tier 1 | Access is blocked for Tier 1 users     | not            |

  @ui @topup @balance
  Scenario Outline: Top-up completes successfully and balance reflects increase
    Given I am logged in as "<email>" with password "********"
    And I navigate to "Cards > Card Details"
    And I note the starting balance "<startingBalance>"
    When I click "Load Funds/Top-Up"
    And I enter a top-up amount of "<amount>"
    And I select a linked bank account
    And I confirm the top-up
    Then I should see a success indicator
    When I return to "Card Details" and refresh
    Then the balance should be "<expectedBalance>"
    And I open "Recent Transactions" and I should see entries listed
    And I log out

    Examples:
      | email                         | startingBalance | amount  | expectedBalance |
      | test+topup02@example.com      | $50.00          | $25.00  | $75.00          |

  @ui @balance @transactions
  Scenario: View current balance and at least 3 recent transactions (seeded)
    Given I am logged in as "test+bal01@example.com" with password "********"
    When I navigate to "Cards > Card Details"
    Then I should see the Balance equals "$1,250.00"
    And I should see a "Recent transactions" section with at least 3 items
    And the first three entries’ dates and amounts should match the seeded dataset
    And I navigate back to the dashboard

  @ui @transactions @pagination
  Scenario Outline: Transaction history pagination boundary counts
    Given I am logged in as "<email>" with password "********"
    When I navigate to "Transaction History"
    Then page 1 should display exactly <page1Count> items
    When I go to the next page if available
    Then page 2 should display exactly <page2Count> items
    When I go to the next page if available
    Then page 3 should display exactly <page3Count> items
    And there should <hasMore> be a page 3

    Examples:
      | email                        | page1Count | page2Count | page3Count | hasMore |
      | test+thist02@example.com     | 0          | 0          | 0          | not     |
      | test+thist03@example.com     | 1          | 0          | 0          | not     |
      | test+thist04@example.com     | 25         | 0          | 0          | not     |
      | test+thist05@example.com     | 25         | 1          | 0          | not     |
      | test+thist06@example.com     | 25         | 25         | 0          | not     |
      | test+thist01@example.com     | 25         | 25         | 1          | should  |

  @ui @transactions @filters
  Scenario Outline: Transaction type filter returns only matching results
    Given I am logged in as "test+thist08@example.com" with password "********"
    And I navigate to "Transaction History"
    When I set Type filter to "<type>"
    Then all listed transactions should be of type "<type>"
    And no transactions of other types should be present
    When I clear the Type filter
    Then a mixed set of Load, Purchase, and Refund should be visible

    Examples:
      | type     |
      | Load     |
      | Purchase |
      | Refund   |

  @ui @transactions @date-range
  Scenario Outline: Date range filter includes only in-range transactions and can yield empty results
    Given I am logged in as "test+thist10@example.com" with password "********"
    And I navigate to "Card > Transactions"
    When I apply the date range From "<from>" To "<to>"
    Then only the following dates should be visible: <visibleDates>
    And the following dates should not be visible: <notVisibleDates>

    Examples:
      | from        | to          | visibleDates                 | notVisibleDates |
      | 2026-01-10  | 2026-01-31  | 2026-01-10,2026-01-15        | 2026-02-05      |
      | 2026-02-01  | 2026-02-10  | 2026-02-05                   | 2026-01-10,2026-01-15 |
      | 2025-12-01  | 2025-12-31  | <empty>                      | 2026-01-10,2026-01-15,2026-02-05 |

  @ui @transactions @filters @empty
  Scenario: Combined date range and type filters can produce an empty result set
    Given I am logged in as "test+thist09@example.com" with password "********"
    And I navigate to "Card > Transactions"
    When I apply the date range From "2025-01-10" To "2025-01-12"
    And I set Type filter to "Refund"
    Then I should see 0 transactions in the list
    And pagination should indicate no additional pages
    When I clear all filters
    Then the original mixed transaction list should return

  @ui @security @block-card
  Scenario: Block card takes effect immediately and persists across navigation
    Given I am logged in as "test+block01@example.com" with password "********"
    And I navigate to "Cards > Card Details"
    And I confirm the card is currently "Active"
    When I click "Block Card" and confirm
    Then the card status should update to "Blocked" immediately
    When I navigate away and back to "Cards > Card Details"
    Then the card status should still be "Blocked"

  @ui @security @block-card
  Scenario: Blocked state persists after logout and re-login
    Given I am logged in as "test+block02@example.com" with password "********"
    And I navigate to "Cards > Card Details"
    And I confirm the card is currently "Active"
    When I click "Block Card" and confirm
    Then the card status should update to "Blocked" immediately
    When I log out and log back in as "test+block02@example.com" with password "********"
    And I navigate to "Cards > Card Details"
    Then the card status should be "Blocked"

  @ui @security @block-card
  Scenario Outline: Block Card action is available to users with a card regardless of tier (cancel to avoid state change)
    Given I am logged in as "<email>" with password "********"
    And I navigate to "Cards > Card Details"
    When I click "Block Card"
    Then a confirmation prompt should appear
    When I click "Cancel"
    Then the card status should remain "Active"
    And I log out

    Examples:
      | email                          |
      | test+block03_t1@example.com    |
      | test+block03_t2@example.com    |

  @ui @limits
  Scenario: Card details show balance, daily load limit, and remaining/used allowance in example format
    Given I am logged in as "test+limit01@example.com" with password "********"
    When I navigate to "Cards > Card Details"
    Then I should see a daily load usage string matching the pattern "$<used> / $<limit> daily limit used"
    And both values should be currency-formatted with two decimals
    When I refresh the page
    Then the same format should persist

  @ui @limits @topup
  Scenario: Used amount increases on card details after a $100 load within the daily limit
    Given I am logged in as "test+limit02@example.com" with password "********"
    And I navigate to "Cards > Card Details"
    And I note the current used amount "U" and daily limit "L"
    When I perform a top-up of "100.00" from a linked bank account
    And I return to "Cards > Card Details"
    Then the used amount should be "U + 100.00"
    And the remaining allowance should be "L - (U + 100.00)"

  @ui @limits @boundary
  Scenario: Remaining allowance shows correctly when no loads have been made today
    Given I am logged in as "test+limit03@example.com" with password "********"
    And I verify there are 0 load transactions for today in "Card > Transactions"
    When I navigate to "Cards > Card Details"
    Then the used amount should be "$0.00"
    And the remaining allowance should equal the daily limit

  @ui @remittance @tier-gating
  Scenario: Tier 2 user can send money to an international recipient
    Given I am logged in as "test+remit01_t2@example.com" with password "********"
    When I navigate to "Remittance > Send Money"
    And I add a beneficiary "Recipient Test" with Country "PH" and Destination "Bank Account ****7890"
    And I select the beneficiary "Recipient Test"
    And I enter amount "150.00" and proceed to review
    Then I should see the exchange rate and any transaction fees on the review screen
    When I confirm the transfer
    Then I should see a submission success acknowledgment

  @ui @remittance @tier-gating @negative
  Scenario: Tier 1 user is blocked from initiating an international remittance
    Given I am logged in as "test+remit02_t1@example.com" with password "********"
    When I attempt to navigate to "Remittance > Send Money"
    Then I should see access is restricted for Tier 1 and I cannot proceed to amount entry

  @ui @remittance @history
  Scenario: Newly sent transfer appears in remittance history with a valid status
    Given I am logged in as "test+remit03_t2@example.com" with password "********"
    When I navigate to "Remittance > Send Money"
    And I select beneficiary "Recipient Test/PH/Bank ****7890"
    And I enter amount "75.00" and confirm the transfer
    Then I navigate to "Remittance > History"
    And I should see a new entry for "75.00" to "Recipient Test/PH/Bank ****7890"
    And its status should be one of "Pending,Completed,Failed"

  @ui @beneficiaries @crud
  Scenario: Add and save a beneficiary with required fields
    Given I am logged in as "test+t2bene01@example.com" with password "Passw0rd!123"
    When I navigate to "Beneficiaries"
    And I click "Add Beneficiary"
    And I enter Full Name "Amina Rahman", Country "Kenya", Bank Account "1234567890"
    And I click "Save"
    Then I should see the beneficiary "Amina Rahman" with Country "Kenya" in the list
    When I open the beneficiary details for "Amina Rahman"
    Then the stored values should match the inputs

  @ui @beneficiaries @validation @negative
  Scenario Outline: Beneficiary save is blocked when required fields are missing
    Given I am logged in as "test+t2bene03@example.com" with password "Passw0rd!123"
    And I navigate to "Beneficiaries"
    When I click "Add Beneficiary"
    And I enter Full Name "<fullName>", Country "<country>", Bank Account/Mobile Money "<destination>"
    And I click "Save"
    Then I should see validation preventing save
    And I should not see a new beneficiary "<fullName>" in the list

    Examples:
      | fullName     | country | destination |
      |              |         |             |
      | Samir Test   |         |             |
      | Samir Test   | Kenya   |             |

  @ui @beneficiaries @crud
  Scenario: Edit and delete a saved beneficiary
    Given I am logged in as "test+tier2-edit@example.com" with password "********"
    And I navigate to "Beneficiaries"
    When I add beneficiary "Alex Test" Country "Philippines" Bank "BA-00123456" and save
    And I open "Alex Test" and click "Edit"
    And I update Full Name to "Alexandre Test" and Bank to "BA-00987654" and save
    Then the list should show "Alexandre Test"
    When I reopen "Alexandre Test"
    Then details should show Full Name "Alexandre Test" and Bank "BA-00987654"
    When I delete the beneficiary "Alexandre Test"
    Then it should be removed from the list and remain absent after refresh

  @ui @remittance @beneficiaries @auto-fill
  Scenario: Selecting a saved beneficiary pre-populates the send money form
    Given I am logged in as "test+tier2-streamline@example.com" with password "********"
    And I navigate to "Beneficiaries"
    And I add beneficiary "Maria Sender" Country "Kenya" Mobile Money "MM-2547*****89" and save
    When I navigate to "Remittance > Send Money"
    And I select saved beneficiary "Maria Sender"
    Then the form should auto-populate Full Name, Country, and Mobile Money
    When I cancel the send flow and delete "Maria Sender"
    Then the beneficiary should be removed

  @ui @remittance @preconfirmation
  Scenario: Pre-confirmation review shows exchange rate and any fees before confirming
    Given I am logged in as "test+t2pre03@example.com" with password "Passw0rd!123"
    When I navigate to "Remittance > Send Money"
    And I select a saved beneficiary "Amina Rahman"
    And I enter amount "200.00" and proceed to review
    Then I should see the exchange rate on the review screen
    And I should see any transaction fees on the review screen
    When I navigate back without confirming and re-enter review
    Then exchange rate and any fees are still visible prior to confirmation

  @ui @remittance @history @pagination
  Scenario: Remittance history pagination presence and status visibility
    Given I am logged in as "test+t2hist01@example.com" with password "Passw0rd!123"
    When I navigate to "Remittance > History"
    Then I should see pagination controls
    And at least one entry with status "Pending" should be visible
    When I go to the next page and then previous
    Then the previously observed "Pending" entry should still be visible on its page

  @ui @remittance @history @status
  Scenario: Remittance history displays Completed entries and persists across refresh
    Given I am logged in as "test+t2hist02@example.com" with password "Passw0rd!123"
    When I navigate to "Remittance > History"
    Then I should see at least one entry with status "Completed"
    When I refresh the page and optionally navigate between pages
    Then a "Completed" entry should still be visible when applicable

  @ui @remittance @history @pagination
  Scenario: Remittance history supports pagination navigation across pages without duplication
    Given I am logged in as "test+rhist04-t2@example.com" with password "********"
    When I navigate to "Remittance > History"
    And I record the first page's top two reference IDs
    And I go to the next page and record two different reference IDs
    Then the first page IDs should not appear on the second page
    When I go next once more and then previous
    Then the intermediate page IDs should remain consistent
    When I return to the first page
    Then the original top two reference IDs should be present again

  @ui @remittance @history @empty
  Scenario: Remittance history empty state for users with no transfers
    Given I am logged in as "test+rhist05-t2@example.com" with password "********"
    When I navigate to "Remittance > History"
    Then I should see 0 history entries
    And pagination should be absent or disabled
    When I refresh and optionally apply a non-restrictive filter
    Then the list remains empty

  @ui @e2e
  Scenario: End-to-end journey: register → KYC → Tier 2 → virtual card → top-up → preview FX/fees → send → Completed in history
    Given I register a new account "test+e2e01@example.com" with password "********"
    And I navigate to "Profile > Verification" and verify status "Tier 1"
    When I navigate to "KYC submission" and upload "passport.png" and "selfie.png" and submit
    Then I should see submission confirmation and status "Pending"
    When I wait for approval and refresh "Profile > Verification"
    Then I should see status "Tier 2"
    When I navigate to "Cards > Virtual" and apply for a virtual card
    Then I should see a new virtual card in "Card Details"
    When I perform a top-up from a linked bank account
    Then the card balance should increase
    When I add a remittance beneficiary "Jamie Example" Country "PH" Destination "Mobile Money ****5678"
    And I start a remittance for amount "150.00" and proceed to review
    Then I should see exchange rate and any fees before confirming
    When I confirm the transfer
    Then in "Remittance > History" I should see the new transfer with status "Completed"
    And I log out

  # API Tests

  @api @registration
  Scenario Outline: API registration validation (success and missing email)
    Given the API base URL is set to env variable "API_BASE_URL"
    And the request content type is "application/json"
    When I send a POST request to "/api/users/register" with payload:
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be <status>
    And the response body should <has_field> contain field "id"
    And the response body should <has_tier> contain "verificationTier":"Tier 1"

    Examples:
      | email                   | password     | status | has_field | has_tier |
      | test+reg01@example.com  | P@ssw0rd123! | 201    |           |          |
      |                         | P@ssw0rd123! | 400    | not       | not      |

  @api @auth @profile
  Scenario Outline: API login and profile tier verification
    Given the API base URL is set to env variable "API_BASE_URL"
    And the request content type is "application/json"
    When I send a POST request to "/api/auth/login" with payload:
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be 200
    And I capture the "accessToken" from the response body
    When I send a GET request to "/api/users/me" with bearer token
    Then the response status should be 200
    And the response body should contain "email":"<email>"
    And the response body should contain "verificationTier":"<expected_tier>"

    Examples:
      | email                   | password     | expected_tier |
      | test+auth01@example.com | P@ssw0rd123! | Tier 1        |
      | test+auth02@example.com | P@ssw0rd123! | Tier 2        |

  @api @kyc
  Scenario Outline: API KYC submission acceptance and validation
    Given the API base URL is set to env variable "API_BASE_URL"
    And I am authenticated as "<email>" with password "<password>"
    When I send a POST request to "/api/kyc/submissions" with payload:
      """
      {
        "idType": "<idType>",
        "idImage": "<idImage>",
        "selfieImage": "<selfieImage>"
      }
      """
    Then the response status should be <status>
    And the response body should <has_status> contain "submissionStatus":"Pending"

    Examples:
      | email                  | password     | idType   | idImage              | selfieImage       | status | has_status |
      | test+kyc01@example.com | P@ssw0rd123! | Passport | sample-passport.jpg  | sample-selfie.jpg | 202    |           |
      | test+kyc03@example.com | P@ssw0rd123! | Passport | sample-passport.jpg  |                   | 400    | not       |
      | test+kyc04@example.com | P@ssw0rd123! | National | sample-national.jpg  | sample-selfie.jpg | 400    | not       |

  @api @cards
  Scenario Outline: API card issuance and gating (virtual allowed, physical Tier 2 only)
    Given the API base URL is set to env variable "API_BASE_URL"
    And I am authenticated as "<email>" with password "<password>"
    When I send a POST request to "<endpoint>" with payload:
      """
      {
      }
      """
    Then the response status should be <status>
    And the response body should <has_id> contain field "id"

    Examples:
      | email                      | password     | endpoint                     | status | has_id |
      | test+virt01@example.com    | ********     | /api/cards/virtual           | 201    |       |
      | test+phys01@example.com    | ********     | /api/cards/physical-orders   | 201    |       |
      | test+phys02@example.com    | ********     | /api/cards/physical-orders   | 403    | not   |

  @api @transactions @pagination
  Scenario Outline: API transaction history returns 25 items per page and next page indicator
    Given the API base URL is set to env variable "API_BASE_URL"
    And I am authenticated as "<email>" with password "<password>"
    When I send a GET request to "/api/cards/<cardId>/transactions?limit=25&offset=0" with bearer token
    Then the response status should be 200
    And the response body array "items" length should be <page1Len>
    And the response body should <hasNext> contain field "nextPage"
    When I send a GET request to "/api/cards/<cardId>/transactions?limit=25&offset=25" with bearer token
    Then the response status should be 200
    And the response body array "items" length should be <page2Len>

    Examples:
      | email                       | password | cardId     | page1Len | hasNext | page2Len |
      | test+thist01@example.com    | ******** | vcard-001  | 25       |        | 25       |
      | test+thist04@example.com    | ******** | vcard-004  | 25       | not    | 0        |

  @api @remittance
  Scenario Outline: API remittance creation and history status enumeration
    Given the API base URL is set to env variable "API_BASE_URL"
    And I am authenticated as "<email>" with password "<password>"
    When I send a POST request to "/api/remittances" with payload:
      """
      {
        "beneficiaryId": "<beneficiaryId>",
        "amount": <amount>
      }
      """
    Then the response status should be <createStatus>
    And the response body should <created> contain field "id"
    And the response body "status" should be one of "Pending,Completed,Failed"
    When I send a GET request to "/api/remittances/history?limit=10&offset=0" with bearer token
    Then the response status should be 200
    And the response body array "items" should contain an entry with "amount": <amount> and "beneficiaryId":"<beneficiaryId>"

    Examples:
      | email                      | password | beneficiaryId | amount | createStatus | created |
      | test+remit01_t2@example.com| ******** | bene-7890     | 150    | 201          |        |
      | test+remit02_t1@example.com| ******** | bene-1111     | 50     | 403          | not    |
