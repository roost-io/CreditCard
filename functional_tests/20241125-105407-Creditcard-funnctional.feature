Feature: Credit Card Due Reminder

Scenario: Send reminder before due date
  Given a cardholder with credit card number "1234 5678 9012 3456"
  And the payment due date is "2023-07-15"
  When the system checks for upcoming due dates on "2023-07-10"
  Then a reminder should be sent to the cardholder
  And the reminder should include the last 4 digits "3456"
  And the reminder should contain the payment due date "2023-07-15"

Scenario: Verify reminder content
  Given a reminder has been generated for credit card "1234 5678 9012 3456"
  When the API endpoint "/api/reminders/{cardId}" is called with GET method
  Then the response status code should be 200
  And the response body should contain:
    | last_four_digits | due_date   | cardholder_name |
    | 3456             | 2023-07-15 | John Doe        |

Scenario: Ensure reminder is sent to correct cardholder
  Given multiple cardholders exist in the system
  When a reminder is generated for credit card "1234 5678 9012 3456"
  And the API endpoint "/api/reminders/send" is called with POST method
  Then the response status code should be 200
  And the response body should confirm the reminder was sent to "john.doe@example.com"
