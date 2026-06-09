gherkin
Feature: Credit Card Collections Notification Lifecycle and Masking Compliance

  # Background: Setting up test account and notification infrastructure, applicable to API/audit scenarios
  Background:
    Given the API base URL is configured
    And authorization headers and audit log access are enabled
    And masking logic is active for communications

  # API Tests - Positive, Negative, Security, State-Transition, Audit, Boundary, E2E (based on scenario types)
  
  # Reminder Notification Masking - Functional & Security
  @api @security
  Scenario Outline: Reminder notification sent with masked card digits in all channels
    Given a cardholder account with credit card number <card_number> and due date <due_date>
    And the notification system is operational for all channels
    When a due reminder is triggered for payment due in <due_window> days
    Then the delivered notification in channel '<channel>' should include only last 4 digits <last4>
    And the notification must not contain the full card number <card_number>
    And the message content should indicate payment due date <due_date>
    And audit logs record the event with only <last4> as the card reference

    Examples:
      | card_number         | last4 | due_date   | due_window | channel   |
      | 5100 9999 8888 1234 | 1234  | 2024-06-25 | 3          | email     |
      | 5100 9999 8888 1234 | 1234  | 2024-06-25 | 3          | SMS       |
      | 5100 9999 8888 1234 | 1234  | 2024-06-25 | 3          | portal    |

  @api @negative
  Scenario Outline: No reminder notification is sent if not within due window
    Given a cardholder account with payment due in <due_window> days
    And the active notification scheduler is running  
    When a due reminder workflow is triggered
    Then no reminder notification should be present in channel '<channel>'
    And audit logs confirm no notification event was triggered

    Examples:
      | due_window | channel   |
      | 15         | email     |
      | 10         | SMS       |
      | 8          | portal    |

  # Reminder Notification Security - Audit/Compliance Log Check
  @audit @security
  Scenario Outline: Reminder logs and metadata never expose full card number
    Given a cardholder account with card number <card_number> and due payment
    When a reminder notification is generated and delivered
    Then audit logs, message queue logs, and metadata must only reference last 4 digits <last4>
    And searching for <card_number> in logs must return zero results

    Examples:
      | card_number         | last4 |
      | 5100 2233 4455 1874 | 1874  |
      | 5100 8888 7777 4321 | 4321  |

  # Overdue Alert State Transition
  @api @state-transition
  Scenario Outline: Account state transitions to overdue on missed payment
    Given a cardholder account with due date <due_date> and reminder sent
    And no payment is made by <due_date>
    When overnight batch processes run overdue alerts
    Then the account state changes from 'Due Reminder Sent' to 'Overdue Alert Sent'
    And overdue alert notification is sent including only last 4 digits <last4>
    And reminders are not duplicated after overdue
    And audit logs record the overdue alert event

    Examples:
      | due_date   | last4 |
      | 2024-06-20 | 4321  |
      | 2024-06-21 | 2876  |

  # Overdue Alert Masking - Security
  @security
  Scenario Outline: Overdue alert includes only last 4 digits and never full card number
    Given a cardholder account with overdue status
    When overdue alerts are sent via <channel>
    Then each alert includes only last 4 digits <last4>
    And does not include any additional card number digits in body or attachments
    And masking is consistent across logs and channels

    Examples:
      | last4 | channel   |
      | 4321  | email     |
      | 4321  | SMS       |
      | 4321  | portal    |

  # Negative: No overdue alert if payment received on time
  @negative
  Scenario Outline: Overdue alert suppression after timely payment
    Given a cardholder account with payment due date <due_date> and payment posted before <due_date>
    When overdue alert batch process triggers
    Then no overdue alert notification appears for this cardholder in <channel>
    And logs indicate alert suppression for timely payment

    Examples:
      | due_date   | channel   |
      | 2024-06-22 | email     |
      | 2024-06-22 | SMS       |
      | 2024-06-22 | portal    |

  # Boundary: Overdue days escalation triggers at exact threshold
  @boundary
  Scenario Outline: Overdue alert triggers only after due date boundary
    Given a cardholder with payment due date <due_date>
    When the system batch runs at midnight
    Then no overdue alert is sent on day 0 (before midnight)
    And overdue alert is sent on day 1 (after midnight) for overdue account
    And overdue alerts escalation occurs only at boundary days <overdue_days>
    And masking is applied (last 4 digits only)

    Examples:
      | due_date   | overdue_days |
      | 2024-06-24 | 1           |
      | 2024-05-17 | 30          |

  # Collections Notification Escalation
  @state-transition @api
  Scenario Outline: Escalate overdue account to collections after threshold
    Given an account is overdue for <overdue_days> days and overdue alerts have been sent
    And no payment or promise to pay recorded
    When batch escalates to collections notification
    Then the account state moves from 'Overdue' to 'Collections Notification Sent'
    And collection notification is sent documenting overdue balance and last 4 digits <last4>
    And overdue alerts are not generated post-collections
    And audit logs confirm escalation event

    Examples:
      | overdue_days | last4 |
      | 31           | 4242  |
      | 45           | 9120  |

  # Collection Notification - Functional and Security
  @api @security
  Scenario Outline: Collection notification includes amount owed, charges, and only last 4 digits
    Given a delinquent cardholder account overdue by <overdue_days> days
    And overdue balance is <overdue_balance> and late charges are <additional_charges>
    When collection notification batch runs
    Then notification includes 'Amount Owed: <overdue_balance>' and 'Additional Charges: <additional_charges>'
    And notification references card ending <last4>
    And full card number is never disclosed in body, headers, or metadata

    Examples:
      | overdue_days | overdue_balance | additional_charges | last4 |
      | 61           | $300.00        | $25.00            | 4242  |
      | 70           | $650.00        | $75.00            | 4123  |

  @boundary
  Scenario Outline: Collection notification boundary values on additional charges
    Given a cardholder account escalated to collections with overdue balance <overdue_balance>
    When collection notification is sent with additional charges <additional_charges>
    Then the notification details 'amount owed: <overdue_balance>' and 'additional charges: <additional_charges>'
    And calculation of total due is correct
    And only last 4 digits <last4> appear for card identification

    Examples:
      | overdue_balance | additional_charges | last4 |
      | $100.00        | $0.00              | 2876  |
      | $100.00        | $15.00             | 2876  |
      | $100.00        | $999.99            | 2876  |

  # Negative: Collections notification not sent before threshold
  @negative
  Scenario Outline: No collection notification before delinquency threshold
    Given a cardholder account overdue by <overdue_days> days (less than threshold)
    And collection escalation is enabled
    When batch job triggers collection notification workflow
    Then no collection notification is sent in <channel>
    And audit logs confirm no collection event for account

    Examples:
      | overdue_days | channel   |
      | 30           | email     |
      | 45           | portal    |

  # Payment Plan Proposal Workflow
  @state-transition
  Scenario Outline: Collection notification escalates to payment plan proposal
    Given a cardholder account in 'Collection Notified' state unable to pay overdue balance
    And payment plan feature enabled
    When payment plan eligibility workflow evaluates cardholder
    And eligibility passes
    Then system sends payment plan proposal with only last 4 digits <last4> as identifier
    And account state transitions to 'Payment Plan Proposal Sent'
    And log entry for proposal issuance contains masking compliance

    Examples:
      | last4 |
      | 4123  |
      | 5619  |

  @api @security
  Scenario Outline: Payment plan proposal includes only last 4 digits
    Given a payment plan proposal is to be sent for overdue account
    When the proposal is generated and delivered in channel <channel>
    Then proposal includes only last 4 digits <last4> as identifier
    And full card number is absent from all proposal content, documents, and metadata

    Examples:
      | last4 | channel   |
      | 4242  | email     |
      | 4242  | portal    |
      | 4242  | attached_document |

  # Negative Payment Plan Proposal
  @negative
  Scenario Outline: No payment plan proposal sent to ineligible cardholder
    Given an account with overdue balance but no payment plan eligibility
    When payment plan proposal workflow triggers
    Then no proposal notification is sent to cardholder
    And audit logs record no proposal event for this account

    Examples:
      | overdue_balance | eligibility |
      | $250.00        | false       |
      | $800.00        | false       |

  @boundary
  Scenario Outline: Payment plan proposal boundary condition for minimum eligible amount
    Given an account with overdue balance <overdue_balance> equals minimum threshold
    And payment plan eligibility confirmed
    When payment plan proposal is requested via portal
    Then proposal displays structured repayment schedule and applies reduced rate/fee
    And only last 4 digits <last4> are presented
    And backend/audit logs exclude full card number

    Examples:
      | overdue_balance | last4  |
      | $500.00        | 1234   |

  @state-transition
  Scenario Outline: Accepting or rejecting payment plan proposal updates account state
    Given a cardholder with payment plan proposal in 'Pending Acceptance' state
    When the cardholder '<action>' the proposal
    Then account state transitions to '<resulting_state>'
    And all related communications and logs reference only last 4 digits <last4> for card
    And no invalid state occurs

    Examples:
      | action  | resulting_state    | last4 |
      | Accept  | In Payment Plan    | 9567  |
      | Reject  | Delinquent        | 9567  |

  # Agency Escalation - Functional, Security, Negative, Boundary
  @api @state-transition
  Scenario Outline: Escalate delinquent account to agency and mask card identifier
    Given a delinquent account with multiple reminders sent and no response
    When escalation workflow triggers agency handoff
    Then agency receives only last 4 digits <last4> for card identification
    And full card number is never present in any data or logs
    And state tracks escalation to agency

    Examples:
      | last4 |
      | 5678  |
      | 9567  |

  @security
  Scenario Outline: Provide only last 4 digits to agency system integration
    Given a delinquent account eligible for agency escalation
    When outgoing payload is sent to agency
    Then payload includes only last 4 digits <last4>
    And no field contains full card number in payload, logs, or transmitted comms

    Examples:
      | last4 |
      | 5678  |

  @negative
  Scenario Outline: No escalation to agency if not eligible (insufficient reminders)
    Given an account with only <reminders> reminders sent
    When escalation to agency is attempted via UI or API
    Then system should block or deny attempt
    And account remains un-escalated
    And error code or rejection notice is logged
    And no agency receives card data

    Examples:
      | reminders |
      | 1         |
      | 2         |

  @boundary
  Scenario Outline: Agency escalation occurs only at exact missed notification count
    Given an account with <missed_notifications> prior notifications without response
    When escalation to agency is attempted
    Then escalation is possible only at threshold <boundary>
    And communications/logs only reference last 4 digits <last4>
    And attempt just before threshold is blocked

    Examples:
      | missed_notifications | boundary | last4 |
      | 3                    | 3        | 5678  |
      | 2                    | 3        | 5678  |

  # Legal Action Workflow - State Transition, Security, Negative, Boundary
  @state-transition
  Scenario Outline: State transition from agency escalation to legal action
    Given an account in 'With Agency' state and defaulted after required duration
    When legal action workflow is triggered
    Then account transitions to 'Legal Action' state
    And legal documentation is generated with only last 4 digits <last4>
    And logs reflect new state and masking compliance

    Examples:
      | last4 |
      | 4242  |
      | 9137  |

  @api @security
  Scenario Outline: Generate legal documentation for defaulted account with correct masking
    Given an account in 'Legal Action' state
    When legal documents are generated and delivered via <channel>
    Then all document content, metadata, and audit logs include only last 4 digits <last4>
    And full card number is never present in any version or log

    Examples:
      | last4 | channel         |
      | 4242  | email           |
      | 4242  | download        |
      | 4242  | printed_copy    |

  @negative
  Scenario Outline: Legal action cannot be triggered if payments resolved early
    Given an overdue account cleared before reaching default threshold
    When legal action workflow is attempted
    Then the option to initiate legal action is not available or blocked
    And no legal documentation is generated
    And audit logs confirm prevention of wrongful escalation

    Examples:
      | overdue_days | payment_status |
      | 25           | resolved       |
      | 29           | settled        |

  @boundary
  Scenario Outline: Legal action boundary initiation after max overdue days
    Given an account at <boundary_minus_one> days overdue
    When legal action workflow is attempted
    Then initiation is blocked prior to threshold
    When account reaches <boundary_day> days overdue
    Then legal action initiation is allowed and successfully generates legal documentation
    And masking rules enforced (last 4 digits only)

    Examples:
      | boundary_minus_one | boundary_day |
      | 29                 | 30           |

  # Masking - Across All Communications
  @security
  Scenario Outline: Masking applies only last 4 digits in all customer-facing collection communications
    Given outbound communications templates are configured for masking
    And collections account with known card number <card_number>
    When reminders, overdue alerts, collection notifications, payment plan proposals, agency escalations, and legal notices are sent via <channel>
    Then each communication displays only last 4 digits <last4> for card reference
    And full card number <card_number> never appears in any communication, log, or document

    Examples:
      | card_number         | last4 | channel   |
      | 5100 9999 8888 6005 | 6005  | email     |
      | 5100 9999 8888 6005 | 6005  | portal    |
      | 5100 9999 8888 6005 | 6005  | SMS       |

  @audit
  Scenario Outline: Full card number never logged in backend or audit
    Given backend log and audit access is enabled for test account <card_number>
    When all collection workflows are triggered (reminder, overdue, collection, plan, agency, legal)
    Then no full card number <card_number> is present in any backend log or audit entry
    And only last 4 digits <last4> are referenced where necessary

    Examples:
      | card_number         | last4 |
      | 5100 1234 5678 9101 | 9101  |

  @negative
  Scenario Outline: Attempt to expose full card number is blocked or triggers error
    Given messaging template or API is manipulated to output full card number <card_number>
    When a notification (reminder, overdue, collections, legal) is triggered
    Then system blocks or flags attempt
    And no communication, log, or document displays full card number <card_number>
    And attempted breach is logged for audit

    Examples:
      | card_number         |
      | 4000 9999 8888 7777 |

  @boundary
  Scenario Outline: Masking deviates from last 4 digits is rejected
    Given masking configuration allows modification
    When template admin sets mask to show <mask_pattern> digits
    And triggers communication for collection event
    Then system enforces masking policy (last 4 digits only)
    And deviating configuration is reverted, blocked, or corrected

    Examples:
      | mask_pattern |
      | last 3       |
      | last 5       |
      | first 4      |
      | middle 6     |

  @audit
  Scenario Outline: Audit logging of masking events for all collection notifications
    Given audit logging is enabled for notification events involving card ending <last4>
    When masking occurs in reminder, overdue, collection, plan, agency, legal communications
    Then each event is written to audit log referencing only last 4 digits <last4>
    And full card number is never logged in any entry

    Examples:
      | last4 |
      | 9567  |

  # State Transition & E2E - Full Lifecycle
  @state-transition @e2e
  Scenario Outline: End-to-end lifecycle: Reminder to Overdue, Collections, Payment Plan, Agency, Legal
    Given an account with credit card ending <last4> and due date <due_date>
    When reminder notification is sent
    And payment is missed; overdue alert triggers
    And account becomes significantly delinquent; collection notification triggers
    And payment plan is generated for unpaid collection; cardholder cannot pay
    And agency escalation is triggered after non-response
    And legal action is initiated after continued default
    Then at every state transition until 'Legal Action Initiation', only last 4 digits <last4> are referenced in notifications and logs
    And audit logs show sequential state progressions with all data masked

    Examples:
      | last4 | due_date   |
      | 4242  | 2024-06-24 |

  # Notification Channel and Delivery - Multi-channel, Retry, Masking
  @api @functional
  Scenario Outline: Notification delivered via all channels with masking
    Given account <account_email> with upcoming payment due, card ending <last4>
    When Credit Card Due Reminder is triggered
    Then email notification is sent to <account_email> and includes only <last4>
    And SMS notification is sent and includes only <last4>
    And portal notification is posted referencing only <last4>
    And audit logs confirm masking compliance

    Examples:
      | account_email         | last4 |
      | testuser@example.com  | 4242  |

  @negative
  Scenario Outline: Notification delivery failure triggers retry with proper masking
    Given account <account_email> with upcoming payment due
    And communication channel <channel> is unavailable (failure injected)
    When due reminder is triggered
    Then notification delivery fails and is logged
    And retry process triggers, and successful delivery is logged
    And all sent and failed messages reference only last 4 digits <last4>
    And no full card number is ever exposed in logs or communications

    Examples:
      | account_email         | channel | last4 |
      | testuser@example.com  | email   | 4242  |

  @security
  Scenario Outline: Notification content validates masking across all channels
    Given notification workflows enabled for account ending <last4>
    When notification is delivered via <channel> for reminder, overdue, collection, plan, agency, legal
    Then content includes only last 4 digits <last4>
    And never full card number or extra digits
    And repeat for each notification type; confirm compliance

    Examples:
      | last4 | channel   |
      | 4242  | email     |
      | 4242  | portal    |
      | 4242  | SMS       |

  @audit
  Scenario Outline: Audit log for all notification deliveries includes only last 4 digits
    Given audit logging system is enabled for account ending <last4>
    When any notification is sent (reminder, overdue, collection, plan, agency, legal)
    Then audit log reference includes only last 4 digits <last4>
    And no log entry ever contains full card number

    Examples:
      | last4 |
      | 4242  |

  # Amount Calculation - Reminder and Overdue
  @api @functional
  Scenario Outline: Validate amount due calculation on reminders and overdue alerts
    Given an account <account_id> with statement balance <balance> and due date <due_date>
    When Credit Card Due Reminder workflow triggers
    Then reminder notification displays 'Amount Due: <balance>' and only last 4 digits <last4>
    And backend statement and notification amount match for <account_id>
    And full card number is never included

    Examples:
      | account_id | balance   | due_date   | last4 |
      | ACC123     | $350.00   | 2024-06-26 | 1245  |
      | ACC123     | $0.00     | 2024-06-26 | 1245  |
      | ACC123     | $8,000.00 | 2024-06-26 | 1245  |

  Scenario Outline: Validate overdue amount calculation post due date in overdue alerts
    Given an account <account_id> with statement balance <balance> and payment due date <due_date> missed
    And overdue workflow is enabled
    When overdue alert is triggered
    Then notification displays overdue balance <overdue_balance> and late fee <late_fee>
    And only last 4 digits <last4> are present in notification
    And backend record matches notification value

    Examples:
      | account_id | balance   | due_date   | overdue_balance | late_fee | last4 |
      | ACC987     | $350.00   | 2024-06-20 | $375.00         | $25      | 1259  |
      | ACC987     | $7,800.00 | 2024-05-05 | $7,825.00       | $25      | 1259  |

  # Correct Notification Attribution and Masking
  @api @security
  Scenario Outline: Notification attributed to correct cardholder only; masking enforced
    Given cardholder <cardholder> with card ending <last4> and another cardholder 'Other' with card ending <diff_last4>
    When payment-related notification is triggered
    Then notification is delivered only to <cardholder>'s contact channel, referencing only <last4>
    And no notification is delivered to 'Other' or references <diff_last4>
    And no full card number is shown in any message, log, or export

    Examples:
      | cardholder   | last4 | diff_last4 |
      | John Test    | 4242  | 9831       |

