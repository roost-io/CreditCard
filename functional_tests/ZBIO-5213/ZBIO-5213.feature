Feature: Credit Card Collection Lifecycle — Notification, Masking, Escalation, and Compliance Validation

  # Background setup for API tests
  Background:
    Given the API base URL is set to the collection service environment
    And the authorization token is configured
    And content type is "application/json"

  # UI background setup for regulatory/audit scenarios
  @ui
  Background:
    Given I am logged into the collection portal as a regulator, auditor, or agent
    And all communication, notification, and audit modules are enabled

  # API Tests: End-to-End, Masking, State Transitions
  @api @endtoend
  Scenario Outline: Due Collection Notification Generation and Masking Validation Across Channels
    Given a cardholder account is <accountState> with dues approaching <dueDate>
    And notification channels <channels> are configured
    When the system sends a "<notificationType>" notification for card ending "<cardDigits>"
    Then the notification is delivered via <channels>
    And notification content contains only the last 4 digits "<cardDigits>"
    And the notification includes <contentFields>
    And compliance/audit logs are updated for end-to-end traceability
    And no full card number or PII is exposed

    Examples:
      | accountState     | dueDate     | notificationType | channels                  | cardDigits | contentFields                        |
      | active           | tomorrow    | Reminder        | Email, SMS, App           | 4321       | due amount, due date, masking         |
      | overdue          | yesterday   | Overdue         | Email, SMS, Portal        | 9876       | overdue balance, escalation warning   |
      | restructured     | today       | Payment Plan    | Email, Portal             | 1234       | payment terms, timeline, masking      |

  @api @masking
  Scenario Outline: Data Masking Enforcement Across Collection Communications and Documents
    Given system notification logic is enabled for "<notifType>"
    When a communication is generated from account with test card "<cardDigits>"
    Then only last 4 digits "<cardDigits>" are present in outbound communication
    And no more than 4 digits appear in UI, PDF, legal feed, or logs
    And masking validation passes for all channels

    Examples:
      | notifType     | cardDigits |
      | reminder      | 2345       |
      | overdue       | 8765       |
      | payment plan  | 2442       |
      | agency        | 8822       |
      | legal         | 4454       |

  @api @boundary
  Scenario Outline: Boundary Escalation, Alert Timing, and Channel Override Handling
    Given account with overdue amount at regulatory threshold <threshold>
    And due date is <date>
    And channel configuration is <channels>
    When alert is triggered for "<alertType>"
    Then alert notification is sent only via <channels>
    And alert includes only last 4 digits "<cardDigits>"
    And escalation warning appears <escalation>
    And suppression or override works as per selected channel

    Examples:
      | threshold | date          | alertType   | channels                 | cardDigits | escalation     |
      | min       | today         | Reminder    | SMS                      | 3222       | not shown      |
      | median    | yesterday     | Overdue     | App, Email               | 5555       | warning shown  |
      | max       | tomorrow      | Collection  | Portal                   | 7878       | warning shown  |

  @api @agency
  Scenario Outline: Collection Agency Handoff — Data Masking, Feed, and Error Handling
    Given account state is "<status>" and eligible for agency handoff
    When system triggers agency feed transmission for card "<cardDigits>" with amount <amount> and legal state <legalStatus>
    And a transmission <transmissionStatus> occurs (<errorCode>)
    Then agency feed contains only last 4 digits "<cardDigits>"
    And feed has no unauthorized PII
    And failure/retry/fallback is logged in audit
    And outgoing payloads with unmasked data are blocked

    Examples:
      | status     | cardDigits | amount  | legalStatus | transmissionStatus | errorCode |
      | delinquent | 9531       | 5000.00 | default     | success           | NONE      |
      | default    | 9987       | 3200.00 | legal       | failure           | 502       |
      | pending    | 4411       | 750.00  | collection  | retry             | 408       |

  @api @legal
  Scenario Outline: Legal Action — Escalation Trigger, Document Generation, and Masking
    Given account is in default after agency recovery fails
    And legal escalation triggers are enabled
    When legal notification and document is generated for card "<cardDigits>"
    And legal template contains field placeholders
    Then all legal communications show only last 4 digits "<cardDigits>"
    And audit log includes all prior escalations
    And template edits cannot expose unmasked data
    And legal action is traceable through UI and audit logs

    Examples:
      | cardDigits |
      | 1344       |
      | 7777       |
      | 8889       |

  @api @optout
  Scenario Outline: Notification Suppression on Opt-Out or Account Closure
    Given cardholder account is "<state>" and notifications are "<notifStatus>"
    And opt-out/closure rules are enabled
    When a <triggerEvent> is initiated
    Then no notification is sent to any channel
    And suppression is logged with only last 4 digits "<cardDigits>" if present
    And audit trail contains suppression and reversal reason

    Examples:
      | state      | notifStatus | triggerEvent        | cardDigits |
      | opt-out    | enabled     | Overdue Attempt     | 2323       |
      | closed     | enabled     | Agency Escalation   | 7921       |

  @api @paymentplan
  Scenario Outline: Payment Plan Proposal Eligibility and Rollback Handling
    Given payment plan eligibility is configured and account is <accountState> with overdue amount <amount>
    When a payment plan proposal is <proposalAction>
    Then plan proposal notification contains only last 4 digits "<cardDigits>" if eligible
    And UI shows eligibility or denial reason as <uiMessage>
    And audit log records state <stateResult>

    Examples:
      | accountState | amount  | proposalAction | cardDigits | uiMessage        | stateResult       |
      | eligible     | 2000.00 | offered        | 9042       | Eligible         | offer proposed    |
      | ineligible   | 250.00  | attempted      | 6734       | Not Eligible     | no offer/logged   |
      | eligible     | 5000.00 | revoked        | 8811       | Revoked          | revoked/logged    |

  @api @legalblock
  Scenario Outline: Legal Escalation Block — State Enforcement and Masking
    Given account in <accountEscalationState> without prior agency step
    When legal escalation is manually triggered
    Then system blocks legal notification, shows escalation requirement
    And no unauthorized communication or doc is generated
    And masking is enforced (last 4 digits only)
    And audit log records attempted premature sequence

    Examples:
      | accountEscalationState |
      | overdue               |
      | collection            |

  # UI Tests: Portal, Audit, Regulatory Screens
  @ui @audit
  Scenario Outline: Regulatory/Audit UI — End-to-End Masking and Inspection
    Given I am on the communication logs UI as <userRole>
    When I view logs for cardholder with last 4 digits "<cardDigits>"
    And I navigate stages "<stages>" from reminder to legal
    Then every log entry shows only last 4 digits "<cardDigits>"
    And delivery time, content, recipient, and masking are verified
    And document export includes only masked data

    Examples:
      | userRole   | cardDigits | stages                       |
      | regulator  | 7832       | reminder, overdue, legal     |
      | auditor    | 1543       | all stages                   |
      | admin      | 1299       | collection, agency, legal    |

  @ui @recipient
  Scenario Outline: Multi-Recipient Escalation — Joint/Cardholder Notification Coverage
    Given a joint account with primary and secondary cardholders <recipients>
    And notification channel configuration is <channels>
    When a <notificationType> is triggered for account ending "<cardDigits>"
    Then notifications are delivered to <recipients> correctly
    And masking is enforced in every message
    And role reassignment and recipient override are reflected in logs

    Examples:
      | recipients               | channels     | notificationType | cardDigits |
      | primary, secondary       | Email, SMS   | Reminder        | 4056       |
      | primary                  | Portal       | Payment Plan    | 3729       |
      | secondary                | Email        | Legal Notice    | 5647       |

  @ui @config
  Scenario Outline: Alert Channel Configuration, Override, and Traceability
    Given I configure alert channel as <primary> and secondary as <secondary> for card "<cardDigits>"
    And admin override delivers future notifications via <overrideChannel>
    When a <notificationType> is triggered and channels changed to <currentChannel>
    Then notification is delivered via <currentChannel> only
    And channel changes and reversals are audit-logged
    And all delivered messages show only last 4 digits "<cardDigits>"

    Examples:
      | primary | secondary | overrideChannel | notificationType | currentChannel | cardDigits |
      | email   | sms       | sms             | Overdue         | sms            | 9054       |
      | email   | sms       | app             | Collection      | app            | 1777       |
      | app     | sms       | email           | Payment Plan    | email          | 6722       |

  @ui @failednotif
  Scenario Outline: Missed/Failed Notification UI and Audit Recovery
    Given account with notification channel <channel> is misconfigured or disabled
    When system attempts to send <notificationType> for card "<cardDigits>"
    And delivery fails due to <errorReason>
    Then delivery failure is logged in UI with only last 4 digits "<cardDigits>"
    And alternate channel <alternateChannel> is activated and notification retried
    And audit log export contains all failed attempts and masking compliance

    Examples:
      | channel | notificationType | cardDigits | errorReason     | alternateChannel |
      | email   | Reminder         | 4433       | undeliverable   | postal mail      |
      | sms     | Payment Plan     | 7766       | network error   | app              |

  @ui @contentvalidation
  Scenario Outline: Overdue and Collection Notification Content — Lawful Disclosure and UI Behavior
    Given notification templates for overdue/collection are configured for <region>
    When user misses payment by <daysLate> and notice is triggered for card "<cardDigits>"
    And template legally mandates required disclosures
    Then notification content includes last 4 digits "<cardDigits>", overdue amount, fee breakdown, and lawful warning
    And no unlawful fields (SSN, full card#) are shown
    And UI disables manual override for unauthorized sections

    Examples:
      | region     | daysLate | cardDigits |
      | stateA     | 1        | 8224      |
      | stateB     | 5        | 0999      |
      | federal    | 30       | 4477      |

  @ui @manualoverride
  Scenario Outline: Backoffice Manual Escalation and Notification Customization — UI and Audit Trail
    Given agent accesses escalation UI for overdue account "<cardDigits>"
    When manual override and customization is initiated
    And agent attempts to edit restricted and permitted fields in notification
    Then UI prohibits edits to restricted fields and auto-inserts masking (last 4 digits only)
    And customization is allowed only for compliant fields
    And override is logged with agent, timestamp, and change reason

    Examples:
      | cardDigits |
      | 5531      |
      | 7732      |

  @ui @paymentplan_rollback
  Scenario Outline: Payment Plan Proposal Eligibility, Rollback, and UI Handling
    Given account is <state> for payment plan with overdue amount <amount> and plan count <planCount>
    When payment plan proposal is <action> for card "<cardDigits>"
    And user abandons, revokes, or is ineligible
    Then UI shows correct eligibility or revocation reason
    And all communications and logs include only last 4 digits "<cardDigits>"

    Examples:
      | state      | amount  | planCount | action   | cardDigits |
      | eligible   | 3200.00 | 0         | offered  | 7394       |
      | ineligible | 100.00  | 3         | denied   | 1111       |
      | eligible   | 1200.00 | 1         | revoked  | 6666       |

  # Edge case tests and regulatory/localization checks included above via Examples tables

