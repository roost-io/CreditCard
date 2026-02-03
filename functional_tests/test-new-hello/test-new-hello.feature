Feature: EvolvePay Platform Management

  Background:
    # API Test Setup
    Given the API base URL is set from environment variable 'BASE_URL'
    And the content type is 'application/json'

    # UI Test Setup
    Given I am on the EvolvePay homepage

# --------------------------------------------------------------------------------
# API Test Scenarios
# --------------------------------------------------------------------------------

  @api @registration
  Scenario: [API] Successful New User Registration for Tier 1 Access
    Given the request body for a new user:
      '''
      {
        "email": "new.user.api@example.com",
        "password": "StrongPassword123!",
        "passwordConfirmation": "StrongPassword123!"
      }
      '''
    When I send a POST request to '/api/v1/users/register'
    Then the response status should be 201
    And the response body should contain a "userId" field
    And the response body "user.tier" should be "Tier 1 (Unverified)"
    And the response body should contain an "authToken"

  @api @registration
  Scenario: [API] Attempt Registration with an Existing Email
    Given a user with email "existing.user@example.com" already exists
    And the request body for registration with the existing email:
      '''
      {
        "email": "existing.user@example.com",
        "password": "AnotherPassword456!",
        "passwordConfirmation": "AnotherPassword456!"
      }
      '''
    When I send a POST request to '/api/v1/users/register'
    Then the response status should be 409
    And the response body should contain an error message "This email address is already registered."

  @api @registration
  Scenario: [API] Attempt Registration with a Weak Password
    Given the request body with a weak password:
      '''
      {
        "email": "weak.password.user@example.com",
        "password": "123",
        "passwordConfirmation": "123"
      }
      '''
    When I send a POST request to '/api/v1/users/register'
    Then the response status should be 400
    And the response body should contain an error message "Password does not meet security requirements."

  @api @kyc
  Scenario: [API] Tier 1 User Submits Documents for KYC Verification
    Given the authorization header is set with a valid token for a Tier 1 user
    And the content type is 'multipart/form-data'
    And the multipart request body contains:
      | field        | value                         | type |
      | id_document  | 'path/to/passport.jpg'        | file |
      | selfie_image | 'path/to/selfie.png'          | file |
      | documentType | 'PASSPORT'                    | text |
    When I send a POST request to '/api/v1/users/kyc/submit'
    Then the response status should be 202
    And the response body "message" should be "KYC documents submitted for review."
    And the response body "kycStatus" should be "Pending"

  @api @kyc
  Scenario: [API] Get User Profile and Verification Status
    Given the authorization header is set with a valid token for a user with "Pending" KYC status
    When I send a GET request to '/api/v1/users/profile'
    Then the response status should be 200
    And the response body "tier" should be "Tier 1 (Unverified)"
    And the response body "kycStatus" should be "Pending"

  @api @cards
  Scenario: [API] Tier 2 (Verified) User Orders a Physical Card
    Given the authorization header is set with a valid token for a Tier 2 user
    And the request body to confirm the shipping address:
      '''
      {
        "addressId": "addr_123456789"
      }
      '''
    When I send a POST request to '/api/v1/cards/physical/order'
    Then the response status should be 201
    And the response body should contain a "cardId"
    And the response body "cardType" should be "PHYSICAL"
    And the response body "status" should be "Ordered"

  @api @cards
  Scenario: [API] Tier 1 (Unverified) User is Blocked from Ordering a Physical Card
    Given the authorization header is set with a valid token for a Tier 1 user
    When I send a POST request to '/api/v1/cards/physical/order'
    Then the response status should be 403
    And the response body should contain an error message "User must be Tier 2 verified to order a physical card."

  @api @cards
  Scenario: [API] User Blocks a Lost Card
    Given the authorization header is set with a valid token for a user with card "card-active-123"
    And the request body to block the card:
      '''
      {
        "status": "BLOCKED",
        "reason": "Card was lost"
      }
      '''
    When I send a PUT request to '/api/v1/cards/card-active-123/status'
    Then the response status should be 200
    And the response body "status" should be "BLOCKED"

  @api @transactions
  Scenario Outline: [API] Filter Transaction History by Type and Date Range
    Given the authorization header is set with a valid token for a user with card "card-tx-history-456"
    When I send a GET request to '/api/v1/cards/card-tx-history-456/transactions?startDate=2025-09-01&endDate=2025-09-30&type=<type>'
    Then the response status should be 200
    And the response body should be a JSON array
    And each item in the response body should have a "type" of "<type>"

    Examples:
      | type     |
      | purchase |
      | load     |
      | refund   |

  @api @transactions
  Scenario: [API] Verify Transaction History Pagination
    Given the authorization header is set with a valid token for a user with a card having over 50 transactions
    When I send a GET request to '/api/v1/cards/card-many-tx-789/transactions?page=2&limit=25'
    Then the response status should be 200
    And the response body should contain a "data" array
    And the response body "pagination.currentPage" should be 2
    And the response body "pagination.itemsPerPage" should be 25
    And the response body "pagination.totalItems" should be greater than 25

  @api @security
  Scenario: [API] Attempt to Access Resources with an Expired Session Token
    Given I have an authentication token that has just expired
    And the authorization header is set with the expired token
    When I send a GET request to '/api/v1/users/profile'
    Then the response status should be 401
    And the response body should contain an error message "Session has expired. Please log in again."

