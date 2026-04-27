Feature: Comprehensive Credit Card Due and Collection Workflow Masking, Compliance, Notification, and State Management

  # Background: Common test setup for API and UI scenarios
  Background:
    Given the system base URL is configured
    And authorization, notification, and agency integrations are enabled
    And the test cardholder(s) and staff roles exist in the environment
    And audit log and masking policy enforcement are enabled

  # End-to-End Workflow
  @e2e @ui @api
  Scenario Outline: Credit card due collection lifecycle transitions and masking
    Given an existing credit card account ending <card_last4> with upcoming payment due
    And eligible workflow and notification integration are enabled
    When the system sends a due reminder notification for the account
    Then the notification shows only the last 4 digits '<card_last4>' and never full card number
    When due date passes with no payment, the system triggers overdue alert and calculates additional charges
    Then overdue notification is sent with masked card digits and fee calculation is validated
    When escalation threshold is reached, formal collection notification is sent with last 4 digits only
    Then overdue balance and late fees are correctly calculated and masked in the communication
    When continued non-payment is simulated, external collection agency workflow is triggered
    Then handoff communication is confirmed, card data is redacted and masked
    When a payment plan proposal is offered, customer accepts and makes initial payment as per plan
    Then workflow transitions, fee calculation, and masking are validated
    When default/dispute occurs after plan, legal escalation is triggered and documents are generated
    Then all documents and notifications show masked digits, role-based actions are respected
    When legal closure or recovery completes, system state is updated, notifications sent, and audit log reviewed
    Then audit trail contains only masked card PII and compliance requirements are met

    Examples:
      | card_last4 |
      | 1234       |

  # Boundary Value and Negative Path
  @api @ui
  Scenario Outline: Overdue balance escalation fee calculation and integration error handling
    Given account with overdue balance <balance> and escalation threshold logic enabled
    When the system triggers due/overdue notification and/or escalation
    Then notification/communication shows only masked card digits, calculation aligns with boundary value, and error handling is user-friendly and masked
    When staff user applies one-time fee waiver or override
    Then content and logs reflect override, masking, and correct recalculation
    When agency handoff is attempted and integration is <integration_state>
    Then outcome is logged, notifications are masked, and system recovers gracefully

    Examples:
      | balance | integration_state |
      | 0       | up               |
      | -10     | up               |
      | 500     | down             |
      | 10000   | down             |
      | Max     | up               |

  # Role-Based Access & Masking
  @rbac @ui @api
  Scenario Outline: Role-based notification trigger and masking enforcement
    Given user of role <role> with assigned overdue account ending <card_last4>
    When user attempts to view or trigger notification/action in the collection workflow
    Then permission, access control, and masking enforcement apply per role
    When unauthorized action is attempted (view/escalate/download)
    Then system blocks action, displays masked error, and logs event

    Examples:
      | role           | card_last4 |
      | Customer       | 9876      |
      | Bank Staff     | 9876      |
      | Collection Agent | 9876    |
      | Legal Handler  | 9876      |
      | System Admin   | 9876      |
      | Unauthorized User | 9876   |

  # Notification Content Delivery & Masking
  @notify @ui @api
  Scenario Outline: Notification generation, multi-channel delivery, and masking
    Given overdue or collection event occurs for card ending <card_last4> with communication channels enabled
    When the system sends notification via <channel>
    Then notification content, formatting, and masking are validated per channel and regulatory requirement
    When delivery fails or is misaddressed, error handling and masking are enforced
    When retry/fallback is performed, masking persists and error logs are compliant
    And downloadable documents are inspected for masking

    Examples:
      | card_last4 | channel    |
      | 2468       | SMS        |
      | 2468       | Email      |
      | 2468       | UI         |
      | 2468       | Download   |

  # Decision Table for Payment Plan & State Transition
  @state
  Scenario Outline: User actions and system state transitions for payment plan and collections
    Given overdue account ending <card_last4> at state <state>
    When user action <user_action> is performed
    Then system transitions state to <next_state>, recalculates fee, sends masked notification, and logs event

    Examples:
      | card_last4 | state      | user_action        | next_state   |
      | 5555       | Overdue    | Pay in full        | Current      |
      | 5555       | Overdue    | Pay partial        | Overdue      |
      | 5555       | Collection | Accept plan        | Payment Plan |
      | 5555       | Collection | Decline plan       | Agency       |
      | 5555       | Agency     | Pay after escalation | Recovered   |
      | 5555       | Legal      | Resolve dispute    | Closed       |

  # Notification Misdelivery & Correction Negative Path
  @negui @ui
  Scenario Outline: Notification misdelivery and masked correction workflow
    Given cardholder profile with incorrect contact information for card ending <card_last4>
    When due reminder notification is sent and delivered to wrong user/contact
    Then recipient reports the issue and system support workflow is triggered
    When contact is updated and notification is re-sent
    Then notification content and audit logs reflect masking, error, and compliance

    Examples:
      | card_last4 | incorrect_contact |
      | 4321       | wrong_email      |

  # Payment Plan Boundary & Eligibility
  @ppboundary @api @ui
  Scenario Outline: Payment plan proposal eligibility and masking at boundary values
    Given overdue account with balance <balance> for card ending <card_last4>
    When system attempts to generate payment plan proposal
    Then plan is <plan_status>, notification is sent or suppressed, and only last 4 digits shown
    When plan is accepted or rejected as user
    Then notification, logs, and audit trail reflect outcome, masking, and compliance

    Examples:
      | balance | plan_status      | card_last4 |
      | 0       | ineligible       | 6543       |
      | 49      | ineligible       | 6543       |
      | 500     | eligible         | 6543       |
      | 100000  | eligible         | 6543       |

  # Collection Agency Integration Failure
  @agencyfail @api
  Scenario Outline: Collection agency handoff integration failure and masking
    Given account in collection escalation state for card ending <card_last4>
    And collection agency system integration is <integration_state>
    When system triggers agency handoff
    Then failure is logged, masked notifications sent to all parties, and retry/escalation path proceeds
    When integration recovers, handoff is completed, logs and outputs remain masked

    Examples:
      | card_last4 | integration_state |
      | 1212       | down             |
      | 1212       | up after retry   |

  # Legal Escalation, Document Generation & Access
  @legal @api @ui
  Scenario Outline: Legal action document creation, notification, masking, and access control
    Given account in legal-eligible state for card ending <card_last4> and legal handler available
    When legal action is initiated and documents generated
    Then all notices, headers, footers, annex (UI/PDF/Download) show only masked digits
    When access attempt by <role> to legal documents occurs
    Then system enforces access control and masking per regulatory policy

    Examples:
      | card_last4 | role            |
      | 4444       | Legal Handler   |
      | 4444       | Customer        |
      | 4444       | Unauthorized User |
      | 4444       | Collection Agent|
      | 4444       | Bank Staff      |

  # Invalid User Input and Monetary Calculation Error Handling
  @dataval @ui
  Scenario Outline: Invalid payment input and secure error messaging workflow
    Given cardholder logs into portal for account ending <card_last4>
    When user enters payment amount <amount>
    Then UI blocks invalid input, shows error message with masking, and logs action
    When staff corrects overdue or fee miscalculation
    Then user receives updated notification, masking is preserved

    Examples:
      | card_last4 | amount      |
      | 2222       | -50         |
      | 2222       | 0           |
      | 2222       | max+1       |
      | 2222       | threshold   |

  # Notification Suppression on Early Payment
  @supp @ui
  Scenario Outline: Notification suppression upon early payment and masking
    Given due reminder is scheduled for card ending <card_last4>
    When cardholder makes early payment before reminder date
    Then system updates account state, suppresses all scheduled notifications, and sends masked receipt
    When attempt to trigger overdue reminder is made
    Then operation is suppressed, audit log and communication reflect masking

    Examples:
      | card_last4 |
      | 5678       |

  # Escalation Manual Override and Audit Compliance
  @manual @api @ui
  Scenario Outline: Manual override of collection escalation and masking
    Given overdue account at escalation threshold for card ending <card_last4>
    When bank staff applies manual hold/override with justification
    Then system cancels/delays collection notification, logs override with masked digits
    When customer receives revised notification
    Then only masked digits are shown
    When manual handoff is attempted, operation is blocked and error is masked/logged

    Examples:
      | card_last4 |
      | 9090       |

  # Dispute Handling and State Freeze
  @dispute @ui @api
  Scenario Outline: Disputed overdue amount and temporary suspension with masking
    Given overdue account ending <card_last4> and active collection/notification workflow
    When customer raises dispute on overdue fee
    Then system freezes escalation, halts notifications, all logs and comms show masked digits
    When dispute is resolved as <resolution>
    Then customer/staff receive appropriate masked notification and workflow resumes/adjusts per policy

    Examples:
      | card_last4 | resolution |
      | 5555       | approve   |
      | 5555       | adjust    |
      | 5555       | reject    |

  # Multiple Cards, Parallel Workflows, Cross-Masking
  @multi @ui @api
  Scenario Outline: Parallel due and collection workflows for multiple cards per user
    Given cardholder with accounts ending <card_last4a> and <card_last4b> in separate workflows
    When system triggers notifications for each card
    Then each comm displays correct masked digits, no mixing of card data
    When cross-notification error is simulated
    Then system blocks/corrects, all logs/comms remain masked and segregated

    Examples:
      | card_last4a | card_last4b |
      | 1010        | 2020        |

  # Post-Legal Closure Communication and Retention
  @postclose @ui @api
  Scenario Outline: Post-legal closure notification, retention and masking enforcement
    Given account ending <card_last4> completed legal closure
    When system generates final closure notification/documents for all parties
    Then all communications use only last 4 digits and system disables further action/workflow
    When audit/download/archive is performed
    Then artifacts are masked and retained as per regulatory timelines

    Examples:
      | card_last4 |
      | 9898       |

  # Portal UI Masking Validation on Screens and Downloadable Documents
  @uimask @ui
  Scenario Outline: End-to-end UI masking validation for overdue and escalation journey
    Given cardholder logs in and views dashboard for card ending <card_last4>
    When user navigates to documents section and downloads PDF/statement/notice
    Then content and file name show only masked digits, UI, popups, browser titles remain masked
    When account escalates to overdue, collection, and legal states
    Then each notification/download/UI display maintains masking compliance even in errors, logs, or deep-links

    Examples:
      | card_last4 |
      | 1111       |

  # Audit Log and Retention Enforcement
  @audit @api @ui
  Scenario Outline: Audit log and retention validation for all states, actions, and masked digits
    Given overdue event occurs for account ending <card_last4>
    When payment, escalation, agency handoff, and legal closure actions are performed
    Then audit log records actor, timestamp, action, and only masked digits, no full PII
    When record retention expires, attempt to download/export logs
    Then access is denied or redacted beyond retention, masking remains enforced

    Examples:
      | card_last4 |
      | 2222       |

  # Fee and Penalty Calculation Accuracy with Boundaries and Negative Values
  @fee @api @ui
  Scenario Outline: Penalty, fee, and interest assessment with boundary and negative values
    Given account due with balance <balance> for card ending <card_last4>
    When state changes to overdue/collection/legal and fee calculation is triggered
    Then calculation is mathematically correct, enforced within allowed boundaries; comms/audit show only masked digits
    When bank staff applies override
    Then recalculated amounts and all logs/notifications are masked and meet disclosure policy

    Examples:
      | balance | card_last4 |
      | 0       | 3333      |
      | -10     | 3333      |
      | threshold | 3333    |
      | max      | 3333     |

  # Integration Cross-Workflow Error Handling
  @interr @api
  Scenario Outline: Integration error handling, retry, and masked comm/logs
    Given account in overdue/collection state for card ending <card_last4>
    When notification server or agency integration experiences delay or failure
    Then system retries, provides masked notifications/logs, de-duplicates repeated attempts, and masks all outputs
    When integration restores, handoff/notification is completed and masking persists

    Examples:
      | card_last4 |
      | 6789      |

  # Payment Plan Acceptance, Partial Payment, Reversal Workflow
  @planrv @ui @api
  Scenario Outline: Payment plan, partial payment, reversal, recovery and masking
    Given account ending <card_last4> receives payment plan offer
    When customer makes partial payment then attempts reversal
    Then system recovers plan state, sends masked notification/comm to all roles
    When staff reviews audit log, masking and sequence are verified
    When customer overpays, system updates schedule and sends masked updates

    Examples:
      | card_last4 |
      | 3333       |

  # Collection Notification Scheduling and Suppression
  @sched @ui @api
  Scenario Outline: Sequential overdue notices, timing, masking, and suppression logic
    Given overdue account ending <card_last4> with notification schedule configured
    When system sends overdue notifications at scheduled intervals and user pays during sequence
    Then escalation is suppressed, all logs and notifications show correct masking, no invalid/late communication is sent

    Examples:
      | card_last4 |
      | 5678       |

  # Notification Content and Localization Validation
  @loc @ui @api
  Scenario Outline: Localization/regulatory formatting for multilingual notifications with masked digits
    Given account ending <card_last4> triggers overdue or collection event with locale <locale>
    When notification is generated and sent in <locale>
    Then content, regulatory text, and masking for card digits are validated per locale
    When unsupported locale is assigned, fallback and masking rules apply, logs and previews are validated

    Examples:
      | card_last4 | locale       |
      | 2468       | Spanish      |
      | 2468       | German       |
      | 2468       | French       |
      | 2468       | English      |

  # Access Control and Role Revocation
  @rbac2 @ui @api
  Scenario Outline: Dynamic role change handling, notification masking, and access control
    Given collection agent or staff with assigned overdue account ending <card_last4>
    When mid-workflow, admin revokes agent's access
    Then all action attempts, notifications, downloads are blocked or masked as per policy
    When access is restored, workflow resumes, masking persists at all outputs
    When illegal escalation is attempted after demotion, log and masked error are recorded

    Examples:
      | card_last4 |
      | 6789       |

  # Retroactive Fee Recalculation & Communication Update
  @retro @api @ui
  Scenario Outline: Retroactive fee change, notification content update, and full masking
    Given overdue account ending <card_last4> assessed with original late fee and regulatory change occurs
    When system recalculates fee and updates all historical and future comms/logs
    Then all notifications, logs, and UI show correct fee and only masked digits
    When system error occurs during recalculation, masking and compliance are validated

    Examples:
      | card_last4 |
      | 4444       |

  # Third-Party Notification Broker Integration and Masking Validation
  @extint @api
  Scenario Outline: Third-party broker (Twilio, SendGrid) notification consistency and masking
    Given account ending <card_last4> triggers notification routed via <broker>
    When payload, webhook, and delivery log are generated
    Then only last 4 digits are present in all message payloads, logs, and outputs
    When transmission fails, error logs and retries are masked and compliant

    Examples:
      | card_last4 | broker  |
      | 1212       | Twilio  |
      | 1212       | SendGrid|

  # Delayed Payment Handling Before Agency Handoff
  @time @ui @api
  Scenario Outline: Delayed payment after collection notification and suppression of agency escalation
    Given collection notification is sent for account ending <card_last4>, agency handoff scheduled
    When customer makes full payment before escalation
    Then system suppresses escalation, sends masked confirmation, and logs suppression
    When staff/agent tries manual escalation, action is blocked and masking is enforced

    Examples:
      | card_last4 |
      | 2468       |

  # Notification Template Management and Masked Preview Error Handling
  @template @ui
  Scenario Outline: Notification template editing and preview masking
    Given bank staff accesses notification template management UI for overdue/legal template
    When staff edits template and inserts/updates masking token
    Then preview shows only masked digit output (last 4), even during field error or missing data
    When template error occurs, preview/log always masked; fallback template is used
    When template is published or reverted, audit log masking is reviewed

    Examples:
      | card_last4 |
      | 8888       |

  # Cross-Product Payment and Collection Impact Notification
  @xprod @api @ui
  Scenario Outline: Linked loan repayment impacting overdue card state, masking, notification suppression
    Given cardholder has overdue credit card ending <card_last4> and linked loan in arrears
    When loan payment sufficiently credits card, system recalculates state and suppresses pending overdue/collection notifications
    Then all notifications/confirmation comms show only masked digits, logs and statements are reviewed
    When partial resolution leaves card overdue, subsequent notification reflects recalculated balance and masking

    Examples:
      | card_last4 |
      | 3579       |

  # Legal Case Appeal and Reopened Workflow
  @appeal @ui @api
  Scenario Outline: Legal case reopening after customer appeal with masked communication validation
    Given legal case for card ending <card_last4> is closed
    When customer appeals, legal handler approves reopening, system reinstates workflow and generates notices
    Then all notifications, audit logs, reopened and closed chains reviewed for masking compliance
    When customer responds (payment/dispute), system updates workflow and logs with masking

    Examples:
      | card_last4 |
      | 7410       |

  # Consent Withdrawal and Notification Suppression Validation
  @consent @ui @api
  Scenario Outline: User communication consent withdrawal with notification suppression and masking
    Given customer navigates to notification preferences for card ending <card_last4> and withdraws consent
    When system updates preferences and audit log
    Then all digital comms are suppressed, fallback notice generated if required (masked), logs are reviewed
    When consent is reinstated, future notifications enabled, masking checked on all outputs/history

    Examples:
      | card_last4 |
      | 9512       |

  # API Test Scenarios: CRUD Operations for Collection Entities (Example)
  @api
  Scenario Outline: Collection entity API operations with masking and compliance checks
    Given the API base URL is '/api/collections'
    And authorization token is set for <role>
    When I send a <method> request to '/api/collections/<entity_id>' with payload
      """
      {
        "card_number": "<masked_card>",
        "balance": <balance>,
        "fee_applied": <fee>
      }
      """
    Then the response status should be <status>
    And the response should contain masked card number '<masked_card>' and no full card data

    Examples:
      | role      | method | entity_id | masked_card | balance | fee | status |
      | Bank Staff| GET    | 1001      | 5678        | 500     | 15  | 200    |
      | System    | POST   | 1002      | 3333        | 1000    | 0   | 201    |
      | Customer  | PUT    | 1003      | 2468        | 200     | 5   | 200    |

# End of feature - all scenarios validated for masking, state, notification, audit, and regulatory compliance.
