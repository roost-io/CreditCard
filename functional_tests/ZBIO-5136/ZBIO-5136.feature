I've analyzed the git diff and identified that the following change has been made to the requirements:

1. The masking of credit card numbers in the log entries for collection calls is no longer required (removed from expectedResult in one place and completely removed TC-012 test case)

Based on this change, I need to update the test scenario that verifies credit card masking in collection call logs:

Feature: Credit Card Balance and Payment Management
This feature covers viewing credit card balances, making payments, and system processes for overdue accounts, for both UI and API interfaces.

Background:
  Given the API base URL is set from environment variable 'BASE_URL'
  And the content type is 'application/json'

# API Test Scenarios
@api
Scenario: Retrieve card balance for an account with an outstanding amount
  Given the authorization header is set for user 'user-001' with card 'card-123'
  When I send a GET request to '/api/v1/cards/card-123/balance'
  Then the response status should be 200
  And the response body should contain a 'unpaidBalance' of 150.75
  And the response body should contain a 'dueDate' with a valid date format

@api
Scenario Outline: Retrieve zero balance for new or fully paid cards
  Given the authorization header is set for user '<user_id>' with card '<card_id>'
  When I send a GET request to '/api/v1/cards/<card_id>/balance'
  Then the response status should be 200
  And the response body should contain a 'unpaidBalance' of 0.00
  And the response body 'dueDate' should be null or not present

  Examples:
    | user_id   | card_id   | description      |
    | user-002  | card-new  | new card         |
    | user-003  | card-paid | fully paid card  |

@api
Scenario: Successfully make a full payment via API
  Given the authorization header is set for user 'user-005' with card 'card-250' which has a balance of 250.00
  And the request body:
    '''
    {
      "amount": 250.00,
      "paymentMethodId": "pm_valid_source",
      "currency": "USD"
    }
    '''
  When I send a POST request to '/api/v1/cards/card-250/payments'
  Then the response status should be 201
  And the response body 'status' should be 'succeeded'
  And the response body should contain a 'transactionId'

@api
Scenario: Successfully make a partial payment via API
  Given the authorization header is set for user 'user-006' with card 'card-500' which has a balance of 500.00
  And the request body:
    '''
    {
      "amount": 200.00,
      "paymentMethodId": "pm_valid_source",
      "currency": "USD"
    }
    '''
  When I send a POST request to '/api/v1/cards/card-500/payments'
  Then the response status should be 201
  And the response body 'status' should be 'succeeded'
  And a subsequent GET request to '/api/v1/cards/card-500/balance' should have 'unpaidBalance' of 300.00

@api
Scenario: Handle an overpayment via API
  Given the authorization header is set for user 'user-007' with card 'card-100' which has a balance of 100.00
  And the request body:
    '''
    {
      "amount": 120.00,
      "paymentMethodId": "pm_valid_source",
      "currency": "USD"
    }
    '''
  When I send a POST request to '/api/v1/cards/card-100/payments'
  Then the response status should be 201
  And a subsequent GET request to '/api/v1/cards/card-100/balance' should have 'unpaidBalance' of 0.00
  And the same response should have 'creditBalance' of 20.00

@api
Scenario: Fail a payment with invalid card details via API
  Given the authorization header is set for user 'user-008' with card 'card-fail'
  And the request body:
    '''
    {
      "amount": 75.00,
      "paymentMethodId": "pm_invalid_cvc",
      "currency": "USD"
    }
    '''
  When I send a POST request to '/api/v1/cards/card-fail/payments'
  Then the response status should be 400
  And the response body should contain an 'errorCode' of 'payment_details_invalid'
  And the response body should contain an 'errorMessage' of 'Your card details are incorrect.'

@api
Scenario: Fail a payment attempt for a non-existent card
  Given the authorization header is set for user 'user-008'
  And the request body:
    '''
    {
      "amount": 50.00,
      "paymentMethodId": "pm_valid_source",
      "currency": "USD"
    }
    '''
  When I send a POST request to '/api/v1/cards/card-nonexistent/payments'
  Then the response status should be 404
  And the response body should contain an 'errorMessage' of 'Card not found.'

