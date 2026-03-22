Feature: Credit Card Due Collection, Masking, Escalation, Notification and Compliance Lifecycle

  # Background spans all endpoints, users, and compliance settings.
  Background:
    Given all integration endpoints (notification, collection agency, legal system) are active
    And masking and audit settings are set per PCI DSS and GLBA
    And valid test users exist for all roles (cardholder, agent, manager, collection agency, legal user)
    And system supports multi-card/joint account scenarios
    And notification preferences and payment plan features are enabled

  # End-to-end lifecycle; positive flow
  @e2e @ui @api
  Scenario: Full Credit Card Due Collection Lifecycle with Notifications, Escalation, Payment Plan, and Compliance Checks
    Given a cardholder with multiple active credit cards enrolled in digital notifications and 3 days before payment due date
    When the system sends automated due reminders referencing only last 4 digits via preferred channels
    And the cardholder misses payment and receives overdue balance alert with masked last 4 digits and consequences
    And the account transitions to delinquent, system sends escalation notification with masked account details
    And the cardholder logs in, reviews masked notifications, and acknowledges receipt
    And the agent accesses account details for the cardholder, views only masked card information
    And the cardholder is offered a payment plan proposal referencing only last 4 digits with schedule and reduced fees/rates
    And the cardholder rejects the payment plan and the account progresses to collection agency threshold
    And the system records handoff to collection agency via integration referencing only last 4 digits, masks all PII, and audit log entry is created
    And collection agency user logs in and accesses this account, views masked information
    And continued non-payment triggers legal action threshold; legal notification is generated, referencing only last 4 digits, and sent to cardholder
    And legal user reviews masked audit log for the case
    And the cardholder pays full balance after legal notice, all actions are reversed, account status reverts, workflows closed, and masked notifications issued
    Then all communications, logs, and notifications throughout the workflow reference only the last 4 digits
    And regulatory requirements GLBA and PCI DSS are upheld
    And audit trail for every action is complete

  # Negative, masking compliance coverage
  @security @ui @api
  Scenario Outline: Strict Masking - Validate Full Card Number Exposure Is Impossible in Notifications, UIs, APIs and Logs
    Given a cardholder with at least one active card, notification and API access is available
    When <trigger>
    Then the received notification, UI, log, or API response shows only last 4 digits, full PAN is never exposed anywhere
    And masking enforcement is checked in all outbound/inbound paths
    And failed masking or attempted exposure is logged as a security event

    Examples:
      | trigger                                                                                  |
      | triggering due reminder, overdue alert, collection escalation, payment proposal           |
      | inspecting notification (email/SMS/app) for masking                                      |
      | testing UI screens/logins as cardholder, agent, manager for masked card views             |
      | accessing audit logs, communication archives                                              |
      | outbound API dataloads for collection agency, legal system                               |
      | input and data retrieval attempts for full PAN via API, UI, integrations                  |
      | forced error paths (API failure, external rejection) for masking in errors                |
      | role access by agent, collection, legal                                                  |

  # Payment plan boundary and transition edge
  @boundary @paymentplan @ui @api
  Scenario Outline: Boundary Delinquency and Payment Plan Eligibility and Reversal
    Given a cardholder overdue at the boundary for payment plan eligibility with payment plan feature active
    When system attempts to offer payment plan for <balance> overdue and <delinquencyDays> days delinquent
    Then the eligibility is decided accordingly and proposal offer workflow triggers only at valid boundaries
    And all communications, notifications, and UI references show only last 4 digits
    And audit entries record masking, actions, and reversals

    Examples:
      | balance    | delinquencyDays | outcome               |
      | 499.99     | 29              | No proposal           |
      | 500.00     | 30              | Proposal offered      |
      | 500.01     | 30              | Proposal offered      |
      | 499.99     | 30              | No proposal           |
      | 1000.00    | 35              | Proposal accepted     |

  # Role-based access boundary and rejection scenarios
  @role @rba @security @ui
  Scenario Outline: Role-Based Access Validation for All User Types
    Given <role> user logs in to the system during test account status <status>
    When user attempts authorized and unauthorized actions
    Then masking (last 4 digits only) is enforced in all UI pages, logs, communications
    And only permitted actions succeed; unauthorized attempts are blocked and logged in audit trail with masked error message

    Examples:
      | role               | status       | authorized_action                          | unauthorized_action              |
      | cardholder         | overdue      | view/acknowledge notifications, schedule payment | access agency dashboard          |
      | agent              | collection   | initiate status change, send notification  | edit legal file                  |
      | manager            | on plan      | review communication logs, override status | download legal documents         |
      | collection agency  | collection   | access collection account, view masked card | change account core data         |
      | legal user         | legal        | access legal documents, review logs        | access payment plan schedule     |

  # Integration/External System failure handling scenarios
  @integration @failure @api
  Scenario Outline: Integration Failure Handling and Masked User Messaging
    Given integration endpoint <integration> can be simulated to fail for account in <accountStatus> state
    When the system triggers event <eventType>
    And <integration> is unavailable or returns error
    Then retry/fallback logic executes, error message is masked and logged
    And queued steps are replayed after recovery maintaining masking, order and completeness
    And audit log records all failures, recoveries, and masking validation

    Examples:
      | integration            | accountStatus    | eventType                           |
      | notification           | overdue          | due reminder delivery                |
      | notification           | overdue          | overdue alert partial delivery       |
      | collection agency      | collection       | agency handoff                      |
      | legal documentation    | legal            | legal notification/document creation |
      | payment integration    | payment          | payment scheduling during outage     |

  # Multi-account/joint scenarios, duplicate/out-of-order notification suppression
  @joint @ui @api
  Scenario Outline: Joint Account Multiple Cards - Notification Duplication and Card Reference Masking
    Given user has a joint account with <cardCount> cards, both approaching due date, preferences <channels>
    When system sends notifications for each card and <scenario>
    Then no duplicate/out-of-order notifications are sent; all references are unique to correct card (last 4 digits only)
    And audit records log delivery, suppression, ordering, and masking

    Examples:
      | cardCount | channels      | scenario                                         |
      | 2         | email,SMS     | both cards due within 24 hours                    |
      | 2         | email,SMS     | one card paid, one missed payment                 |
      | 2         | app,email     | simultaneous payment attempt from both users      |
      | 2         | email,SMS     | collection escalation for only delinquent card    |
      | 2         | app,email     | payment plan proposal for both cards, eligibility |

  # Time zone and cutoff boundary edge flow
  @boundary @timezone @ui @api
  Scenario Outline: Time Zone and Last-Minute Payments - Notification Escalation and State Reversal
    Given cardholder is located in <timeZone>, with card due at <dueTime> bank time
    When payment is made at/after cutoff and triggers <triggerType>
    Then account state, notification, and masking logic aligns to actual payment timing, state transitions and suppression
    And all communication logs, reversals, and audit entries reference only last 4 digits

    Examples:
      | timeZone       | dueTime     | triggerType                |
      | Pacific        | 12:00 AM ET | payment 5 mins before cutoff|
      | Eastern        | 12:00 AM ET | payment delayed post-cutoff|
      | Central        | 12:00 AM ET | agent override/correction   |
      | Mountain       | 12:00 AM ET | duplicate notification suppression |

  # Negative: Notification lost/missing escalation path
  @escalation @negative @ui @api
  Scenario Outline: Lost Notification Leads to Escalation and Recovery with Masking
    Given the cardholder's email/SMS is invalid, and account is overdue/collection/legal enabled
    When multiple notification delivery attempts fail and auto-escalation proceeds
    And cardholder reconnects, updates contact details, triggers retroactive notifications
    Then all communications and logs reference only last 4 digits, masking is enforced end-to-end
    And recovery window, payment plan, and state reversal are handled per business rules, audit log complete

    Examples:
      | deliveryStatus | recoveryWindow |
      | fail           | eligible       |
      | fail           | expired        |

  # Payment Plan proposal limits and acceptance/rejection
  @paymentplan @positive @negative @ui @api
  Scenario Outline: Payment Plan Proposal Fee Reduction Limit, User Rejection and Acceptance
    Given cardholder has overdue/delinquent account eligible for payment plan, reduction rules <limitType> active
    When system issues proposal with masked schedule through enabled channels
    And user <action> proposal
    And user proceeds to pay <paymentType>
    Then the masked communications reflect only last 4 digits at every step, audit is correct

    Examples:
      | limitType   | action  | paymentType    |
      | minimum     | reject  | none           |
      | minimum     | accept  | one installment|
      | maximum     | accept  | full payoff    |
      | minimum     | accept  | early payoff   |
      | maximum     | push    | none           |

  # Negative: Collection agency consent withdrawal, data deletion and access revocation
  @consent @agency @negative @ui @api
  Scenario Outline: User Consent Withdrawal After Collection Agency Handoff
    Given account has been handed off with masked last 4 digits, cardholder initiates dispute and consent withdrawal
    When system locks agency actions, notifies agency, blocks login, triggers deletion request and records compliance status
    Then all references, notifications, errors, and logs are masked (last 4 digits only)
    And audit confirms removal, communication cutoff, masking, and agency compliance

    Examples:
      | handoffStatus   | agencyAction         |
      | handed-over     | login blocked        |
      | handed-over     | deletion confirmed   |

  # Negative: Partial payment scheduling and state transition
  @payment @negative @ui @api
  Scenario Outline: Partial Payment Scheduling and State Logic
    Given cardholder is overdue and schedules <paymentType> payment after alert via portal, agent/manager can review
    When system accepts payment, maintains overdue logic, sends masked notifications
    And user makes additional payments <additionalType>
    Then account status, notifications and logs are correct, masking is enforced, audit trail is complete

    Examples:
      | paymentType | additionalType     |
      | partial     | partial again      |
      | partial     | full outstanding   |
      | less-minimum| rejected           |

  # Negative: API payload masking and tampering defense
  @api @masking @security @negative
  Scenario Outline: API Injection - Full Card Number Input Rejection and Masking
    Given API endpoints for notification, payment plan, agency handoff, legal integration support auditing and masking
    When I submit an API request to <endpoint> with a payload containing full card number
    Then the request is rejected, system responds with masked error (last 4 digits only), and logs the event with PCI/GLBA compliance

    Examples:
      | endpoint                   | operation                |
      | /api/notifications         | due reminder creation    |
      | /api/notifications         | overdue alert sent       |
      | /api/payment-plan          | proposal creation        |
      | /api/agency-handoff        | agency submission        |
      | /api/legal-notification    | legal notification       |
      | /api/notification-template | template update          |

  # Notification preference mutation; escalation masking
  @preference @negative @ui @api
  Scenario Outline: Notification Preference Update and Channel Enforcement
    Given cardholder has overdue account with default notification channel <defaultChannel>
    When user changes preferences to <newChannel>, system confirms, logs change, and delivers next notification/escalation
    Then all communications show only last 4 digits, masked in every channel, audit log records preference and suppression events

    Examples:
      | defaultChannel | newChannel |
      | SMS            | email     |
      | email          | app       |
      | SMS            | app       |

  # Payment plan proposal at final eligible day
  @boundary @paymentplan @timing @ui @api
  Scenario: Payment Plan Proposal and Acceptance at Last Eligible Day with Immediate Reversal
    Given cardholder is delinquent at final eligible day for payment plan
    When system triggers masked proposal, user immediately accepts and makes first installment payment
    And system logs payment, transitions state to 'on plan', sends masked notifications for future installments
    And agent reviews for compliance, timeline, and masking
    Then all notifications, communication logs, and audit entries reference only last 4 digits, masking enforced

  # Legal notification generation, access control, and audit masking
  @legal @audit @masking @ui @api
  Scenario: Legal Notification Generation, Document Masking, Access Control and Audit Validation
    Given delinquent account crosses legal action threshold, legal module active, legal user and cardholder with access
    When system generates masked legal notification and document for cardholder
    And legal user accesses documents via UI, agent attempts unauthorized access, access is rejected and logged
    And cardholder reviews communication log with masked details
    And legal user downloads documents, all instances display only last 4 digits
    And compliance officer reviews audit log for all document and notification events
    Then legal notifications and documents are masked in all channels; access control is enforced and logged; audit log is PCI DSS and GLBA compliant
