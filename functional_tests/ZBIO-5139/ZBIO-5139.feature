Feature: Credit Card Account Management and Application Processing

  This feature covers the end-to-end testing of the credit card system, including online applications, account management by customers, and administrative actions by bank representatives. It includes both UI-level user workflows and direct API endpoint testing.

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the content type is 'application/json'

  # --------------------------------------------------------------------------------
  # API Test Scenarios
  # --------------------------------------------------------------------------------

  @api
  Scenario: TC-001 API - Successful Credit Card Application Submission
    Given the authorization header is set for a public endpoint
    And the request body for a new application is:
      '''
      {
        "personalDetails": {
          "firstName": "John",
          "lastName": "Doe",
          "dateOfBirth": "1990-05-15",
          "socialSecurityNumber": "999-00-1111"
        },
        "incomeDetails": {
          "annualIncome": 75000,
          "employmentStatus": "FULL_TIME"
        },
        "contactInfo": {
          "email": "john.doe@example.com",
          "phone": "555-123-4567",
          "address": "123 Main St, Anytown, USA"
        },
        "termsAccepted": true
      }
      '''
    When I send a POST request to '/api/v1/applications'
    Then the response status should be 201
    And the response body should contain a non-empty 'applicationId'
    And the response body 'status' should be 'SUBMITTED'

  @api
  Scenario: TC-002 API - Application Submission with Missing Required Field
    Given the authorization header is set for a public endpoint
    And the request body for an incomplete application is:
      '''
      {
        "personalDetails": {
          "firstName": "Jane",
          "lastName": "Doe"
        },
        "incomeDetails": {
          "annualIncome": null,
          "employmentStatus": "FULL_TIME"
        },
        "contactInfo": {
          "email": "jane.doe@example.com"
        },
        "termsAccepted": true
      }
      '''
    When I send a POST request to '/api/v1/applications'
    Then the response status should be 400
    And the response body should be a JSON object
    And the response body should contain an 'errors' array
    And the 'errors' array should contain an object with 'field' as 'incomeDetails.annualIncome' and 'message' as 'Annual income is required'

  @api
  Scenario: TC-011 API - Application Submission with Invalid Data Format
    Given the authorization header is set for a public endpoint
    And the request body for an application with invalid data is:
      '''
      {
        "personalDetails": {
          "firstName": "Invalid",
          "lastName": "User"
        },
        "incomeDetails": {
          "annualIncome": 75000
        },
        "contactInfo": {
          "email": "invalid-email-format",
          "phone": "555-123-4567"
        },
        "termsAccepted": true
      }
      '''
    When I send a POST request to '/api/v1/applications'
    Then the response status should be 400
    And the response body 'errors' array should contain an object with 'field' as 'contactInfo.email' and 'message' as 'Please enter a valid email address'

  @api
  Scenario: TC-003 API - Bank Agent Successfully Waives a Fee
    Given the authorization header is set with a bank agent token from 'AGENT_AUTH_TOKEN'
    And a customer account with ID 'cust-acc-123' has a fee with ID 'fee-xyz-456'
    And the request body for a fee waiver is:
      '''
      {
        "reason": "One-time courtesy for valued customer",
        "agentId": "agent-987"
      }
      '''
    When I send a POST request to '/api/v1/accounts/cust-acc-123/fees/fee-xyz-456/waive'
    Then the response status should be 200
    And the response body should contain a 'transactionId' for the waiver
    And the response body 'message' should be 'Fee waived successfully'

  @api
  Scenario: TC-004 API - Successful Reward Points Redemption for Cashback
    Given the authorization header is set with customer token for account 'cust-acc-456'
    And the request body for a cashback redemption is:
      '''
      {
        "rewardType": "CASHBACK",
        "pointsToRedeem": 2500
      }
      '''
    When I send a POST request to '/api/v1/accounts/cust-acc-456/rewards/redeem'
    Then the response status should be 200
    And the response body should contain a 'statementCreditId'
    And the response body 'newPointsBalance' should be a number

  @api
  Scenario: TC-005 API - Attempt to Redeem with Insufficient Points
    Given the authorization header is set with customer token for account 'cust-acc-789' with low points
    And the request body to redeem more points than available is:
      '''
      {
        "rewardType": "CASHBACK",
        "pointsToRedeem": 10000
      }
      '''
    When I send a POST request to '/api/v1/accounts/cust-acc-789/rewards/redeem'
    Then the response status should be 400
    And the response body 'error' should be 'Insufficient points balance for redemption'

  @api
  Scenario: TC-006 API - Bank System Increases a Customer's Credit Limit
    Given the authorization header is set with a system admin token from 'ADMIN_AUTH_TOKEN'
    And the request body to increase a credit limit is:
      '''
      {
        "newLimit": 7500,
        "reasonCode": "AUTOMATED_6MONTH_REVIEW",
        "effectiveDate": "2023-10-27T00:00:00Z"
      }
      '''
    When I send a PUT request to '/api/v1/accounts/cust-acc-123/limit'
    Then the response status should be 200
    And the response body 'accountId' should be 'cust-acc-123'
    And the response body 'newLimit' should be 7500

  @api
  Scenario: TC-008 API - Successful Promotional Balance Transfer Request
    Given the authorization header is set with customer token for account 'cust-acc-123'
    And the request body for a balance transfer is:
      '''
      {
        "fromIssuer": "Rival Bank",
        "fromCardNumber": "4567123487650987",
        "amount": 2000.00,
        "promoCode": "BT_0_APR_12M"
      }
      '''
    When I send a POST request to '/api/v1/accounts/cust-acc-123/balance-transfers'
    Then the response status should be 202
    And the response body 'status' should be 'PROCESSING'
    And the response body should contain a 'transferId'

  @api
  Scenario: TC-010 API - Performance of Reward Points Balance Endpoint
    Given the authorization header is set with customer token for account 'cust-acc-456'
    When I send a GET request to '/api/v1/accounts/cust-acc-456/rewards'
    Then the response status should be 200
    And the response time should be less than 500ms
    And the response body should contain a 'pointsBalance' field

  # --------------------------------------------------------------------------------
  # UI Test Scenarios
  # --------------------------------------------------------------------------------

  @ui
  Scenario: TC-001 UI - Successful Credit Card Application Submission
    Given I am on the credit card application page
    When I enter 'John Doe' in the 'Full Name' field
    And I enter '75000' in the 'Annual Income' field
    And I enter 'john.doe@example.com' in the 'Email Address' field
    And I enter all other required personal and contact information
    And I check the 'I agree to the Terms and Conditions' checkbox
    And I click the 'Submit Application' button
    Then I should see the success message 'Your application has been submitted successfully!'
    And I should see my application reference number

  @ui
  Scenario: TC-002 UI - Application Submission with Missing Income Information
    Given I am on the credit card application page
    When I enter 'Jane Doe' in the 'Full Name' field
    And I leave the 'Annual Income' field blank
    And I enter 'jane.doe@example.com' in the 'Email Address' field
    And I click the 'Submit Application' button
    Then the form submission should be prevented
    And I should see an error message 'Annual Income is a required field' next to the income field

  @ui
  Scenario: TC-011 UI - Application Form with Specific Invalid Data Errors
    Given I am on the credit card application page
    When I enter 'invalid-email' in the 'Email Address' field and move to the next field
    Then I should see an error message 'Please enter a valid email address (e.g., name@example.com)'
    When I enter 'seventy five thousand' in the 'Annual Income' field and move to the next field
    Then I should see an error message 'Please enter numbers only for Annual Income'
    When I enter a future date in the 'Date of Birth' field and move to the next field
    Then I should see an error message 'Date of Birth cannot be in the future'

  @ui
  Scenario: TC-003 UI - Bank Agent Waives a Customer Fee in CRM
    Given I am logged in as a 'Bank Agent' to the CRM portal
    When I search for customer account '123-456-789'
    And I navigate to the 'Account Statement' tab
    And I locate the '$95.00 Annual Fee'
    And I click the 'Waive Fee' button next to it
    And I select 'One-time courtesy' as the reason
    And I click the 'Confirm Waiver' button
    Then I should see a confirmation message 'Fee of $95.00 has been successfully waived'
    And the customer's account balance should be updated to reflect the waiver

  @ui
  Scenario: TC-004 UI - Successful Reward Points Redemption for Cashback
    Given I am logged in as a customer
    And I have a rewards balance of '5,000' points
    When I navigate to the 'Rewards Redemption' page
    And I select the 'Cashback' category
    And I choose the '$25 Cashback for 2,500 points' option
    And I click the 'Redeem Now' button
    And I confirm the redemption on the confirmation popup
    Then I should see a success message 'You have successfully redeemed 2,500 points for a $25 statement credit'
    And my rewards balance should be updated to '2,500' points

  @ui
  Scenario: TC-005 UI - Attempt to Redeem Points with Insufficient Balance
    Given I am logged in as a customer
    And I have a rewards balance of '1,000' points
    When I navigate to the 'Rewards Redemption' page
    And I select the '$25 Gift Card for 2,500 points' option
    And I click the 'Redeem Now' button
    Then I should see an error message 'You have insufficient points to redeem this item.'
    And my rewards balance should remain '1,000' points

  @ui
  Scenario: TC-006 UI - Customer Verifies Credit Limit Increase
    Given I am logged in as a customer
    When I navigate to my 'Account Details' page
    Then I should see my 'Credit Limit' is '$7,500'
    When I navigate to the 'Notifications' center
    Then I should see a message titled 'Your Credit Limit Has Increased' with a recent date

  @ui
  Scenario: TC-008 UI - Customer Initiates a Promotional Balance Transfer
    Given I am logged in as a customer with a balance transfer offer
    When I navigate to the 'Offers and Transfers' page
    And I click 'Start a Balance Transfer'
    And I enter 'Rival Bank' in the 'Card Issuer' field
    And I enter '4567123487650987' in the '16-Digit Card Number' field
    And I enter '2000' in the 'Amount to Transfer' field
    And I review the '0% APR for 12 months' promotional terms
    And I click the 'Submit Transfer Request' button
    Then I should see a confirmation page with the message 'Your balance transfer request is being processed'
    And I should see a transaction ID for my request
