Feature: Credit Card Due Reminder Notifications

  Scenario: Successful Due Reminder Notification
    Given a customer with account ID "ACC123" has a payment due in 5 days
    And the payment amount due is $500.00
    And the credit card has last 4 digits "4321"
    When the POST request is sent to "/api/notifications/due-reminders"
    With request body:
      """
      {
        "accountId": "ACC123",
        "notificationType": "PAYMENT_DUE"
      }
      """
    Then the response status code should be 200
    And the response body should contain:
      """
      {
        "status": "SUCCESS",
        "notificationId": "NOT-UUID",
        "deliveryStatus": "SENT"
      }
      """
    And the notification log should show successful delivery for account "ACC123"
    And the notification content should include the due date, amount "$500.00", and card ending in "4321"
