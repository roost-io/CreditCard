Feature: Collections lifecycle artifacts generation and PAN-compliance (API)
  Ensures lifecycle-driven communications are generated only when appropriate and every artifact shows exactly the last 4 digits with no full PAN exposure.

  @api
  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the request header 'Content-Type' is 'application/json'
    And the request header 'Authorization' is 'Bearer ${TOKEN}'
    And the PAN exposure regex pattern is '\b\d{13,19}\b'

  # API Tests — Positive generation and PAN compliance
  @api @positive
  Scenario Outline: Generate <artifactType> for state '<state>' and verify last-4 only and no full PAN
    Given account '<accountId>' exists with last4 '<last4>'
    When I PUT to '/api/accounts/<accountId>/lifecycle' with payload
      """
      {
        "state": "<state>",
        "flags": <flags>
      }
      """
    And I POST to '/api/accounts/<accountId>/actions/<action>' with payload
      """
      {
        "tenant": "test-tenant",
        "initiator": "qa_automation"
      }
      """
    Then a GET to '/api/artifacts?accountId=<accountId>&type=<artifactType>' should return exactly <expectedCount> items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body should contain exactly one occurrence of '<last4>' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      {
        "artifactId": "{artifactId}",
        "patterns": ["\\b\\d{13,19}\\b"]
      }
      """
    Then the response JSON field 'matches' should equal 0
    And the artifact body fields '<expectedFields>' should be present (if not '-')
    And I DELETE '/api/artifacts/{artifactId}' should return status 204

    Examples:
      | accountId     | last4 | state                           | action                          | artifactType                 | expectedFields                   | flags                                                | expectedCount |
      | ACC-DUE-01    | 4242  | upcoming payment due date       | generate-due-reminder           | Credit Card Due Reminder     | -                                | {}                                                   | 1            |
      | ACC-OVD-01    | 9001  | missed payment due date         | generate-overdue-alert          | Overdue Balance Alert        | -                                | {}                                                   | 1            |
      | ACCT-3001     | 4242  | significantly delinquent        | generate-collection-notification| Collection Notification      | amountOwed,additionalCharges     | {}                                                   | 1            |
      | P901          | 7719  | overdue                          | generate-payment-plan-proposal  | Payment Plan Proposal        | repaymentSchedule                | {"unableToPayFull": true}                            | 1            |
      | ACCT-AG-01    | 1234  | non-responsive after notifications | generate-agency-handoff      | Collection Agency Handoff    | -                                | {"nonResponsive": true, "priorNotifications": true}  | 1            |
      | ACC-LEGAL-1001| 1234  | extreme non-payment/default     | generate-legal-documents        | Legal Document               | -                                | {}                                                   | 1            |

  # API Tests — Negative gating (no artifact when trigger not met)
  @api @negative
  Scenario Outline: Do not generate <artifactType> when state '<state>' does not meet the trigger
    Given account '<accountId>' exists with last4 '<last4>'
    When I PUT to '/api/accounts/<accountId>/lifecycle' with payload
      """
      {
        "state": "<state>"
      }
      """
    And I POST to '/api/accounts/<accountId>/actions/<action>' with payload
      """
      {
        "tenant": "test-tenant",
        "initiator": "qa_automation"
      }
      """
    Then a GET to '/api/artifacts?accountId=<accountId>&type=<artifactType>' should return exactly 0 items
    And polling '/api/artifacts?accountId=<accountId>&type=<artifactType>' for 10 seconds every 2 seconds should still return 0 items

    Examples:
      | accountId     | last4 | state                       | action                          | artifactType               |
      | ACC-DUE-02    | 7777  | not upcoming due            | generate-due-reminder           | Credit Card Due Reminder   |
      | ACC-OVD-02    | 3333  | not missed due date         | generate-overdue-alert          | Overdue Balance Alert      |
      | B234          | 1881  | overdue                     | generate-collection-notification| Collection Notification    |
      | Q012          | 6640  | overdue (able to pay full)  | generate-payment-plan-proposal  | Payment Plan Proposal      |
      | AGENCY-02     | 1234  | responsive                  | generate-agency-handoff         | Collection Agency Handoff  |
      | ACC-LEGAL-2001| 5678  | overdue (not extreme)       | generate-legal-documents        | Legal Document             |

  # API Tests — Boundary validator for digit-count (N-1 and N+1)
  @api @boundary
  Scenario Outline: Validator flags non-compliance when <digitsLen> digits are displayed in <artifactType>
    Given I have a sample text '<sampleText>' for '<artifactType>'
    When I POST to '/api/validator/last4-only' with payload
      """
      {
        "artifactType": "<artifactType>",
        "artifactText": "<sampleText>"
      }
      """
    Then the response status should be 200
    And the response JSON field 'compliant' should equal false
    And the response JSON field 'reason' should contain "only the last 4 digits"

    Examples:
      | artifactType               | digitsLen | sampleText                          |
      | Credit Card Due Reminder   | 3         | "...ending *** 242"                 |
      | Credit Card Due Reminder   | 5         | "...ending ***** 42420"             |
      | Overdue Balance Alert      | 3         | "Acct ending *** 001"               |
      | Overdue Balance Alert      | 5         | "Acct ending ***** 90010"           |
      | Collection Notification    | 3         | "Identifier: *** 242"               |
      | Collection Notification    | 5         | "Identifier: ***** 84242"           |
      | Payment Plan Proposal      | 3         | "Plan for acct *** 234"             |
      | Collection Agency Handoff  | 3         | "ID: *** 234 to agency"             |
      | Legal Document             | 3         | "Case ref: acct *** 789"            |
      | Legal Document             | 5         | "Case ref: acct ***** 56789"        |

  # API Tests — State/communication gating (only the expected artifact is produced)
  @api @state-transition
  Scenario Outline: Only '<expectedOnlyType>' is generated when state is '<state>'
    Given account '<accountId>' exists with last4 '<last4>'
    When I PUT to '/api/accounts/<accountId>/lifecycle' with payload
      """
      {
        "state": "<state>",
        "history": {"dueReminderSent": <dueReminderSent>, "overdueAlertSent": <overdueAlertSent>}
      }
      """
    And I POST to '/api/accounts/<accountId>/actions/evaluate-lifecycle' with payload
      """
      { "runWindow": "now" }
      """
    Then a GET to '/api/artifacts?accountId=<accountId>&type=<expectedOnlyType>' should return exactly 1 items
    And for each type in '<absentTypes>' a GET to '/api/artifacts?accountId=<accountId>&type={type}' should return exactly 0 items

    Examples:
      | accountId   | last4 | state                             | expectedOnlyType            | absentTypes                                                                 | dueReminderSent | overdueAlertSent |
      | ACCT-2001   | 4242  | upcoming payment due date         | Credit Card Due Reminder    | Overdue Balance Alert,Collection Notification,Collection Agency Handoff,Legal Document | false          | false           |
      | ACCT-2002   | 4242  | overdue                           | Overdue Balance Alert       | Credit Card Due Reminder,Collection Notification,Collection Agency Handoff,Legal Document | true           | false           |
      | ACCT-2003   | 4242  | significantly delinquent          | Collection Notification     | Credit Card Due Reminder,Overdue Balance Alert,Collection Agency Handoff,Legal Document | true           | true            |
      | ACCT-2004   | 4242  | non-responsive after notifications| Collection Agency Handoff   | Credit Card Due Reminder,Overdue Balance Alert,Collection Notification,Legal Document | true           | true            |

  # API Tests — Required field validation (Collection Notification content)
  @api @negative @content
  Scenario Outline: Collection Notification is non-compliant when '<missingField>' is missing
    Given account '<accountId>' exists with last4 '<last4>'
    And I PUT to '/api/accounts/<accountId>/lifecycle' with payload
      """
      {
        "state": "significantly delinquent",
        "financials": {
          "amountOwed": <amountOwed>,
          "additionalCharges": <additionalCharges>
        }
      }
      """
    When I POST to '/api/accounts/<accountId>/actions/generate-collection-notification' with payload
      """
      { "initiator": "qa_automation" }
      """
    And I GET '/api/artifacts?accountId=<accountId>&type=Collection Notification'
    And I GET '/api/artifacts/{artifactId}' from the first item
    When I POST to '/api/validator/required-fields' with payload
      """
      {
        "requiredFields": ["amountOwed","additionalCharges"],
        "artifactId": "{artifactId}",
        "missingOverride": "<missingField>"
      }
      """
    Then the response JSON field 'compliant' should equal false
    And the response JSON field 'missing' should contain "<missingField>"

    Examples:
      | accountId | last4 | amountOwed | additionalCharges | missingField        |
      | C345      | 6579  | 980.00     | null              | amountOwed          |
      | D456      | 3007  | 450.00     | null              | additionalCharges   |

  # API Tests — Wrong 4-digit segment (first4 or middle4) is non-compliant
  @api @negative @segment
  Scenario Outline: Non-compliance when <segmentName> '<segmentValue>' is shown instead of last4 '<last4>' in <artifactType>
    Given I have a sample text '<sampleText>' for '<artifactType>'
    When I POST to '/api/validator/last4-only' with payload
      """
      {
        "artifactType": "<artifactType>",
        "artifactText": "<sampleText>",
        "expectedLast4": "<last4>"
      }
      """
    Then the response status should be 200
    And the response JSON field 'compliant' should equal false
    And the response JSON field 'reason' should contain "last 4 digits"

    Examples:
      | artifactType               | last4 | segmentName | segmentValue | sampleText                                              |
      | Collection Agency Handoff  | 1234  | first4      | 5678         | "Agency package for acct 5678 (should be last4 1234)"  |
      | Collection Notification    | 4242  | first4      | 4111         | "Notice for acct 4111 (should be last4 4242)"          |
      | Overdue Balance Alert      | 4242  | middle4     | 5678         | "Alert for acct 5678 (should be last4 4242)"           |

  # API Tests — Security scan across multiple artifacts (end-to-end)
  @api @e2e
  Scenario: End-to-end escalation path with last-4-only compliance across all artifacts
    Given account 'ACC-E2E-01' exists with last4 '6789'
    When I PUT to '/api/accounts/ACC-E2E-01/lifecycle' with payload
      """
      { "state": "upcoming payment due date" }
      """
    And I POST to '/api/accounts/ACC-E2E-01/actions/generate-due-reminder' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-01&type=Credit Card Due Reminder' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body should contain exactly one occurrence of '6789' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0
    When I PUT to '/api/accounts/ACC-E2E-01/lifecycle' with payload
      """
      { "state": "missed payment due date" }
      """
    And I POST to '/api/accounts/ACC-E2E-01/actions/generate-overdue-alert' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-01&type=Overdue Balance Alert' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body should contain exactly one occurrence of '6789' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0
    When I PUT to '/api/accounts/ACC-E2E-01/lifecycle' with payload
      """
      {
        "state": "significantly delinquent",
        "financials": {"amountOwed": 500.00, "additionalCharges": 25.00}
      }
      """
    And I POST to '/api/accounts/ACC-E2E-01/actions/generate-collection-notification' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-01&type=Collection Notification' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body should contain exactly one occurrence of '6789' as the identifier
    And the artifact body fields 'amountOwed,additionalCharges' should be present (if not '-')
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0
    When I PUT to '/api/accounts/ACC-E2E-01/lifecycle' with payload
      """
      {
        "state": "non-responsive after notifications",
        "history": {"dueReminderSent": true, "overdueAlertSent": true}
      }
      """
    And I POST to '/api/accounts/ACC-E2E-01/actions/generate-agency-handoff' with payload
      """
      { "initiator": "qa_automation", "recipient": "Collection Agency" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-01&type=Collection Agency Handoff' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body should contain exactly one occurrence of '6789' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0
    When I PUT to '/api/accounts/ACC-E2E-01/lifecycle' with payload
      """
      { "state": "extreme non-payment/default" }
      """
    And I POST to '/api/accounts/ACC-E2E-01/actions/generate-legal-documents' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-01&type=Legal Document' should return at least 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body should contain exactly one occurrence of '6789' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0

  # API Tests — E2E with Payment Plan Proposal after significant delinquency
  @api @e2e
  Scenario: End-to-end path offering a Payment Plan Proposal with last-4-only compliance
    Given account 'ACC-E2E-02' exists with last4 '9012'
    When I PUT to '/api/accounts/ACC-E2E-02/lifecycle' with payload
      """
      { "state": "upcoming payment due date" }
      """
    And I POST to '/api/accounts/ACC-E2E-02/actions/generate-due-reminder' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-02&type=Credit Card Due Reminder' should return exactly 1 items
    When I PUT to '/api/accounts/ACC-E2E-02/lifecycle' with payload
      """
      { "state": "missed payment due date" }
      """
    And I POST to '/api/accounts/ACC-E2E-02/actions/generate-overdue-alert' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-02&type=Overdue Balance Alert' should return exactly 1 items
    When I PUT to '/api/accounts/ACC-E2E-02/lifecycle' with payload
      """
      {
        "state": "significantly delinquent",
        "financials": {"amountOwed": 800.00, "additionalCharges": 40.00}
      }
      """
    And I POST to '/api/accounts/ACC-E2E-02/actions/generate-collection-notification' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-02&type=Collection Notification' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body fields 'amountOwed,additionalCharges' should be present (if not '-')
    And the artifact body should contain exactly one occurrence of '9012' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0
    When I PUT to '/api/accounts/ACC-E2E-02/lifecycle' with payload
      """
      { "state": "significantly delinquent", "flags": {"unableToPayFull": true} }
      """
    And I POST to '/api/accounts/ACC-E2E-02/actions/generate-payment-plan-proposal' with payload
      """
      { "initiator": "qa_automation" }
      """
    Then a GET to '/api/artifacts?accountId=ACC-E2E-02&type=Payment Plan Proposal' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    And the artifact body fields 'repaymentSchedule' should be present (if not '-')
    And the artifact body should contain exactly one occurrence of '9012' as the identifier
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0

  # API Tests — Focused functional checks for single artifacts (due/overdue)
  @api @functional
  Scenario Outline: Single artifact content checks for '<artifactType>' including boundary guards
    Given account '<accountId>' exists with last4 '<last4>'
    When I PUT to '/api/accounts/<accountId>/lifecycle' with payload
      """
      { "state": "<state>" }
      """
    And I POST to '/api/accounts/<accountId>/actions/<action>' with payload
      """
      { "initiator": "qa_automation" }
      """
    And a GET to '/api/artifacts?accountId=<accountId>&type=<artifactType>' should return exactly 1 items
    And I GET '/api/artifacts/{artifactId}' from the first item
    Then the artifact body should contain exactly one occurrence of '<last4>' as the identifier
    And the artifact body should not contain any 3-digit identifier fragment of '<last4>'
    And the artifact body should not contain any 5+ digit sequence adjacent to '<last4>'
    And I POST to '/api/security/scan' with payload
      """
      { "artifactId": "{artifactId}", "patterns": ["\\b\\d{13,19}\\b"] }
      """
    Then the response JSON field 'matches' should equal 0

    Examples:
      | accountId    | last4 | state                           | action               | artifactType             |
      | ACC-OVD-06   | 4242  | missed payment due date         | generate-overdue-alert | Overdue Balance Alert  |
      | ACC-DUE-06   | 9876  | upcoming payment due date       | generate-due-reminder  | Credit Card Due Reminder |
