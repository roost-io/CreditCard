Feature: Credit Card Collection Lifecycle Communication and Data Masking

  # Background setup: Configuring test environment base URL, authorization, and notifications
  Background:
    Given the API base URL is "https://testcardsystem.example.com"
    And the authorization token is set for test admin or system user
    And notification system is enabled

  # API & Backend Notification Tests
  @api @functional
  Scenario Outline: Send Automated Due Reminder Notification With Masked Card Digits
    Given a cardholder account '<accountId>' exists with card ending '<last4>' and due date in <daysToDue> days
    And no previous due reminder sent for this cycle
    And notifications are enabled for the account
    When I trigger the batch job for due reminder notifications
    Then the notification should be sent to the cardholder
    And the notification content should include only the last 4 digits '<last4>' in masked format '**** **** **** <last4>'
    And the payment due date '<dueDate>' is present in the notification
    And the full card number is not exposed in any notification, log, or audit entry
    And the notification status should be 'sent'

    Examples:
      | accountId   | last4 | daysToDue | dueDate        |
      | 8722Acc     | 8722  | 3         | 2024-06-07     |
      | 4567Acc     | 4567  | 5         | 2024-06-09     |

  @api @security
  Scenario Outline: Validate No Full Card Number is Exposed in Due Reminder Notification Artifacts
    Given cardholder account '<accountId>' with card number '<cardNumber>' and pending payment
    And notifications are enabled for the account
    When I trigger the batch job for due reminders
    Then search all notification payloads, logs, message queues, and database for '<cardNumber>'
    And assert only masked last 4 digits '<last4>' appear in format '**** **** **** <last4>'
    And no full or partial card number (other than last 4) appears anywhere

    Examples:
      | accountId    | cardNumber            | last4 |
      | 5162Acc      | 5162314112348722      | 8722  |
      | 4535Acc      | 4535123456789001      | 9001  |

  @api @functional
  Scenario Outline: Send Overdue Alert Notification After Missed Payment Date
    Given a cardholder account '<accountId>' with card ending '<last4>'
    And the payment due date has passed by <daysPastDue> days
    And no payment received after due date
    When I trigger the batch job for overdue alert notifications
    Then the overdue alert notification is sent with overdue amount '<overdueAmount>' and masked card number '**** **** **** <last4>'
    And the full card number is not present anywhere in the message or logs
    And notification status is 'sent'
    And audit/log entries reflect correct event and message

    Examples:
      | accountId    | last4 | daysPastDue | overdueAmount |
      | 6533Acc      | 6533  | 1           | $85           |
      | 7800Acc      | 7800  | 2           | $142          |

  @api @negative
  Scenario Outline: Do Not Send Overdue Alert If Payment Was Made Before Due Date
    Given a test account '<accountId>' with card ending '<last4>' and due date '<dueDate>'
    And payment in full was posted one day before due date
    When I run the overdue alert batch process
    Then no overdue alert is sent or visible for the account in logs, notifications, or event tables
    And the audit log shows payment posted and no alert event

    Examples:
      | accountId   | last4 | dueDate      |
      | 4901Acc     | 4901  | 2024-06-08   |
      | 2730Acc     | 2730  | 2024-06-09   |

  @api @functional
  Scenario Outline: Collection Notification Sent for Significantly Delinquent Accounts
    Given the account '<accountId>' is in delinquent status for <daysDelinquent> days with card ending '<last4>'
    And collection notifications are enabled
    When I trigger the collection notification job
    Then the collection notification is sent to the cardholder including amount owed '<amountOwed>' and only masked card number '**** **** **** <last4>'
    And audit and notification logs reflect the event record
    And no full or unmasked card number appears in any field

    Examples:
      | accountId    | last4 | daysDelinquent | amountOwed |
      | 6019Acc      | 6019  | 32             | $1800      |
      | 5200Acc      | 5200  | 45             | $3250      |

  @api @security
  Scenario Outline: Collection Notifications Display Only Last 4 Digits in All Channels
    Given an account '<accountId>' is overdue and flagged for collection notices with card ending '<last4>'
    When I launch the collection notification job
    Then all communication channels and logs related to collection notification show only masked card number '**** **** **** <last4>', never full PAN

    Examples:
      | accountId    | last4 |
      | 1226Acc      | 1226  |
      | 3337Acc      | 3337  |

  @api @functional
  Scenario Outline: Payment Plan Proposal Triggered for Unable-to-Pay Cardholder
    Given account '<accountId>' is overdue, eligible for payment plan, and has card ending '<last4>'
    When I initiate payment plan proposal via system action or API
    Then the payment plan proposal notification includes repayment schedule, reduced fees, and only masked card number '**** **** **** <last4>'
    And log/audit entries confirm correct event and no unmasked card data

    Examples:
      | accountId    | last4 |
      | 4105Acc      | 4105  |
      | 8991Acc      | 8991  |

  @api @security
  Scenario Outline: Payment Plan Proposal Notification Complies With Card Masking
    Given payment plan proposal triggered for account '<accountId>' with card ending '<last4>'
    And notification system is enabled
    When I retrieve payment plan proposal notification and logs
    Then only masked card number '**** **** **** <last4>' should appear in all message channels and logs
    And no full or partial unmasked card number appears in any output

    Examples:
      | accountId   | last4 |
      | 5777Acc     | 5777  |
      | 4105Acc     | 4105  |

  @api @negative
  Scenario Outline: Payment Plan Proposal Not Sent if Balance Is Paid in Full
    Given overdue flag cleared by recent full payment for account '<accountId>' with card ending '<last4>'
    And payment plan proposal job is enabled
    When I trigger payment plan proposal
    Then no payment plan proposal notification is generated, logged, or shown for the account
    And audit logs, notification endpoints, and UI lack payment plan proposal events

    Examples:
      | accountId   | last4 |
      | 3278Acc     | 3278  |
      | 8944Acc     | 8944  |

  @api @state-transition
  Scenario Outline: Escalate to Collection Agency After Failed Notifications
    Given overdue account '<accountId>' in 'collection escalation' queue with card ending '<last4>'
    And overdue for >60 days, all prior notifications sent with no payment or user response
    And collection agency integration configured
    When I trigger agency handoff process
    Then account status transitions from 'delinquent' to 'in collection agency'
    And agency receives only the last 4 digits '<last4>' in outbound payload or records
    And no other card details or PII are transmitted
    And audit/data export logs reflect transition event and data snapshot

    Examples:
      | accountId   | last4 |
      | 8845Acc     | 8845  |
      | 7790Acc     | 7790  |

  @api @security
  Scenario Outline: Transmit Only Last 4 Digits to Collection Agency
    Given overdue account '<accountId>' with card ending '<last4>' eligible for agency escalation
    When I trigger the collection agency workflow and capture outbound API payload
    Then data sent to agency contains only masked card number '**** **** **** <last4>'
    And agency system records show only last 4 digits
    And audit trail evidences transmission with masking enforcement

    Examples:
      | accountId   | last4 |
      | 4242Acc     | 4242  |
      | 8788Acc     | 8788  |

  @api @negative
  Scenario Outline: Agency Handoff Blocked for Ineligible Accounts
    Given overdue account '<accountId>' with partial payment or incomplete notifications, card ending '<last4>'
    When I attempt escalation to collection agency
    Then handoff request is blocked due to ineligibility
    And no data is transmitted to agency
    And audit log shows handoff prevention with reason code

    Examples:
      | accountId   | last4 |
      | 7900Acc     | 7900  |
      | 3099Acc     | 3099  |

  @api @functional
  Scenario Outline: Legal Action Triggered for Defaulted Accounts
    Given account '<accountId>' marked 'default' after full escalation path completed, card ending '<last4>'
    When legal action initiation is triggered
    Then legal documentation is generated per template with only last 4 digits '<last4>' masked in all fields
    And audit log records legal escalation event

    Examples:
      | accountId    | last4  |
      | 4123Acc      | 4123   |
      | 2244Acc      | 2244   |

  @api @security
  Scenario Outline: Legal Documentation Must Include Only Last 4 Digits of Card Number
    Given legal escalation path is triggered for account '<accountId>' with card ending '<last4>'
    When I retrieve generated legal documents (PDF, e-doc, etc.)
    Then every field, section, and attachment displays only masked card '**** **** **** <last4>'
    And no unmasked or partial PAN is present anywhere in the documentation

    Examples:
      | accountId   | last4 |
      | 4242Acc     | 4242  |
      | 5432Acc     | 5432  |

  @api @security
  Scenario Outline: Masking Validation for All Lifecycle Communications
    Given account '<accountId>' moves through reminder, alert, collection, payment plan, agency, legal stages with card ending '<last4>'
    When I trigger each lifecycle communication and inspect payloads/messages/logs
    Then only masked card number (last 4 digits '<last4>') is included
    And no full or partial PAN appears in any communication or audit log

    Examples:
      | accountId   | last4 |
      | 9001Acc     | 9001  |
      | 4242Acc     | 4242  |

  @api @security
  Scenario Outline: No Full Card Number in Internal Audit Logs
    Given audit logging enabled for all collection lifecycle events for account '<accountId>' with card ending '<last4>'
    When I perform reminder, overdue, collection, agency, legal actions
    Then audit logs contain only masked card number '**** **** **** <last4>'
    And no full or partial PAN appears in any log entry
    And attempts to inject unmasked PAN are sanitized or blocked

    Examples:
      | accountId   | last4 |
      | 4242Acc     | 4242  |
      | 9001Acc     | 9001  |

  @api @negative
  Scenario Outline: Flag and Reject Notification With Incorrect Masking
    Given notification engine supports content validation and cardholder account '<accountId>' exists
    And I tamper with notification template to include incorrect masking (e.g., partial mask or >4 digits unmasked)
    When I trigger an outbound notification (overdue, collection, legal)
    Then the system flags the notification for improper masking
    And the message is rejected or quarantined
    And error logs record explicit masking violation
    And no improperly masked notification is delivered

    Examples:
      | accountId   |
      | 8299Acc     |
      | 1123Acc     |

  @api @security
  Scenario Outline: Block Outbound Communication Containing Full Card Number
    Given notification processing pipeline supports card number validation
    And a message with full PAN ('<fullCardNumber>') is submitted for delivery
    When I trigger outbound communication processing
    Then the system detects the unmasked PAN and blocks or quarantines the message
    And security incident is logged with full details
    And no full card number is ever sent to recipient or external system

    Examples:
      | fullCardNumber           |
      | 1234 5678 9012 3456      |
      | 4111 1111 1111 4242      |

  @api @functional
  Scenario Outline: Notification Contains Correct Fields and Message Structure
    Given account '<accountId>' is eligible for notification with card ending '<last4>', due date '<dueDate>', and amount due '<amountDue>'
    And notification templates are configured correctly
    When system sends notification for stage '<stage>'
    Then notification content includes cardholder name, last 4 digits '<last4>', due date '<dueDate>', and amount due '<amountDue>'
    And notification structure is user-readable and contains no missing fields

    Examples:
      | accountId   | last4 | dueDate      | amountDue | stage              |
      | 4242Acc     | 4242  | 2024-06-07   | $250      | Due Reminder       |
      | 9001Acc     | 9001  | 2024-06-10   | $310      | Overdue Alert      |
      | 4105Acc     | 4105  | 2024-05-25   | $1550     | Payment Plan       |

  @api @negative
  Scenario Outline: Reject Notification If Required Fields Missing
    Given notification generator supports faulty templates
    And account '<accountId>' is due for notification
    And template is missing '<missingField>'
    When system attempts to send notification
    Then notification is rejected and not delivered
    And error and audit logs record explicit missing field message

    Examples:
      | accountId   | missingField         |
      | 5723Acc     | last 4 digits        |
      | 4105Acc     | amount due           |
      | 9001Acc     | due date             |

  @api @security
  Scenario Outline: Notification Sent Only To Authorized Cardholder
    Given cardholder account '<accountId>' with primary email '<authorizedEmail>' and phone '<authorizedPhone>', card ending '<last4>'
    And unauthorized account '<unauthEmail>' exists
    When automated due reminder notification workflow is triggered
    Then notification is sent only to '<authorizedEmail>' or '<authorizedPhone>'
    And the masked card number '**** **** **** <last4>' appears in the notification
    And no notification is sent to any unauthorized user (e.g., '<unauthEmail>')
    And logs/audit confirm strictly authorized delivery and data masking

    Examples:
      | accountId   | authorizedEmail                | authorizedPhone   | last4 | unauthEmail                    |
      | 4242Acc     | test+cardholder001@example.com | +14557890001      | 4242  | test+intruder021@example.com   |

  @api @security
  Scenario Outline: Collection Agency Access Limited to Assigned Accounts Only
    Given agency user '<agencyUser>' is logged in and assigned to accounts '<assignedAccounts>'
    And each assigned account has card ending '<assignedLast4>'
    And at least one unassigned account '<unassignedAccount>' with card ending '<unassignedLast4>' exists
    When agency requests list and details of assigned accounts
    Then only assigned accounts are accessible; all others return access denied
    And only masked card numbers '<assignedLast4>' are displayed or exported
    And no full card numbers or unrelated PII appear anywhere in agency-accessible screens/exports

    Examples:
      | agencyUser | assignedAccounts | assignedLast4 | unassignedAccount | unassignedLast4 |
      | AlphaAgent | 100234           | 5678          | 100235            | 3210            |

  @api @functional
  Scenario Outline: Log and Retry Failed Notification Transmission With PII Masking
    Given delinquent account '<accountId>' with card ending '<last4>' is set to notify
    And notification transmission is configured to fail (e.g., simulate SMTP 500)
    When notification workflow is triggered and transmission fails
    Then system logs the failed event with only masked card number '<last4>' present
    And initiates exactly one retry as per policy; retry attempt is logged and audited
    And no full card number appears in any failed/success logs or error payloads

    Examples:
      | accountId   | last4 |
      | 9876Acc     | 9876  |
      | 4444Acc     | 4444  |

  @api @functional
  Scenario Outline: Raise Incident for Undeliverable Collection Notifications
    Given overdue account '<accountId>' eligible for collection notification, card ending '<last4>'
    And notification endpoints are invalid to simulate delivery failure
    And incident management system is enabled
    When all allowed notification retries fail
    Then notification status is marked 'undeliverable'
    And an incident/ticket is raised containing only masked card number '<last4>'
    And no further collection/legal process is allowed until resolution

    Examples:
      | accountId   | last4 |
      | 9201Acc     | 9201  |
      | 6543Acc     | 6543  |

  @api @negative
  Scenario Outline: Prevent Escalation If Data Error Detected
    Given delinquent account '<accountId>' with card number '<invalidCardNumber>' and blank email
    And escalation workflow is enabled
    When escalation to collection notification or legal action is attempted
    Then system blocks escalation with clear data error status/message
    And no notification is sent until all mandatory data fields are corrected

    Examples:
      | accountId   | invalidCardNumber |
      | 401234Acc   | 123X              |
      | 7835Acc     | 872               |

  @api @audit
  Scenario Outline: Audit Log Integrity for Legal and Collection Events
    Given account '<accountId>' at legal action initiation or collection escalation stage with card ending '<last4>'
    And immutable audit subsystem is enabled
    When legal or collection event is triggered
    Then audit log entry is written with masked card '**** **** **** <last4>', event timestamp, and user ID
    And attempts to alter or delete audit log fail or generate alert
    And no log entry exposes full card number

    Examples:
      | accountId   | last4 |
      | 4123Acc     | 4123  |
      | 772910Acc   | 4123  |

  # API/State Transition & Boundary Condition Scenarios
  @api @state-transition
  Scenario Outline: Valid State Transitions From Due → Overdue → Collections
    Given account '<accountId>' with due date '<dueDate>' and no payment made for <daysOverdue> days
    And collections trigger threshold is <collectionsThreshold> days overdue
    When due reminder is sent, payment is missed, and overdue alert is triggered
    Then account automatically transitions from Due to Overdue and, at threshold, to Collections
    And all state transitions and notifications contain only masked card number '**** **** **** <last4>'
    And manual attempts to skip states are rejected

    Examples:
      | accountId   | dueDate      | daysOverdue | collectionsThreshold | last4 |
      | 143160Acc   | 2024-06-01   | 8           | 7                   | 1600  |

  @api @state-transition
  Scenario Outline: Failed Payment Plan Acceptance Reverts To Collections
    Given account '<accountId>' in Collections with payment plan proposal generated, response window is <windowDays> days
    When cardholder fails to respond or explicitly rejects within window
    Then account remains or reverts to Collections
    And collection notification is sent in masked form
    And audit log reflects proposal status and state transitions

    Examples:
      | accountId   | windowDays |
      | 604499Acc   | 5          |

  @api @negative
  Scenario Outline: Block Re-entry Into Payment Plan After Legal Action Initiation
    Given account '<accountId>' is already in Legal Action status with card ending '<last4>'
    When user or system attempts to initiate or accept a payment plan offer (via API, UI, or manual entry)
    Then request is denied with 'INELIGIBLE_STATE' status
    And no payment plan record is created for account
    And audit logs reflect blocked attempt with masked card info only

    Examples:
      | accountId   | last4 |
      | 980123Acc   | 5432  |
      | 310088Acc   | 9001  |

  @api @boundary
  Scenario Outline: Boundary Test - Collection Notification Triggered Exactly At Overdue Days Threshold
    Given account '<accountId>' is overdue by <overdueDays> days and collection threshold is <threshold> days
    When overdue check batch job is triggered
    Then at (threshold-1) days, no collection notification is sent
    And at threshold days, collection notification is sent with masked card number '**** **** **** <last4>' and correct amount owed
    And full card number is absent in all notifications and logs

    Examples:
      | accountId   | overdueDays | threshold | last4   | amountOwed |
      | testuserA   | 29          | 30        | 4242    | $500       |
      | testuserA   | 30          | 30        | 4242    | $510       |

  @api @boundary
  Scenario Outline: Boundary Test - Legal Escalation Triggered Only At Threshold Day
    Given account '<accountId>' overdue by <overdueDays> days, legal escalation threshold is <legalThreshold> days
    When I trigger legal escalation batch process
    Then no legal action is triggered at (threshold-1) days
    And legal action is triggered at threshold
    And legal notification contains only masked card number '**** **** **** <last4>'
    And legal event is audit-logged

    Examples:
      | accountId   | overdueDays | legalThreshold | last4   |
      | testuserB   | 89          | 90            | 2244    |
      | testuserB   | 90          | 90            | 2244    |

  @api @security
  Scenario Outline: API Sends Only Approved Fields To Collection Agency
    Given account '<accountId>' overdue and met agency escalation criteria, card ending '<last4>'
    When collection agency handoff is triggered via API
    Then API payload contains only 'accountId', 'customerName', and 'last4' (masked card number)
    And no other sensitive data is present in the payload
    And audit logs reference only masked card data
    And attempts to inject unmasked card number are blocked/masked

    Examples:
      | accountId   | last4 |
      | testuserC   | 8788  |

  @api @negative
  Scenario Outline: No Duplicate Agency Handoffs For Single Account
    Given account '<accountId>' is overdue and eligible for agency escalation
    When escalation procedure is triggered multiple times in rapid succession
    Then only a single agency handoff event and notification is created
    And subsequent triggers are suppressed or ignored as per idempotency logic
    And audit logs contain only one escalation event per account

    Examples:
      | accountId   |
      | testuserD   |

  @api @functional
  Scenario Outline: Outbound Notification Data Must Match Customer and Account
    Given accounts '<accountIdE>' and '<accountIdF>' exist with unique cards '<last4E>' and '<last4F>'
    And both are at distinct collection lifecycle stages
    When system sends notifications for each account
    Then each notification includes the correct due date, amount owed, and only the last 4 digits for respective card
    And any attempt to send cross-customer data is blocked and logged

    Examples:
      | accountIdE   | last4E | accountIdF   | last4F  | stageE        | stageF           |
      | testuserE    | 1122   | testuserF    | 2211    | Overdue Alert | Payment Plan     |

  # End-to-End Lifecycle Scenario
  @api @e2e
  Scenario: Full Lifecycle: Due Reminder → Overdue → Collections → Payment Plan → Agency → Legal
    Given customer account 'testuserG' with unique card number '**** **** **** 9001' is created
    And notification, overdue batch, collections, agency, and legal modules are enabled
    When system triggers due reminder notification prior to payment due date
    And payment due date passes with no payment
    And overdue alert notification is generated
    And after 30 days, collections notification is triggered
    And payment plan proposal is generated after collection stage
    And continued non-response leads to collection agency handoff
    And subsequent default triggers legal action and notification
    Then at each step, notification is generated with correct, masked card data (last 4 digits only)
    And system audit logs present all transition and escalation events with compliant data masking

