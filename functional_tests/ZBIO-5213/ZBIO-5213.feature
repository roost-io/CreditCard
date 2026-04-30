Feature: Credit Card Collection Workflow – Masking, Compliance, Audit & Integration

  # Background for API and workflow tests
  Background:
    Given the API base URL is set
    And audit and masking enforcement are enabled
    And user authentication is available for cardholder, agency, legal staff, and administrator roles

  # API Workflow & Masking Tests
  @api
  Scenario Outline: Automated Credit Card Due Reminder Notification – Masking & Audit Compliance
    Given a cardholder account "<account_id>" with next payment due in <due_in_days> days and no prior reminders in window
    When system triggers due reminder notification job
    Then notification is delivered to cardholder via "<channel>" containing only last 4 digits "<last_4>" of card "<card_number>"
    And notification payload does NOT expose full or partial card number (only last 4 digits)
    And notification includes correct due date "<due_date>", amount "<due_amount>", and cardholder name "<cardholder_name>"
    And audit log records notification event, cardholder role, and masking compliance

    Examples:
      | account_id | card_number        | last_4 | due_in_days | channel | due_date    | due_amount | cardholder_name |
      | 12345      | 4012888888881881   | 1881   | 5           | email   | 2024-07-15  | $500.00    | Alice Smith     |
      | 67890      | 5555555555554444   | 4444   | 7           | sms     | 2024-07-17  | $1000.00   | Bob Johnson     |

  @api
  Scenario Outline: Overdue Balance Alert with State Transition – Masking Branch Coverage
    Given a credit card account "<account_id>" with payment due date <due_date> and payment status "<payment_status>"
    When due date passes and system triggers overdue processing
    Then overdue alert is sent ONLY if payment is "<alert_status>"
    And alert includes only last 4 digits "<last_4>" of card "<card_number>"
    And overdue amount "<overdue_amount>" and consequences are correct per payment variation
    And event/state change are recorded in audit log

    Examples:
      | account_id | card_number        | last_4 | due_date    | payment_status | alert_status | overdue_amount |
      | 12345      | 4012888888881881   | 1881   | 2024-07-15  | unpaid         | sent         | $500.00       |
      | 67890      | 5555555555554444   | 4444   | 2024-07-15  | partial        | sent         | $200.00       |
      | 24680      | 4111111111111111   | 1111   | 2024-07-15  | late_full      | not_sent     | $0.00         |

  @api
  Scenario Outline: Collection Notification Trigger at Delinquency Boundary with Fee Calculation
    Given credit card "<card_id>" is overdue for "<overdue_days>" days
    When system triggers collection notification processing
    Then collection notification is sent only when delinquency threshold "<trigger_days>" is reached
    And notification includes overdue amount "<overdue_amount>", late fee "<late_fee>", and only last 4 digits "<last_4>" of card "<card_number>"
    And audit log records the event and fee computation
    And no full card number appears in any notification or log

    Examples:
      | card_id | card_number      | last_4 | overdue_days | trigger_days | overdue_amount | late_fee |
      | 12345   | 4012888888881881 | 1881   | 29           | 30           | $500.00       | $0.00    |
      | 12345   | 4012888888881881 | 1881   | 30           | 30           | $510.00       | $10.00   |
      | 67890   | 5555555555554444 | 4444   | 31           | 30           | $1020.00      | $20.00   |

  @api
  Scenario Outline: Collection Agency Data Hand-Off via Secure API – Masked Integration & Error Handling
    Given delinquent account "<account_id>" eligible for agency escalation and agency endpoint "<agency_api>"
    When system prepares and transmits data package:
      """
      {
        "balance_due": "<balance_due>",
        "cardholder_name": "<cardholder_name>",
        "last_4_digits": "<last_4>"
      }
      """
      to agency API endpoint "<agency_api>"
    Then agency system receives masked data and acknowledges receipt
    And audit log records the transmission with sender, recipient, included fields, and masking status
    And integration errors (incomplete/rejected transmission) are logged and handled

    Examples:
      | account_id | agency_api        | balance_due | cardholder_name | card_number | last_4 |
      | 12345      | /api/agency/hand | $800.00     | Alice Smith     | 4012888888881881 | 1881 |
      | 67890      | /api/agency/hand | $1200.00    | Bob Johnson     | 5555555555554444 | 4444 |
      | 24680      | /api/agency/hand | $1500.00    | Carol Lee       | 4111111111111111 | 1111 |

  @api
  Scenario Outline: Collection Agency Escalation at Policy Day Threshold with Error Handling
    Given account "<account_id>" is overdue for <overdue_days> days and agency escalation boundary is <boundary_days>
    When system attempts to escalate to collection agency via API
    Then escalation occurs only if overdue days meet threshold and API transmission includes only last 4 digits "<last_4>" of card "<card_number>"
    And audit log reflects transmission, masking, and response (success/error)
    And API masking errors or missing data trigger retry or block per policy

    Examples:
      | account_id | overdue_days | boundary_days | card_number | last_4 | api_status   |
      | 12345      | 44           | 45            | 4012888888881881 | 1881 | not_triggered |
      | 12345      | 45           | 45            | 4012888888881881 | 1881 | triggered     |
      | 67890      | 46           | 45            | 5555555555554444 | 4444 | triggered     |

  # End-to-End Workflow & Masking
  @e2e
  Scenario: Full Credit Card Collection Lifecycle from Reminder to Legal Action
    Given a cardholder account "<account_id>" with valid card, due date, and escalation thresholds set
    When system advances through lifecycle stages: due reminder, overdue, collection, payment plan proposal, agency handoff, legal escalation
    Then at each stage, notifications, documents, and API transmissions include ONLY last 4 digits "<last_4>" of card "<card_number>"
    And all state transitions are tracked and logged in audit trail
    And no full card data is exposed in any notification, document, or log
    And regulatory compliance is validated at every transition

  @e2e
  Scenario Outline: Regulatory Audit Trail Verification across All Collection Lifecycle Events
    Given cardholder account "<account_id>" undergoes reminder, overdue, collection, payment plan, agency, legal, and error event stages
    When each notification, transition, and escalation event occurs
    Then audit logs capture masked card digits "<last_4>", event type, recipient, role, timestamp, and regulatory compliance fields
    And logs are complete, ordered, and accurate across all lifecycle events
    And no exposure of full card information occurs

    Examples:
      | account_id | card_number      | last_4 |
      | 12345      | 4012888888881881 | 1881   |
      | 67890      | 5555555555554444 | 4444   |

  @e2e
  Scenario: Audit and Masking Validation during External Document Generation for Collection Agency and Legal Partners
    Given account in collection/agency/legal state and partner endpoints available
    When system generates and transmits external documents with necessary data (agency/legal forms)
    Then documents include ONLY last 4 digits "<last_4>" of card
    And secure transmission, receipt, and audit logging are completed
    And any document generation with full card number is blocked and logged as error

  @e2e
  Scenario: Cross-Account Data Integrity and State Transition
    Given multiple credit card accounts "<account_A>" and "<account_B>" with separate overdue statuses
    When workflows are triggered for each account (reminder, overdue, collection, agency, legal, reversal)
    Then messages and logs reference ONLY correct account and last 4 digits
    And no cross-account data appears in any communication or audit record
    And state transitions are account-specific and comply with regulatory mandates

  @e2e
  Scenario: Lifecycle Interruption and Recovery After System Outage with Masking Assurance
    Given accounts in active collection lifecycle states and system outage occurs
    When system recovers and resumes pending workflow steps
    Then all resumed notifications and documents contain only last 4 digits
    And audit log records outage period, paused actions, recovery events, and correct masking compliance
    And no duplicate, out-of-order, or unmasked notifications after recovery

  # Negative Path & Error Handling API Tests
  @negative
  Scenario Outline: PII Masking Failure and Notification Transmission Exception Handling
    Given simulated notification generation with full card number "<card_number>" in payload or undeliverable contact "<contact>"
    When system scans and attempts transmission
    Then notification containing full card number is blocked and logged in audit
    And administrator is alerted of masking error via error report
    And notification transmission failures due to undeliverable contact are retried up to "<retry_limit>" attempts, with audit logging and escalation
    And NO unauthorized data transmission occurs

    Examples:
      | card_number        | contact    | retry_limit |
      | 4012888888881881   | bad.email  | 3           |
      | 5555555555554444   | +123456789 | 3           |

  @negative
  Scenario Outline: Unauthorized Access Attempt and Cross-Account Data Leakage Prevention
    Given user "<role>" attempts to view/send collection notification or audit logs for "<target_account>" as unauthorized
    When system checks privilege matrix and access attempt
    Then action is blocked and audit log records denied access with responsible user, role, and event
    And NO cardholder/account/masked card data is leaked in notification or log
    And cross-account reference attempts are detected and prevented

    Examples:
      | role         | target_account | expected_log     |
      | staff        | 12345          | access_denied    |
      | external     | 67890          | access_denied    |

  @negative
  Scenario Outline: Payment Plan Enrollment Failure and Error Notification
    Given cardholder "<cardholder_name>" attempts payment plan enrollment with "<failure_type>"
    When system detects error or invalid terms
    Then masked error notification is sent (only last 4 digits "<last_4>")
    And audit log records failure event and rejected enrollment
    And workflow reverts to previous state without exposing sensitive card info

    Examples:
      | cardholder_name | failure_type         | card_number      | last_4 |
      | Alice Smith     | technical_error      | 4012888888881881 | 1881   |
      | Bob Johnson     | invalid_installment  | 5555555555554444 | 4444   |

  @negative
  Scenario: Payment Plan Terms Violation Without Legal Escalation
    Given account on payment plan with minor violation (late/partial payment below escalation threshold)
    When system detects breach and triggers collection workflow
    Then collection notifications include only last 4 digits
    And no premature agency/legal escalation occurs
    And audit log covers all workflow events and masking compliance

  @negative
  Scenario Outline: Partial Payment Plan Acceptance and Workflow Handling Variations
    Given payment plan proposal has been sent to cardholder "<cardholder_name>" with masked card info "<last_4>"
    When cardholder "<response_type>" the plan or breaches terms
    Then system modifies plan, escalates, or triggers breach process as per business rules
    And all communications and audit logs include only last 4 digits
    And workflow state transitions and regulatory compliance are validated

    Examples:
      | cardholder_name | response_type | card_number      | last_4 |
      | Alice Smith     | partial_accept| 4012888888881881 | 1881   |
      | Bob Johnson     | refuse        | 5555555555554444 | 4444   |
      | Carol Lee       | breach        | 4111111111111111 | 1111   |

  # Real-Time Dynamic Masking and Notification Adjustment API Tests
  @api
  Scenario Outline: Collection Notification with Dynamic Overdue Amount Adjustment
    Given account "<account_id>" in collection state with current overdue balance "<overdue_amount>" and masked card "<last_4>"
    When cardholder makes partial payment "<payment_amount>"
    Then system updates overdue balance and generates new notification with only last 4 digits
    And audit log records all balance changes and masking compliance
    And attempted notifications with stale/incorrect balance are blocked/logged

    Examples:
      | account_id | overdue_amount | payment_amount | card_number      | last_4 |
      | 12345      | $500.00        | $100.00        | 4012888888881881 | 1881   |
      | 67890      | $1000.00       | $250.00        | 5555555555554444 | 4444   |

  # Masked Legal Action API Tests
  @api
  Scenario Outline: Legal Action Documentation Generation and Transmission with Card Masking Enforcement
    Given account "<account_id>" in default and legal escalation workflow enabled
    When system generates legal documents (summons, complaints) for "<recipient_type>"
    Then documents contain ONLY last 4 digits "<last_4>" of card
    And audit logs capture generation, transmission, recipients, and masking compliance
    And regulatory compliance of legal documentation is validated

    Examples:
      | account_id | recipient_type | card_number      | last_4 |
      | 12345      | cardholder     | 4012888888881881 | 1881   |
      | 12345      | legal_staff    | 4012888888881881 | 1881   |
      | 67890      | cardholder     | 5555555555554444 | 4444   |
      | 67890      | agency         | 5555555555554444 | 4444   |

  # Payment Plan Proposal Boundary & Compliance API
  @api
  Scenario Outline: Payment Plan Proposal Timing and Compliance with Masking Enforcement
    Given credit card account "<account_id>" is overdue for "<overdue_days>" days and collection notification has been sent
    When payment plan eligibility window (<min_days> to <max_days> overdue) is checked
    Then proposal is sent ONLY if overdue days are within window, including only last 4 digits "<last_4>" and regulatory terms
    And proposal and audit log are compliant with masking and regulatory requirements

    Examples:
      | account_id | overdue_days | min_days | max_days | card_number      | last_4 |
      | 12345      | 14           | 15       | 30       | 4012888888881881 | 1881   |
      | 12345      | 15           | 15       | 30       | 4012888888881881 | 1881   |
      | 67890      | 31           | 15       | 30       | 5555555555554444 | 4444   |

  # Multi-Channel Notification & Masking API Tests
  @api @multi-channel
  Scenario Outline: Multi-Channel Notification Content Verification and Role-Specific Masking
    Given notification template is ready for "<channel>" and recipient role "<role>" at workflow stage "<stage>"
    When notification is triggered for cardholder "<cardholder_name>" with last 4 digits "<last_4>"
    Then delivered message contains only last 4 digits and is formatted according to channel and role
    And audit log records channel, masking, recipient, and event details
    And notifications with improper masking are blocked/logged

    Examples:
      | channel   | role        | stage      | cardholder_name | card_number      | last_4 |
      | email     | cardholder  | reminder   | Alice Smith     | 4012888888881881 | 1881   |
      | sms       | cardholder  | overdue    | Bob Johnson     | 5555555555554444 | 4444   |
      | in-app    | cardholder  | collection | Carol Lee       | 4111111111111111 | 1111   |
      | document  | agency      | handoff    | Bob Johnson     | 5555555555554444 | 4444   |
      | document  | legal_staff | legal      | Alice Smith     | 4012888888881881 | 1881   |

  # Notification Timing, Duplicate Prevention & Dynamic Due Date API
  @api
  Scenario Outline: Payment Due Reminder Timing & Duplicate Suppression – Masking Compliance
    Given account "<account_id>" with due date "<due_date>" and reminder window "<window_min>" to "<window_max>" days before due
    When reminder workflow is triggered at "<days_before_due>" days before due date
    Then notification is sent only if within window and includes only last 4 digits "<last_4>"
    And duplicate/out-of-window reminders are blocked and logged for suppression or invalid attempt

    Examples:
      | account_id | due_date    | window_min | window_max | days_before_due | card_number      | last_4 | duplicate_attempt |
      | 12345      | 2024-07-15  | 5          | 7          | 7               | 4012888888881881 | 1881   | No               |
      | 12345      | 2024-07-15  | 5          | 7          | 5               | 4012888888881881 | 1881   | No               |
      | 12345      | 2024-07-15  | 5          | 7          | 4               | 4012888888881881 | 1881   | No               |
      | 12345      | 2024-07-15  | 5          | 7          | 6               | 4012888888881881 | 1881   | Yes              |

  @api
  Scenario Outline: Dynamic Due Date Adjustment and Notification Window Compliance
    Given account "<account_id>" with original due date "<original_due_date>" and reminder already sent
    When due date is changed to "<new_due_date>" (extend/shorten)
    Then system recalculates reminder window and sends only in-window notifications (masked last 4 digits "<last_4>")
    And obsolete or duplicate reminders are suppressed and recorded in audit log

    Examples:
      | account_id | original_due_date | new_due_date | card_number      | last_4 |
      | 12345      | 2024-07-15        | 2024-07-18   | 4012888888881881 | 1881   |
      | 67890      | 2024-07-22        | 2024-07-19   | 5555555555554444 | 4444   |

  # Notification Preferences API Tests
  @api
  Scenario Outline: Multi-Channel Opt-In/Opt-Out Management for Collection Communications
    Given cardholder "<cardholder_name>" accesses preferences and selects opt-in status "<opt_status>" for channel "<channel>"
    When collection communication events (reminder, overdue, agency, legal) are triggered
    Then cardholder receives notifications only via opted-in channels with only last 4 digits
    And suppressed channels are honored immediately and audit log records preference changes

    Examples:
      | cardholder_name | channel   | opt_status | card_number      | last_4 |
      | Alice Smith     | email     | enabled    | 4012888888881881 | 1881   |
      | Bob Johnson     | sms       | disabled   | 5555555555554444 | 4444   |
      | Carol Lee       | in-app    | enabled    | 4111111111111111 | 1111   |

  # Real-Time Retry and Failure Recovery API Tests
  @api
  Scenario Outline: Real-Time Notification Retry and Failure Recovery Mechanism Verification
    Given account "<account_id>" at workflow stage "<stage>" and contact "<contact>" with retry policy "<retry_limit>"
    When notification fails (network/channel/recipient)
    Then system retries up to policy limit and each attempt includes only last 4 digits "<last_4>"
    And persistent failure escalates to administrator with masked error log
    And audit log tracks all retries, masking, escalation, and recipient role

    Examples:
      | account_id | stage      | contact    | retry_limit | card_number      | last_4 |
      | 12345      | overdue    | bad.email  | 3           | 4012888888881881 | 1881   |
      | 67890      | reminder   | +123456789 | 3           | 5555555555554444 | 4444   |

  # Escalation/De-Escalation State Transition API Tests
  @api
  Scenario Outline: Escalation and De-Escalation State Transition with Masking Enforcement
    Given account "<account_id>" is in "<escalated_state>" and payment or plan is accepted
    When system detects resolution and initiates state transition back to "active"
    Then state change notifications to cardholder, agency, legal include only last 4 digits "<last_4>"
    And audit log records all escalation/de-escalation actions and masking compliance
    And any attempted escalation/de-escalation with full card number is blocked/logged

    Examples:
      | account_id | escalated_state | card_number      | last_4 |
      | 12345      | legal           | 4012888888881881 | 1881   |
      | 67890      | agency          | 5555555555554444 | 4444   |

  # UI & Portal Tests (Functional + Accessibility)
  @ui @portal
  Scenario Outline: Cardholder Accepts Custom Payment Plan via Self-Service Portal
    Given I am logged into the self-service portal as "<cardholder_name>"
    When I review and accept payment plan proposal with masked card "<last_4>" and adjust installment "<installment_amount>" "<installment_date>" within policy
    And I confirm and submit acceptance
    Then confirmation and payment schedule are generated and displayed (with only last 4 digits)
    And documents/messages are sent by selected channels, masked accordingly
    And audit log records all portal actions

    Examples:
      | cardholder_name | card_number      | last_4 | installment_amount | installment_date |
      | Alice Smith     | 4012888888881881 | 1881   | $150.00           | 2024-08-01       |
      | Bob Johnson     | 5555555555554444 | 4444   | $200.00           | 2024-08-10       |

  @ui
  Scenario: User Requests Detailed Breakdown of Collection Fees and Charges via Portal
    Given I am the cardholder receiving collection notification (masked last 4 digits only)
    When I request itemized breakdown of fees through portal/support
    Then breakdown is displayed/sent including only last 4 digits for card reference
    And unauthorized/unauthenticated users are denied access and audit log records request events

  @ui
  Scenario Outline: Accessibility and Usability Verification of Collection Notifications and Portal Flows
    Given notification templates and portal workflows are enabled
    When visually impaired users access messages/docs with "<assistive_technology>"
    And perform workflow actions using "<input_method>" (screen reader, keyboard)
    Then all content, masking, color contrast, structured markup, and navigation comply with WCAG 2.1 AA
    And masked card info reveals only last 4 digits
    And users can take independent action
    And no accessibility loophole exposes sensitive card info

    Examples:
      | assistive_technology  | input_method |
      | screen_reader         | keyboard     |
      | color-contrast tools  | keyboard     |
      | tab navigation        | keyboard     |

  # Non-Functional Bulk Processing, Performance
  @performance
  Scenario: Peak Load Performance Test for Bulk Collection Notification Dispatch
    Given 50,000+ accounts in collection pipeline with varying lifecycle states
    When bulk notification batch (reminder, overdue, collection, payment plan, agency handoff) is triggered
    Then 95% of notifications are delivered within 15 min
    And all communications/templates contain only masked last 4 digits of card
    And system resource utilization remains within thresholds
    And no lost, duplicated, or delayed notifications beyond tolerances

  # End-to-End Branching, Masking, Compliance
  @api
  Scenario: Formal Collection Notification and Payment Plan Proposal with Masked Card Number & Branch Coverage
    Given account "<account_id>" is delinquent and overdue alerts sent but not responded
    When system triggers collection notification and checks payment plan eligibility
    Then all communications include only last 4 digits
    And audit log records collection, proposal, and response events
    And workflow branches per cardholder acceptance, refusal, or no response
    And regulatory compliance is validated

  @api
  Scenario: User-Initiated Escalation Request and Immediate Agency/Legal Notification
    Given cardholder authenticates and initiates escalation (dispute, debt restructure, legal)
    When system prepares masked communication/document and transmits to agency/legal
    Then notifications/documents include only last 4 digits, audit log records actions, and responses are properly masked