# --------------------------------------------------------------------------------
# UI Test Scenarios
# --------------------------------------------------------------------------------

  @ui @registration
  Scenario: [UI] Successful New User Registration
    Given I am on the registration page
    When I enter "test.user.ui@example.com" in the "Email" field
    And I enter "StrongPassword123!" in the "Password" field
    And I enter "StrongPassword123!" in the "Confirm Password" field
    And I click the "Register" button
    Then I should be redirected to the dashboard
    And I should see a success message "Registration successful! Please check your email to verify your account."
    And I should see my verification status as "Tier 1 (Unverified)" in my profile.

  @ui @registration
  Scenario: [UI] Attempt Registration with a Mismatched Password
    Given I am on the registration page
    When I enter "mismatch.user@example.com" in the "Email" field
    And I enter "StrongPassword123!" in the "Password" field
    And I enter "DifferentPassword456!" in the "Confirm Password" field
    And I click the "Register" button
    Then I should remain on the registration page
    And I should see an error message "Passwords do not match."

  @ui @login
  Scenario: [UI] User Login with Invalid Credentials
    Given I am on the login page
    When I enter "nonexistent.user@example.com" in the "Email" field
    And I enter "WrongPassword123" in the "Password" field
    And I click the "Login" button
    Then I should see an error message "Invalid email or password."

  @ui @kyc
  Scenario: [UI] Tier 1 User Submits Documents for KYC Verification
    Given I am logged in as a "Tier 1 (Unverified)" user
    When I navigate to the "Profile" page
    And I click the "Upgrade to Tier 2" button
    And I select "Passport" from the "ID Type" dropdown
    And I upload a valid ID document "files/passport.jpg"
    And I upload a selfie "files/selfie.jpg"
    And I click the "Submit for Verification" button
    Then I should see a confirmation message "Your documents have been submitted for review."
    And my profile status should be updated to "Pending"

  @ui @cards
  Scenario: [UI] Tier 1 User is Prevented from Ordering a Physical Card
    Given I am logged in as a "Tier 1 (Unverified)" user
    When I navigate to the "Cards" page
    Then the "Order Physical Card" button should be disabled
    And I should see a message "Please complete Tier 2 verification to order a physical card."

  @ui @cards
  Scenario: [UI] Tier 2 User Successfully Orders a Physical Card
    Given I am logged in as a "Tier 2 (Verified)" user
    When I navigate to the "Cards" page
    And I click the "Order Physical Card" button
    And I confirm my mailing address on the confirmation screen
    And I click the "Confirm Order" button
    Then I should see a success message "Your physical card has been ordered and will be shipped to your address."
    And the card status in the list should show "Ordered"

  @ui @transactions
  Scenario: [UI] Filter Transaction History by Date Range and Type
    Given I am logged in and on the "Transaction History" page for my card
    And there are "purchase" and "load" transactions in my history
    When I set the start date to "2025-10-01"
    And I set the end date to "2025-10-15"
    And I select "Purchase" from the "Transaction Type" filter
    And I click the "Apply Filters" button
    Then the transaction list should only show transactions with type "Purchase"
    And all displayed transactions should be dated between "2025-10-01" and "2025-10-15"

  @ui @transactions
  Scenario: [UI] Verify Transaction History Pagination Displays 25 Items Per Page
    Given I am logged in and have a card with 30 transactions
    When I navigate to the "Transaction History" page
    Then I should see 25 transactions listed on the page
    And I should see pagination controls showing "Page 1 of 2"
    When I click the "Next" page button
    Then I should see the remaining 5 transactions on the second page

  @ui @cards
  Scenario: [UI] User Blocks a Card and Confirms its Status
    Given I am logged in and have an active card
    When I navigate to the "Card Details" page
    And I click the "Block Card" button
    And I confirm the action in the popup dialog by clicking "Yes, Block Card"
    Then I should see a success message "Card has been successfully blocked."
    And the card status on the page should change to "Blocked"

  @ui @cards
  Scenario: [UI] Daily Load Limit Display Updates After a Top-Up
    Given I am logged in and on the "Card Details" page
    And the daily limit display shows "$0.00 / $2000.00 daily limit used"
    When I navigate to the "Load Funds" page
    And I perform a successful top-up of "$500.00"
    And I return to the "Card Details" page
    Then the daily limit display should now show "$500.00 / $2000.00 daily limit used"

  @ui @security
  Scenario: [UI] User is Automatically Logged Out After a Period of Inactivity
    Given I am logged in to the EvolvePay platform
    When I remain idle for 15 minutes
    And I attempt to click on the "Profile" navigation link
    Then I should be redirected to the login page
    And I should see a message "Your session has expired due to inactivity. Please log in again."

  @ui @remittance
  Scenario: [UI] Tier 2 User Successfully Sends an International Remittance
    Given I am logged in as a "Tier 2 (Verified)" user with sufficient funds
    And I have a saved beneficiary for international transfer
    When I navigate to the "International Transfer" page
    And I select the beneficiary
    And I enter an amount to send
    And I review the exchange rate and fees on the confirmation screen
    And I click the "Confirm Transfer" button
    Then I should see a success message with a transaction reference number
    And the transfer should appear in my international transfer history with a "Pending" status

  @ui @remittance
  Scenario: [UI] Tier 1 User is Blocked from International Remittance
    Given I am logged in as a "Tier 1 (Unverified)" user
    When I attempt to navigate to the "International Transfer" page
    Then the "International Transfer" option should be disabled or not visible
    And I should be shown a message stating I need to be a Tier 2 user

  @ui @remittance
  Scenario: [UI] User Adds and Saves a New Beneficiary
    Given I am logged in as a "Tier 2 (Verified)" user
    When I navigate to the "Beneficiaries" management page
    And I click "Add New Beneficiary"
    And I fill in all required beneficiary details
    And I click the "Save Beneficiary" button
    Then I should see a confirmation message "Beneficiary saved successfully."
    And the new beneficiary should appear in the list of saved beneficiaries

  @ui @remittance
  Scenario: [UI] User Deletes an Existing Beneficiary
    Given I am logged in as a "Tier 2 (Verified)" user and have a saved beneficiary
    When I navigate to the "Beneficiaries" management page
    And I select a beneficiary from the list
    And I click the "Delete" option
    And I confirm the deletion
    Then the beneficiary should be removed from the list of saved beneficiaries
    And I should see a success message "Beneficiary successfully removed."

  @ui @remittance
  Scenario: [UI] Verify Display of Exchange Rate and Fees Before Transfer Confirmation
    Given I am logged in as a "Tier 2 (Verified)" user
    When I initiate an international transfer and proceed to the confirmation screen
    Then the screen must clearly display the send amount and the exchange rate
    And the screen must clearly display a breakdown of all transaction fees
    And the screen must clearly display the total amount to be debited

  @ui @remittance
  Scenario: [UI] Verify International Transfer History and Pagination
    Given I am logged in and have a history of more than 25 international transfers
    When I navigate to the "International Transfer History" page
    Then the page displays a list of the first 25 past international transfers
    And pagination controls are visible
    When I click the "Next" page button
    Then the next set of transactions should be displayed on the second page