@api
Scenario: Trigger automated collection call for a past-due account
  Given an admin authorization header is set
  And a user 'user-past-due' has a card with an unpaid balance and a past due date
  When I send a POST request to '/api/v1/admin/batch/check-past-due'
  Then the response status should be 202
  And a subsequent GET request to '/api/v1/admin/call-logs?userId=user-past-due' should return a log entry with status 'TRIGGERED'

@api
Scenario: Ensure no collection call is triggered for a fully paid account
  Given an admin authorization header is set
  And a user 'user-paid-up' has a card with a zero balance
  When I send a POST request to '/api/v1/admin/batch/check-past-due'
  Then the response status should be 202
  And a subsequent GET request to '/api/v1/admin/call-logs?userId=user-paid-up' should return an empty list

@api
Scenario: Ensure payment API endpoint requires authentication
  Given the authorization header is not set
  When I send a POST request to '/api/v1/cards/card-any/payments' with an empty body
  Then the response status should be 401
  And the response body should contain an 'error' of 'Authentication required'

# UI Test Scenarios
@ui
Scenario: Display unpaid balance and due date on the account summary page
  Given I am logged in as a user with an unpaid balance of '$150.75'
  When I navigate to the 'Account Summary' page
  Then I should see the unpaid balance is '$150.75'
  And I should see the payment due date is displayed

@ui
Scenario Outline: Display zero balance for new or fully paid cards
  Given I am logged in as a user with a <card_status>
  When I navigate to the 'Account Summary' page
  Then I should see the unpaid balance is '$0.00'

  Examples:
    | card_status         |
    | new card            |
    | fully paid off card |

@ui
Scenario: User successfully pays the full unpaid balance
  Given I am logged in as a user with an unpaid balance of '$250.00'
  When I navigate to the 'Make a Payment' page
  And I select the option to pay the 'Full Balance'
  And the payment amount field is pre-filled with '250.00'
  And I enter valid payment details and click 'Confirm Payment'
  Then I should see a success message 'Payment Successful'
  And I should be redirected to the 'Account Summary' page
  And the unpaid balance should now be '$0.00'

@ui
Scenario: User successfully makes a partial payment
  Given I am logged in as a user with an unpaid balance of '$500.00'
  When I navigate to the 'Make a Payment' page
  And I select the option to pay a 'Custom Amount'
  And I enter '200.00' into the payment amount field
  And I enter valid payment details and click 'Confirm Payment'
  Then I should see a success message 'Payment Successful'
  And on the 'Account Summary' page, the unpaid balance should now be '$300.00'

@ui
Scenario: User makes an overpayment and sees a credit balance
  Given I am logged in as a user with an unpaid balance of '$100.00'
  When I navigate to the 'Make a Payment' page
  And I enter '120.00' into the custom payment amount field
  And I complete the payment successfully
  Then I should see a success message 'Payment Successful'
  And on the 'Account Summary' page, the unpaid balance should be '$0.00'
  And I should see a credit balance of '$20.00'

@ui
Scenario: User attempts a payment with invalid card details
  Given I am logged in as a user with an unpaid balance of '$80.00'
  When I navigate to the 'Make a Payment' page
  And I enter '80.00' into the payment amount field
  And I enter an expired card date in the payment details form
  And I click the 'Confirm Payment' button
  Then I should see an error message 'Payment failed. Please check your card details and try again.'
  And my unpaid balance on the page should still be '$80.00'

@ui
Scenario: User attempts to submit a payment form with an empty amount
  Given I am logged in and on the 'Make a Payment' page
  When I leave the payment amount field empty
  And I click the 'Confirm Payment' button
  Then I should see a validation error message 'Payment amount is required' next to the amount field
  And the payment should not be processed