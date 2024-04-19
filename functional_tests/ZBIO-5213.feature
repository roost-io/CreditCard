Feature: API testing for Credit Card Due Reminder and Overdue Balance Alert
  Scenario: Testing HTTP POST method for Due Date Reminder
    Given the API base URL 'http://localhost:3000' 
    And a valid credit card number and due date is available
    When I send a POST request to '/credit-card-reminder' with body:
    """
    {
      "due_date": "2021-08-29",
      "card_number": "1234567890123456"
    }
    """
    Then the response status should be 200
    And the response should include the reminder notification
    And the notification includes the last 4 digits of the credit card number
  
  Scenario: Testing HTTP POST method for Overdue Balance Alert
    Given the API base URL 'http://localhost:3000'
    And a valid credit card number, due date and outstanding amount is available
    When I send a POST request to '/overdue-alert' with body:
    """
    {
      "due_date": "2021-08-29",
      "card_number": "1234567890123456",
      "outstanding_amount": "500"
    }
    """
    Then the response status should be 200
    And the response includes the overdue balance notification
    And the notification displays the overdue balance and the last four digits of the credit card number

Feature: API testing for Collection Notification and Payment Plan Proposal
  Scenario: Testing HTTP POST method for Collection Notification
    Given the API base URL 'http://localhost:3000'
    And a valid credit card number, outstanding balance and additional charges is available
    When I send a POST request to '/collection-notification' with body:
    """
    {
      "outstanding_balance": "1000",
      "additional_charges": "50",
      "card_number": "1234567890123456"
    }
    """
    Then the response status should be 200
    And the response includes the collection notification
    And the notification contains the amount owed, additional charges and last four digits of the credit card number
  
  Scenario: Testing HTTP POST method for Payment Plan Proposal
    Given the API base URL 'http://localhost:3000'
    And a valid credit card number, outstanding balance and payment proposal is available
    When I send a POST request to '/payment-plan-proposal' with body:
    """
    {
      "outstanding_balance": "1000",
      "payment_proposal": "500",
      "card_number": "1234567890123456"
    }
    """
    Then the response status should be 200
    And the response includes the payment plan proposal
    And the proposal contains reduced interest rates, fees and last four digits of the credit card number

Feature: API testing for Collection Agency Involvement and Legal Action Initiation
  Scenario: Testing HTTP POST method for Collection Agency Involvement
    Given the API base URL 'http://localhost:3000'
    And a valid credit card number, outstanding balance is available
    When I send a POST request to '/collection-agency' with body:
    """
    {
      "outstanding_balance": "1000",
      "card_number": "1234567890123456",
      "collection_agency": "Agency1"
    }
    """
    Then the response status should be 200
    And the response includes the collection notification
    And the collection agency is provided with the last four digits of the credit card number and not the full credit card number

  Scenario: Testing HTTP POST method for Legal Action Initiation
    Given the API base URL 'http://localhost:3000'
    And a valid credit card number and default payment details
    When I send a POST request to '/legal-action' with body:
    """
    {
      "default_payment_details": "Payment not received for 6 months",
      "card_number": "1234567890123456"
    }
    """
    Then the response status should be 200
    And the response includes the legal action documentation
    And any legal documentation includes the last 4 digits of the credit card number
