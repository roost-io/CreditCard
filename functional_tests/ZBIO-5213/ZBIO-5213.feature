Feature: Credit Card Notification and Escalation Workflow Compliance

  # Background for API scenarios: Set base URL, authentication, and content type.
  Background:
    Given the API base URL is set to "https://api.creditcardissuer.com"
    And the authorization token is configured for test users
    And the content type is "application/json"

  # -------------------------------------
  # Due Reminder Notification Scenarios
  @functional @api
  Scenario Outline: Automated Due Reminder Sent to Cardholder with Masked Card Number
    Given an active credit card account with card ending in <card_last4> and due date <due_date>
    And account status is <account_status>
    And payment history is <payment_history>
    When the automated due reminder batch job is triggered
    Then the reminder notification is sent to <notification_channel>
    And the notification contains only the last 4 digits "<card_last4>" for identification
    And no other portion of the credit card number is present anywhere in the notification message or logs

    Examples:
      | card_last4 | due_date      | account_status | payment_history   | notification_channel |
      | 4242       | 5_days_ahead  | Current        | No missed payment | Email               |
      | 4242       | 5_days_ahead  | Current        | No missed payment | SMS                 |

  @negative @api
  Scenario Outline: Reminder Not Sent for Paid Accounts
    Given an active credit card account with card ending "<card_last4>" and due date "<due_date>"
    And payment for the due amount has already been posted
    And account status is "<account_status>"
    When the automated due reminder batch job runs
    Then no due reminder notification is sent or queued
    And no record of a due reminder for the paid account is found in outbound communications logs or inboxes

    Examples:
      | card_last4 | due_date      | account_status |
      | 4242       | 5_days_ahead  | Paid           |
      | 5778       | 3_days_ahead  | Paid           |

  @boundary @api
  Scenario Outline: Due Reminder Sent at Correct Interval Before Due Date
    Given a credit card account with card ending "<card_last4>" and due date set to "<due_date>"
    When the due reminder batch job is triggered
    Then a reminder is sent only when due date is "<trigger_interval>"
    And no reminders are sent for "<non_trigger_interval>"
    And notification timestamp matches the configured interval date

    Examples:
      | card_last4 | due_date      | trigger_interval | non_trigger_interval |
      | 1111       | 5_days_ahead  | 5_days_ahead     | 6_days,4_days_ahead |
      | 2222       | 6_days_ahead  | -                | 6_days_ahead        |
      | 3333       | 4_days_ahead  | -                | 4_days_ahead        |

  # Privacy and Security for Notifications
  @security @api
  Scenario Outline: Due Reminder Content Only Shows Last 4 Digits of Card Number
    Given an eligible card account with masked number "<masked_card>" and notification is triggered
    When notification is sent via <notification_channel>
    Then only "<masked_card>" or "ending in <card_last4>" appears in the reminder
    And no additional card number digits are exposed in payload, headers, audit log, notifications UI

    Examples:
      | masked_card         | card_last4 | notification_channel |
      | **** **** **** 5678 | 5678       | Email               |
      | **** **** **** 9111 | 9111       | SMS                 |

  # Audit Logging for Due Reminder
  @audit @api
  Scenario Outline: Audit Log for Due Reminder Notification
    Given audit logging is enabled for all notification events
    And a due reminder is sent for account "<user_account>" with card ending "<card_last4>"
    When audit logs are retrieved
    Then audit log entry exists for the reminder with correct type, user, date, channel, last 4 digits "<card_last4>"
    And no full card number is recorded
    And the log entry is retrievable and immutable

    Examples:
      | user_account                  | card_last4 |
      | testuser+audit01@example.com  | 1357       |


  # -------------------------------------
  # Overdue Alert Notification Scenarios
  @functional @api
  Scenario Outline: Overdue Alert Sent After Missed Payment
    Given a credit card account with payment due date "<due_date>" and no payment posted
    And account moves to overdue state
    When overdue alert batch process is triggered
    Then overdue alert notification is sent to cardholder and displays only last 4 digits "<card_last4>"
    And no unmasked card number is present

    Examples:
      | card_last4 | due_date    |
      | 7890       | yesterday   |
      | 2468       | yesterday   |

  @functional @api
  Scenario Outline: Overdue Alert Contains Proper Consequence Warning
    Given a cardholder account with overdue status and nonzero balance
    When overdue alert is triggered and delivered
    Then notification displays overdue amount and last 4 digits "<card_last4>"
    And message includes explicit phrase on potential consequences for non-payment

    Examples:
      | card_last4 |
      | 2468       |
      | 7890       |

  @security @api
  Scenario Outline: Overdue Alert Contains Only Last 4 Digits of Card Number
    Given notification templates are set to display only last 4 digits for overdue alert
    When alert notification is triggered
    Then only "<masked_card>" is included in all message references to card number
    And no additional card data is present anywhere (message, attachments, logs)

    Examples:
      | masked_card         |
      | **** **** **** 9001 |
      | **** **** **** 2184 |

  @negative @api
  Scenario Outline: No Overdue Alert Sent for Non-Overdue Accounts
    Given a credit card account in status "<status>"
    When overdue alert batch job is triggered
    Then no overdue alert notification is generated, logged, or sent
    And customer does not receive erroneous communication
    And system logs indicate no delivery event

    Examples:
      | status   |
      | Current  |
      | Paid     |

  @audit @api
  Scenario Outline: Audit Log Created on Overdue Alert Delivery
    Given audit logging is enabled
    And overdue alert notification is delivered for account "<card_last4>"
    When audit logs are reviewed
    Then log entry is present with overdue alert type, recipient, last 4 digits "<card_last4>", and timestamp
    And no unmasked sensitive info
    And entry is immutable

    Examples:
      | card_last4 |
      | 3901       |
      | 2842       |

  # -------------------------------------
  # Collection Notification Scenarios
  @functional @api
  Scenario Outline: Collection Notification Triggered for Delinquent Accounts
    Given a credit card account transitions to 'Significantly Delinquent'
    And account has last 4 digits "<card_last4>"
    When collection notification workflow is triggered
    Then collection notification is sent to registered communication channel
    And notification explicitly includes last 4 digits "<card_last4>"
    And no PII or full card number present
    And audit trail is updated with event timestamp

    Examples:
      | card_last4 |
      | 4242       |
      | 8844       |

  @functional @api
  Scenario Outline: Collection Notification Includes Amount Owed and Additional Charges
    Given a delinquent account with overdue balance and additional charges
    And account ledger shows overdue "<amount_owed>" and late fee "<fee>"
    When collection notification is created and delivered
    Then notification includes accurate amount "<amount_owed>" and itemized charges matching ledger
    And message contains no extraneous or missing charges

    Examples:
      | amount_owed | fee  |
      | $2,045.23   | $35  |
      | $600.00     | $20  |

  @security @api
  Scenario Outline: Collection Notification Masks Card Number Correctly
    Given a collection notification is issued for card "<full_card>" (last 4 "<card_last4>")
    When message is delivered to cardholder
    Then only the last 4 digits "<card_last4>" appear in masked format "<masked_card>"
    And no additional digits from the full card number are present in notification, logs, or payloads

    Examples:
      | full_card             | card_last4 | masked_card         |
      | 5678 1234 9012 8420   | 8420       | **** **** **** 8420 |
      | 8943 9452 2345 2361   | 2361       | **** **** **** 2361 |

  @negative @api
  Scenario Outline: No Collection Notification Sent for Non-Delinquent Accounts
    Given a credit card account is not in 'Significantly Delinquent' state
    When collection notification workflow is triggered
    Then no collection notification is generated or sent
    And no message logs or inbox show such notification

    Examples:
      | card_last4 |
      | 2211       |
      | 1102       |

  # -------------------------------------
  # Payment Plan Proposal Scenarios
  @functional @api
  Scenario Outline: Payment Plan Proposal Sent to Eligible Accounts
    Given a delinquent account marked unable to pay overdue balance in full
    When payment plan proposal workflow is triggered
    Then payment plan proposal is sent to the cardholder
    And proposal contains structured repayment schedule and recorded in message log

    Examples:
      | card_last4 |
      | 4499       |
      | 9644       |

  @security @api
  Scenario Outline: Payment Plan Proposal Includes Last 4 Digits of Card Number
    Given account eligible for payment plan proposal, card "<full_card>" (last 4 "<card_last4>")
    When proposal is generated and sent
    Then only last 4 digits "<card_last4>" are present for identification
    And all but the last 4 digits are masked or omitted in communication and logs

    Examples:
      | full_card            | card_last4 |
      | 6203 8486 8756 9711  | 9711       |
      | 8954 2601 3000 3322  | 3322       |

  @functional @api
  Scenario Outline: Payment Plan Terms Displayed Accurately
    Given a payment plan proposal is generated for overdue account "<card_last4>"
    And reduced rate or fee is applied "<rate_or_fee>"
    When communication is delivered
    Then proposal outlines repayment schedule dates/amounts and displays reduced rate/fee matching backend
    And all listed terms reflect current backend schedule with no errors

    Examples:
      | card_last4 | rate_or_fee         |
      | 9644       | interest:12%       |
      | 4499       | reduced_fee:$15    |

  @negative @api
  Scenario Outline: No Payment Plan Proposal Sent Where Ineligible
    Given an account is ineligible for payment plan (status "<eligibility_status>")
    When payment plan proposal workflow is triggered
    Then no payment plan proposal is generated or sent
    And communication history is clear of any proposal for ineligible cases

    Examples:
      | eligibility_status    |
      | Paid in Full          |
      | Maximum plans reached |
      | Failing eligibility   |

  # -------------------------------------
  # Collection Agency Escalation Scenarios
  @functional @api
  Scenario Outline: Collection Agency Notified for Unresponsive Accounts
    Given an account in 'Agency Handoff Ready' state, card "<card_last4>"
    And prior notifications sent with no customer reply received
    When agency notification workflow is triggered
    Then collection agency receives notification and case details for account
    And the event is logged in system audit
    And no failure or delivery error occurs

    Examples:
      | card_last4 |
      | 3348       |
      | 5911       |

  @security @api
  Scenario Outline: Only Last 4 Digits Sent to Collection Agency
    Given a collection agency handoff workflow is triggered for card "<full_card>"
    When payload is sent to agency endpoint
    Then only last 4 digits "<card_last4>" are provided for identification
    And no more than 4 digits or full card number is present in any payload, file, or log

    Examples:
      | full_card            | card_last4 |
      | 9492 8555 6321 5911  | 5911       |
      | 1987 5216 1938 2217  | 2217       |

  @negative @api
  Scenario Outline: No Collection Agency Escalation For Responsive Accounts
    Given an overdue credit card account "<card_last4>" with payment or response submitted before escalation deadline
    When collection agency escalation workflow is triggered
    Then the account is absent from the agency escalation list
    And no transmission or escalation event occurs for this account
    And audit log does not record escalation or handoff events

    Examples:
      | card_last4 |
      | 8421       |
      | 1502       |

  @audit @api
  Scenario Outline: Collection Agency Escalation Audit Logging
    Given a delinquent account "<card_last4>" is escalated to a collection agency
    When audit logs are inspected
    Then a complete, immutable audit log entry exists for the agency escalation
    And log records action, date/time, masked card number "<card_last4>", triggering actor, and destination
    And no full card number appears in any audit log field

    Examples:
      | card_last4 |
      | 3900       |
      | 8888       |

  @security @api
  Scenario Outline: Proper Data Masking in Collection Agency File Transfers
    Given overdue account "<card_last4>" escalated to collection agency
    When transfer file or API payload is sent
    Then file includes only last 4 digits "<card_last4>" for the account
    And no full card number is present in any row, key, or log for any transferred account

    Examples:
      | card_last4 |
      | 2217       |
      | 5911       |

  # -------------------------------------
  # Legal Action Escalation Scenarios
  @functional @api
  Scenario Outline: Legal Action Initiated on Extreme Non-Payment
    Given a credit card account "<card_last4>" is in extreme non-payment status beyond threshold and all escalations completed
    When legal action initiation workflow is triggered
    Then legal action documentation package is generated and delivered to cardholder
    And account status is updated to Legal Action Initiation
    And audit log records account’s transition to legal action

    Examples:
      | card_last4 |
      | 7854       |
      | 8888       |

  @security @api
  Scenario Outline: Legal Documentation Contains Only Last 4 Digits
    Given a legal document is generated for escalated account "<masked_card>"
    When document is retrieved
    Then only "<masked_card>" or last 4 digits appear in all sections, fields, metadata, and logs
    And no full card number is ever present

    Examples:
      | masked_card         |
      | **** **** **** 7854 |
      | **** **** **** 4444 |

  @negative @api
  Scenario Outline: No Legal Action for Accounts Without Escalated Delinquency
    Given a credit card account in overdue or collection status but not extreme delinquency
    When legal action workflow is triggered
    Then no legal action is initiated for the account
    And no legal documents or state transitions occur
    And logs reflect workflow enforcement and ineligibility

    Examples:
      | card_last4 |
      | 9644       |
      | 3333       |

  @audit @api
  Scenario Outline: Audit Log for Legal Action Initiation
    Given legal action is initiated for delinquent account "<card_last4>"
    When audit log is reviewed
    Then log entry shows action, masked card (last 4 "<card_last4>"), timestamp, initiator, workflow reference
    And no unmasked card number or extra PII is present
    And entry is immutable and downloadable for compliance

    Examples:
      | card_last4 |
      | 7854       |
      | 8888       |


  # -------------------------------------
  # Privacy Validation Scenarios (Full Card Never Exposed)
  @security @api
  Scenario Outline: Full Card Number Never Included in Reminders
    Given a due reminder notification is sent for card "<card_last4>"
    When notification is retrieved across all channels and logs
    Then only last 4 digits "<card_last4>" (masked format) are visible
    And full card number is never present in message, subject, body, metadata, or logs

    Examples:
      | card_last4 |
      | 9953       |
      | 0421       |

  @security @api
  Scenario Outline: Full Card Number Never Included in Overdue Alerts
    Given overdue balance alert is triggered for card "<card_last4>"
    When notification and logs are reviewed
    Then only last 4 digits "<card_last4>" are referenced
    And full card number is not included in any field or log

    Examples:
      | card_last4 |
      | 7631       |
      | 4444       |

  @security @api
  Scenario Outline: Full Card Number Never Included in Collection Notifications
    Given collection notification is sent for card "<card_last4>"
    When notification is inspected across all channels and logs
    Then only last 4 digits "<card_last4>" are present in masked format
    And full card number is absent everywhere

    Examples:
      | card_last4 |
      | 5778       |
      | 2211       |

  @security @api
  Scenario Outline: Full Card Number Never in Payment Plan Proposals
    Given payment plan proposal is generated for card "<card_last4>"
    When proposal content is reviewed across all channels, logs, and stored templates
    Then only last 4 digits "<card_last4>" are included and full card number is never exposed

    Examples:
      | card_last4 |
      | 2222       |
      | 1932       |

  @security @api
  Scenario Outline: Full Card Number Never in Collection Agency Data
    Given account "<card_last4>" is handed off to collection agency
    When agency payload, export files, logs, and portal are checked
    Then only last 4 digits "<card_last4>" are transmitted or visible
    And full card number is never present in any output or integration

    Examples:
      | card_last4 |
      | 3333       |
      | 5911       |

  @security @api
  Scenario Outline: Full Card Number Never in Legal Documentation
    Given legal documents are generated for account "<card_last4>"
    When document, metadata, audit, and all communication are inspected
    Then only last 4 digits "<card_last4>" or masked format is shown
    And full card number is never present

    Examples:
      | card_last4 |
      | 4444       |
      | 7854       |


  # -------------------------------------
  # State Transition Scenarios
  @state-transition @api
  Scenario Outline: Transition from Due Reminder to Overdue Alert Upon Missed Payment
    Given a cardholder with account "<cardholder>" and card ending "<card_last4>" has received due reminder
    When due date passes without payment
    Then account status updates to "Overdue"
    And overdue alert notification is triggered including only last 4 digits "<card_last4>"
    And state and notification logs record event

    Examples:
      | cardholder                 | card_last4 |
      | test.holder@example.com    | 5555       |
      | test.holder@example.com    | 2222       |

  @state-transition @api
  Scenario Outline: Transition from Overdue Alert to Collection Notification for Delinquency
    Given account "<cardholder>" in 'Overdue Alert' state, card "<card_last4>"
    When grace period passes without payment
    Then system processes escalation
    And account transitions to 'Collection Notification' state
    And notification content includes only last 4 digits "<card_last4>"
    And logs reflect correct state transition

    Examples:
      | cardholder                 | card_last4 |
      | test.holder@example.com    | 6666       |
      | test.holder@example.com    | 5778       |

  @state-transition @api
  Scenario Outline: Transition from Collection to Payment Plan Proposal on Agreement
    Given delinquent account "<cardholder>" with card "<card_last4>" is in 'Collection Notification' state
    And collection agent negotiates payment plan
    When payment plan proposal workflow is started and submitted
    Then account state updates to 'Payment Plan Proposal'
    And offer notification displays only last 4 digits "<card_last4>"

    Examples:
      | cardholder                 | card_last4 |
      | test.holder2@example.com   | 7777       |
      | test.holder3@example.com   | 9644       |

  @state-transition @api
  Scenario Outline: Transition from Agency to Legal for Unresolved Accounts
    Given account "<cardholder>" in 'Collection Agency' state (card "<card_last4>")
    And agency status is 'Failed' in system
    When legal escalation workflow is triggered
    Then account status updates to 'Legal Action Initiation'
    And legal documents and notifications contain only masked card number "<card_last4>"
    And audit logs are updated

    Examples:
      | cardholder                  | card_last4 |
      | test.agencyholder@example.com | 8888     |
      | test.agencyholder@example.com | 7854     |


  # -------------------------------------
  # Notification Delivery and Content Validation
  @functional @api
  Scenario Outline: Notification Delivery to Correct Cardholder Only
    Given notification triggered for cardholder "<recipient>" (card ending "<card_last4>")
    When notification is sent
    Then notification is delivered only to "<recipient>" via official channel
    And unauthorized users cannot access notification content
    And no card number exposure in wrong channels

    Examples:
      | recipient                  | card_last4 |
      | test+1234card@example.com  | 9999       |
      | test+5678card@example.com  | 5678       |

  @functional @api
  Scenario Outline: Notification Content Matches Account Data and Event
    Given overdue alert generated for account "<cardholder>", card ending "<card_last4>", balance "<balance>"
    When notification is delivered
    Then "<masked_card>" is present, correct balance and charges are listed
    And payment due details match backend values
    And event context matches expected alert type

    Examples:
      | cardholder                   | card_last4 | masked_card         | balance     |
      | test.holder3@example.com     | 4444       | **** **** **** 4444 | $180.26     |
      | test.holder2@example.com     | 9644       | **** **** **** 9644 | $512.13     |

  @negative @api
  Scenario Outline: Notification Fails Gracefully for Invalid Cardholder Data
    Given an account with invalid contact data or malformed card number "<card_number>"
    When notification workflow is triggered
    Then no notification is delivered
    And logs capture error about invalid data
    And no part of malformed card number appears in any message

    Examples:
      | card_number |
      | 123         |
      |             |
      | abcd9999    |

  # -------------------------------------
  # Audit Trail Privacy and Coverage
  @audit @api
  Scenario Outline: Audit Trail Exists for All Major Notifications
    Given audit trail system is enabled
    And test user "<cardholder>" (card ending "<card_last4>") receives all major notification/escalation events
    When audit trail entries are retrieved for events (Reminder, Overdue, Collection, Payment Plan, Agency, Legal)
    Then each audit log entry contains event type, recipient, date/time, last 4 digits "<card_last4>", and notification content reference
    And entries are immutable and include only masked card number

    Examples:
      | cardholder    | card_last4 |
      | audituser     | 0421       |

  @audit @api
  Scenario Outline: Audit Trail Logs Masked Card Numbers, Never Full
    Given audit log entries are created for triggered events for card "<full_card>" (last 4 "<card_last4>")
    When audit trail is inspected across Reminder, Overdue, Collection, Payment Plan, Agency, Legal Action
    Then every audit entry only contains last 4 digits "<card_last4>", no full card number

    Examples:
      | full_card              | card_last4 |
      | 5555 6666 7777 4242    | 4242       |
      | 1111 2222 3333 4444    | 4444       |

  # -------------------------------------
  # Error Handling and Security Enforcement
  @negative @api
  Scenario Outline: System Handles Missing Account Data When Sending Notifications
    Given a test account is missing required last 4 digits in card record
    When notification workflow is triggered for any event
    Then system blocks notification send
    And presents clear error indicating missing last 4 digits
    And does not dispatch any notification with incomplete info
    And logs error with specific reason

    Examples:
      | missing_field |
      | card_last4    |

  @security @api
  Scenario Outline: System Rejects Notification if Full Card Number is Provided
    Given notification payload is crafted with full card number "<full_card>"
    When notification workflow is triggered for any event
    Then system aborts send process with explicit error about forbidden card number exposure
    And no message is sent, rejection event is logged

    Examples:
      | full_card              |
      | 5555 6666 7777 4242    |
      | 4111 1111 1111 2222    |

  @security @api
  Scenario Outline: Access Control: Unauthorized Users Cannot Trigger or View Collection Actions
    Given a standard bank user without collection role attempts to access collection workflow for account "<card_last4>"
    When attempting to view, trigger, or send any collection notification, payment plan, agency, or legal action
    Then system denies all actions/viewing with access-control error
    And each attempt is logged and no workflow triggered or sensitive data displayed

    Examples:
      | card_last4 |
      | 8420       |
      | 8888       |

  # -------------------------------------
  # End-to-End Scenario: Collection Workflow Coverage
  @e2e @api
  Scenario Outline: End-to-End Collection Lifecycle: Reminder Through Legal Action
    Given test customer "<cardholder>" with card ending "<card_last4>" is eligible for escalation workflow
    When sequence of notifications and escalations are triggered in order (Due Reminder, Overdue Alert, Collection Notification, Payment Plan Proposal, Collection Agency handoff, Legal Action)
    Then at every stage, notification contains only last 4 digits "<card_last4>"
    And state transitions execute in correct sequence
    And all actions are recorded in audit log with masked card number
    And legal, privacy, and process compliance are maintained end-to-end

    Examples:
      | cardholder               | card_last4 |
      | lifecycleuser            | 5123       |

