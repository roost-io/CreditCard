Feature: Collections lifecycle notifications, state gating, and PAN masking via API

  # API Test Setup
  Background:
    Given the API base URL is set from environment 'BASE_URL'
    And I have a valid OAuth2 token for role 'collections-ops'
    And I set the 'Authorization' header to 'Bearer <token>'
    And I set the 'Content-Type' header to 'application/json'

  # Utility: trigger lifecycle evaluation and wait for completion
  # Steps referenced across scenarios:
  # - POST /api/lifecycle/evaluations -> returns {"jobId": "..."}
  # - GET  /api/jobs/{jobId} until status == COMPLETED

  # API Tests — Due Reminder

  @api @dueReminder @masking
  Scenario Outline: Generate Due Reminder for upcoming due date with last-4-only masking
    Given the account '<accountId>' exists with last4 '<last4>'
    And I set the due-date state for account '<accountId>' to 'upcoming' via PUT '/api/accounts/<accountId>/state' with payload:
      """
      { "billing": { "dueState": "upcoming" } }
      """
    And I send a GET request to '/api/artifacts?accountId=<accountId>&type=Credit%20Card%20Due%20Reminder'
    And the response status should be 200
    And the response JSON at '$.total' should be 0
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["<accountId>"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/artifacts?accountId=<accountId>&type=Credit%20Card%20Due%20Reminder'
    Then the response status should be 200
    And the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}'
    Then the response status should be 200
    And the response JSON at '$.metadata.type' should be 'Credit Card Due Reminder'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain '<last4>'
    And the response body should not contain any 13–19 digit numeric sequences
    And the response body should not contain any contiguous numeric sequences longer than 4 digits
    When I send a PUT request to '/api/artifacts/{{artifactId}}/status' with payload:
      """
      { "status": "archived" }
      """
    Then the response status should be 200

    Examples:
      | accountId | last4 |
      | acct-DR01 | 1234  |
      | acct-DR03 | 5521  |

  @api @dueReminder @negative
  Scenario Outline: Suppress Due Reminder when due date is not upcoming
    Given the account '<accountId>' exists with last4 '<last4>'
    And I set the due-date state for account '<accountId>' to 'not-upcoming' via PUT '/api/accounts/<accountId>/state' with payload:
      """
      { "billing": { "dueState": "not-upcoming" } }
      """
    And I send a GET request to '/api/artifacts?accountId=<accountId>&type=Credit%20Card%20Due%20Reminder'
    And the response status should be 200
    And the response JSON at '$.total' should be 0
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["<accountId>"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/lifecycle/runs/{{jobId}}/summary?accountId=<accountId>'
    Then the response status should be 200
    And the response body should not contain 'Due Reminder'
    When I send a GET request to '/api/artifacts?accountId=<accountId>&type=Credit%20Card%20Due%20Reminder'
    Then the response status should be 200
    And the response JSON at '$.total' should be 0

    Examples:
      | accountId | last4 |
      | acct-DR02 | 9876  |

  # API Tests — Overdue Balance Alert

  @api @overdue @masking
  Scenario Outline: Generate Overdue Balance Alert after due date is missed with last-4-only masking
    Given the account '<accountId>' exists with last4 '<last4>'
    And I set the due-date state for account '<accountId>' to 'missed' via PUT '/api/accounts/<accountId>/state' with payload:
      """
      { "billing": { "dueState": "missed" } }
      """
    And I send a GET request to '/api/artifacts?accountId=<accountId>&type=Overdue%20Balance%20Alert'
    And the response JSON at '$.total' should be 0
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["<accountId>"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/artifacts?accountId=<accountId>&type=Overdue%20Balance%20Alert'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain 'overdue'
    And the response body should contain '<last4>'
    And the response body should not contain any 13–19 digit numeric sequences
    And the response body should not contain any contiguous numeric sequences longer than 4 digits
    When I send a PUT request to '/api/artifacts/{{artifactId}}/status' with payload:
      """
      { "status": "archived" }
      """
    Then the response status should be 200

    Examples:
      | accountId | last4 |
      | acct-OA01 | 3141  |
      | acct-OA03 | 6600  |

  @api @overdue @negative
  Scenario Outline: Suppress Overdue Balance Alert before the due date is missed
    Given the account '<accountId>' exists with last4 '<last4>'
    And I set the due-date state for account '<accountId>' to 'not-missed' via PUT '/api/accounts/<accountId>/state' with payload:
      """
      { "billing": { "dueState": "not-missed" } }
      """
    And I send a GET request to '/api/artifacts?accountId=<accountId>&type=Overdue%20Balance%20Alert'
    And the response JSON at '$.total' should be 0
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["<accountId>"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/lifecycle/runs/{{jobId}}/summary?accountId=<accountId>'
    Then the response status should be 200
    And the response body should not contain 'Overdue Balance Alert'
    When I send a GET request to '/api/artifacts?accountId=<accountId>&type=Overdue%20Balance%20Alert'
    Then the response JSON at '$.total' should be 0

    Examples:
      | accountId | last4 |
      | acct-OA02 | 2718  |

  # API Tests — Collection Notification

  @api @collection @masking
  Scenario Outline: Generate Collection Notification for significantly delinquent accounts with last-4-only masking
    Given the account '<accountId>' exists with last4 '<last4>'
    And I set the delinquency state for account '<accountId>' to 'significantly-delinquent' via PUT '/api/accounts/<accountId>/state' with payload:
      """
      { "collections": { "delinquencyState": "significantly-delinquent" } }
      """
    And I send a GET request to '/api/artifacts?accountId=<accountId>&type=Collection%20Notification'
    And the response JSON at '$.total' should be 0
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["<accountId>"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/artifacts?accountId=<accountId>&type=Collection%20Notification'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain '<last4>'
    And the response body should contain 'collection'
    And the response body should not contain any 13–19 digit numeric sequences
    And the response body should not contain any contiguous numeric sequences longer than 4 digits
    When I send a PUT request to '/api/artifacts/{{artifactId}}/status' with payload:
      """
      { "status": "archived" }
      """
    Then the response status should be 200

    Examples:
      | accountId | last4 |
      | acct-CN01 | 8452  |

  @api @collection @details
  Scenario: Collection Notification includes amount owed and additional charges
    Given the account 'acct-CN02' exists with last4 '0047'
    And I set the delinquency state for account 'acct-CN02' to 'significantly-delinquent' via PUT '/api/accounts/acct-CN02/state' with payload:
      """
      { "collections": { "delinquencyState": "significantly-delinquent" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["acct-CN02"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/artifacts?accountId=acct-CN02&type=Collection%20Notification'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain 'amount owed'
    And the response body should contain 'additional charges'
    And the response body should contain '0047'
    And the response body should not contain any 13–19 digit numeric sequences

  @api @collection @negative
  Scenario: Suppress Collection Notification when account is not significantly delinquent
    Given the account 'acct-CN03' exists with last4 '2219'
    And I set the delinquency state for account 'acct-CN03' to 'not-significantly-delinquent' via PUT '/api/accounts/acct-CN03/state' with payload:
      """
      { "collections": { "delinquencyState": "not-significantly-delinquent" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["acct-CN03"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/artifacts?accountId=acct-CN03&type=Collection%20Notification'
    Then the response JSON at '$.total' should be 0

  # API Tests — Payment Plan Proposal

  @api @proposal @masking
  Scenario Outline: Generate Payment Plan Proposal when unable to pay full overdue balance with required content
    Given the account '<accountId>' exists with last4 '<last4>'
    And I set the account financial state for '<accountId>' via PUT '/api/accounts/<accountId>/state' with payload:
      """
      { "billing": { "overdue": true, "dueState": "missed" }, "collections": { "unableToPayFull": true } }
      """
    And I send a GET request to '/api/artifacts?accountId=<accountId>&type=Payment%20Plan%20Proposal'
    And the response JSON at '$.total' should be 0
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["<accountId>"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/artifacts?accountId=<accountId>&type=Payment%20Plan%20Proposal'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain 'structured repayment schedule'
    And the response body should contain 'reduced interest rates or fees'
    And the response body should contain '<last4>'
    And the response body should not contain any 13–19 digit numeric sequences

    Examples:
      | accountId | last4 |
      | acct-PP01 | 7635  |
      | ACC-PP03  | 3399  |

  @api @proposal @negative
  Scenario: Do not offer Payment Plan Proposal after full overdue payment
    Given the account 'ACC-PP02' exists with last4 '7788'
    And I set the account financial state for 'ACC-PP02' via PUT '/api/accounts/ACC-PP02/state' with payload:
      """
      { "billing": { "overdue": true, "dueState": "missed" } }
      """
    And I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-PP02"], "scope": "currentCycle" }
      """
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    And I send a POST request to '/api/payments' with payload:
      """
      { "accountId": "ACC-PP02", "type": "overduePayment", "amount": "FULL", "currency": "USD" }
      """
    And the response status should be 201
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-PP02"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    When I send a GET request to '/api/artifacts?accountId=ACC-PP02&type=Payment%20Plan%20Proposal&createdAfter={{now-5m}}'
    Then the response status should be 200
    And the response JSON at '$.total' should be 0
    When I send a GET request to '/api/artifacts?accountId=ACC-PP02&type=Overdue%20Balance%20Alert'
    Then the response status should be 200
    And the response body should contain '7788'
    And the response body should not contain any 13–19 digit numeric sequences

  # API Tests — Collection Agency Involvement

  @api @agency @masking
  Scenario: Initiate Collection Agency involvement only after no response; payload contains last4 only
    Given the account 'ACC-CA01' exists with last4 '4455'
    And I set prior notifications and no-response flags for 'ACC-CA01' via PUT '/api/accounts/ACC-CA01/state' with payload:
      """
      { "notifications": { "dueReminderSent": true, "overdueAlertSent": true, "collectionNoticeSent": true, "responded": false } }
      """
    When I send a POST request to '/api/lifecycle/escalations/agency' with payload:
      """
      { "accounts": ["ACC-CA01"] }
      """
    Then the response status should be 202
    And I store 'jobId' from the response JSON path '$.jobId'
    When I poll GET '/api/jobs/{{jobId}}' every 2 seconds for up to 120 seconds
    Then the response JSON at '$.status' should be 'COMPLETED'
    When I send a GET request to '/api/agency/handoffs?accountId=ACC-CA01'
    Then the response status should be 200
    And the response JSON at '$.total' should be 1
    And I store 'handoffId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/agency/handoffs/{{handoffId}}/payload'
    Then the response status should be 200
    And the response body should contain '4455'
    And the response body should not contain any 13–19 digit numeric sequences
    And the response body should not contain any contiguous numeric sequences longer than 4 digits

  @api @agency @negative
  Scenario: Suppress Collection Agency involvement when a prior response exists
    Given the account 'ACC-CA02' exists with last4 '6622'
    And I set prior notifications and response flag for 'ACC-CA02' via PUT '/api/accounts/ACC-CA02/state' with payload:
      """
      { "notifications": { "dueReminderSent": true, "overdueAlertSent": true, "collectionNoticeSent": true, "responded": true } }
      """
    When I send a POST request to '/api/lifecycle/escalations/agency' with payload:
      """
      { "accounts": ["ACC-CA02"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    When I send a GET request to '/api/agency/handoffs?accountId=ACC-CA02&createdAfter={{now-10m}}'
    Then the response status should be 200
    And the response JSON at '$.total' should be 0

  @api @agency @masking
  Scenario: Agency handoff payload includes only last4 and not full PAN
    Given the account 'ACC-CA03' exists with last4 '9182'
    And I set prior notifications and no-response flags for 'ACC-CA03' via PUT '/api/accounts/ACC-CA03/state' with payload:
      """
      { "notifications": { "dueReminderSent": true, "overdueAlertSent": true, "collectionNoticeSent": true, "responded": false } }
      """
    When I send a POST request to '/api/lifecycle/escalations/agency' with payload:
      """
      { "accounts": ["ACC-CA03"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    When I send a GET request to '/api/agency/handoffs?accountId=ACC-CA03'
    Then the response status should be 200
    And the response JSON at '$.total' should be 1
    And I store 'handoffId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/agency/handoffs/{{handoffId}}/payload'
    Then the response status should be 200
    And the response body should contain '9182'
    And the response body should not contain any 13–19 digit numeric sequences

  # API Tests — Legal Action Initiation

  @api @legal @masking
  Scenario: Generate Legal Documentation for extreme non-payment with last-4-only masking
    Given the account 'ACC-LA01' exists with last4 '1207'
    And I set legal escalation flag for 'ACC-LA01' via PUT '/api/accounts/ACC-LA01/state' with payload:
      """
      { "collections": { "extremeDefault": true } }
      """
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-LA01"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    When I send a GET request to '/api/legal/documents?accountId=ACC-LA01'
    Then the response status should be 200
    And the response JSON at '$.total' should be 1
    And I store 'docId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/legal/documents/{{docId}}/content'
    Then the response status should be 200
    And the response body should contain '1207'
    And the response body should not contain any 13–19 digit numeric sequences
    And the response body should not contain any contiguous numeric sequences longer than 4 digits

  @api @legal @negative
  Scenario: Suppress Legal Action Initiation when case is not extreme
    Given the account 'ACC-LA02' exists with last4 '5571'
    And I set legal escalation flag for 'ACC-LA02' via PUT '/api/accounts/ACC-LA02/state' with payload:
      """
      { "collections": { "extremeDefault": false } }
      """
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-LA02"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    When I send a GET request to '/api/legal/documents?accountId=ACC-LA02&createdAfter={{now-10m}}'
    Then the response status should be 200
    And the response JSON at '$.total' should be 0

  @api @legal @security
  Scenario: Legal documentation never displays full PAN in plain text
    Given the account 'ACC-LA03' exists with last4 '2640'
    And I set legal escalation flag for 'ACC-LA03' via PUT '/api/accounts/ACC-LA03/state' with payload:
      """
      { "collections": { "extremeDefault": true } }
      """
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-LA03"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    When I send a GET request to '/api/legal/documents?accountId=ACC-LA03'
    Then the response JSON at '$.total' should be 1
    And I store 'docId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/legal/documents/{{docId}}/content'
    Then the response status should be 200
    And the response body should contain '2640'
    And the response body should not contain any 13–19 digit numeric sequences

  # API Tests — Global Masking and Boundary

  @api @masking @e2e
  Scenario: End-to-end masking across all lifecycle artifacts (Due → Overdue → Collection → Proposal → Agency → Legal)
    Given the account 'ACC-2002' exists with last4 '9876'
    And I set the due-date state for account 'ACC-2002' to 'upcoming' via PUT '/api/accounts/ACC-2002/state' with payload:
      """
      { "billing": { "dueState": "upcoming" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-2002"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}' every 2 seconds for up to 120 seconds
    And I collect artifact types for 'ACC-2002' in sequence:
      | type                         |
      | Credit Card Due Reminder     |
    And each collected artifact content should contain '9876' and not contain any 13–19 digit numeric sequences
    Given I set the due-date state for account 'ACC-2002' to 'missed' via PUT '/api/accounts/ACC-2002/state' with payload:
      """
      { "billing": { "dueState": "missed" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-2002"], "scope": "currentCycle" }
      """
    Then I collect artifact types for 'ACC-2002' in sequence:
      | type                  |
      | Overdue Balance Alert |
    And each collected artifact content should contain '9876' and not contain any 13–19 digit numeric sequences
    Given I set the delinquency state for account 'ACC-2002' to 'significantly-delinquent' via PUT '/api/accounts/ACC-2002/state' with payload:
      """
      { "collections": { "delinquencyState": "significantly-delinquent" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-2002"], "scope": "currentCycle" }
      """
    Then I collect artifact types for 'ACC-2002' in sequence:
      | type                  |
      | Collection Notification |
    And each collected artifact content should contain '9876' and not contain any 13–19 digit numeric sequences
    Given I set 'unable to pay full overdue' for 'ACC-2002' via PUT '/api/accounts/ACC-2002/state' with payload:
      """
      { "collections": { "unableToPayFull": true } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-2002"], "scope": "currentCycle" }
      """
    Then I collect artifact types for 'ACC-2002' in sequence:
      | type                   |
      | Payment Plan Proposal  |
    And each collected artifact content should contain '9876' and not contain any 13–19 digit numeric sequences
    Given I set 'no response to previous notifications' for 'ACC-2002' via PUT '/api/accounts/ACC-2002/state' with payload:
      """
      { "notifications": { "responded": false } }
      """
    When I send a POST request to '/api/lifecycle/escalations/agency' with payload:
      """
      { "accounts": ["ACC-2002"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/agency/handoffs?accountId=ACC-2002'
    Then the response JSON at '$.total' should be 1
    And I store 'handoffId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/agency/handoffs/{{handoffId}}/payload'
    Then the response body should contain '9876' and not contain any 13–19 digit numeric sequences
    Given I set 'extreme non-payment/default' for 'ACC-2002' via PUT '/api/accounts/ACC-2002/state' with payload:
      """
      { "collections": { "extremeDefault": true } }
      """
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-2002"] }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/legal/documents?accountId=ACC-2002'
    Then the response JSON at '$.total' should be 1
    And I store 'docId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/legal/documents/{{docId}}/content'
    Then the response body should contain '9876' and not contain any 13–19 digit numeric sequences

  @api @agency @boundary
  Scenario Outline: Agency handoff identifier validation accepts exactly 4 digits and rejects 3 or 5
    Given the account 'ACC-INT02' exists with last4 '6632'
    When I send a POST request to '/api/agency/handoffs/validate' with payload:
      """
      { "accountId": "ACC-INT02", "identifier": "<idFragment>" }
      """
    Then the response status should be <status>
    And the response JSON at '$.accepted' should be <accepted>

    Examples:
      | idFragment | status | accepted |
      | 123        | 400    | false    |
      | 12345      | 400    | false    |
      | 1234       | 200    | true     |

  @api @masking @boundary
  Scenario: Boundary validation of last-4-only in notifications (reject 3- or 5-digit identifiers)
    Given the account 'ACC-MSK02' exists with last4 '5033'
    And I set the due-date state for account 'ACC-MSK02' to 'missed' via PUT '/api/accounts/ACC-MSK02/state' with payload:
      """
      { "billing": { "dueState": "missed" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-MSK02"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-MSK02&type=Overdue%20Balance%20Alert'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain '5033'
    And the response body should not contain '033'
    And the response body should not contain '15033'
    And the response body should not contain any 13–19 digit numeric sequences

  # API Tests — Association (identifier-to-account correctness)

  @api @association @dueReminder
  Scenario: Due Reminder shows the correct account’s last 4 digits and not another account’s
    Given the account 'ACC-A1' exists with last4 '2744'
    And the account 'ACC-A2' exists with last4 '8801'
    And I set the due-date state for account 'ACC-A1' to 'upcoming' via PUT '/api/accounts/ACC-A1/state' with payload:
      """
      { "billing": { "dueState": "upcoming" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-A1"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-A1&type=Credit%20Card%20Due%20Reminder'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response status should be 200
    And the response body should contain '2744'
    And the response body should not contain '8801'
    And the response body should not contain any 13–19 digit numeric sequences
    When I send a GET request to '/api/artifacts?accountId=ACC-A2&type=Credit%20Card%20Due%20Reminder&createdAfter={{now-10m}}'
    Then the response JSON at '$.total' should be 0

  @api @association @overdue
  Scenario: Overdue Balance Alert shows the correct account’s last 4 digits only
    Given the account 'ACC-B1' exists with last4 '7320'
    And the account 'ACC-B2' exists with last4 '9907'
    And I set the due-date state for account 'ACC-B1' to 'missed' via PUT '/api/accounts/ACC-B1/state' with payload:
      """
      { "billing": { "dueState": "missed" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-B1"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-B1&type=Overdue%20Balance%20Alert'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response body should contain '7320'
    And the response body should not contain '9907'
    And the response body should not contain any 13–19 digit numeric sequences
    When I send a GET request to '/api/artifacts?accountId=ACC-B2&type=Overdue%20Balance%20Alert&createdAfter={{now-10m}}'
    Then the response JSON at '$.total' should be 0

  @api @association @collection
  Scenario: Collection Notification shows only the intended card’s last 4 digits
    Given the account 'ACC-90001' exists with last4 '1803'
    And the account 'ACC-90002' exists with last4 '6629'
    And I set the delinquency state for account 'ACC-90001' to 'significantly-delinquent' via PUT '/api/accounts/ACC-90001/state' with payload:
      """
      { "collections": { "delinquencyState": "significantly-delinquent" } }
      """
    And I record current timestamp as 'T0'
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-90001"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-90001&type=Collection%20Notification&createdAfter={{T0}}'
    Then the response JSON at '$.total' should be 1
    And I store 'artifactId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/artifacts/{{artifactId}}/content'
    Then the response body should contain '1803'
    And the response body should not contain '6629'
    And the response body should not contain any 13–19 digit numeric sequences

  @api @association @legal
  Scenario: Legal documentation shows only the intended card’s last 4 digits
    Given the account 'ACC-94001' exists with last4 '7712'
    And the account 'ACC-94002' exists with last4 '5501'
    And I set legal escalation flag for 'ACC-94001' via PUT '/api/accounts/ACC-94001/state' with payload:
      """
      { "collections": { "extremeDefault": true } }
      """
    And I record current timestamp as 'T0'
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-94001"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/legal/documents?accountId=ACC-94001&createdAfter={{T0}}'
    Then the response JSON at '$.total' should be 1
    And I store 'docId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/legal/documents/{{docId}}/content'
    Then the response body should contain '7712'
    And the response body should not contain '5501'
    And the response body should not contain any 13–19 digit numeric sequences

  # API Tests — State Transition Gating

  @api @state @dueReminder
  Scenario: Upcoming due date generates Due Reminder and suppresses Overdue Alert
    Given the account 'ACC-7007' exists with last4 '2222'
    And I set the due-date state for account 'ACC-7007' to 'upcoming' via PUT '/api/accounts/ACC-7007/state' with payload:
      """
      { "billing": { "dueState": "upcoming" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-7007"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-7007'
    Then the response status should be 200
    And the response body should contain 'Credit Card Due Reminder'
    And the response body should not contain 'Overdue Balance Alert'
    When I send a GET request to '/api/artifacts?accountId=ACC-7007&type=Credit%20Card%20Due%20Reminder'
    Then the response JSON at '$.items[0].content' should contain '2222'

  @api @state @collection
  Scenario: Significant delinquency generates Collection Notification and does not involve agency yet
    Given the account 'ACC-9009' exists with last4 '8899'
    And I set the delinquency state for account 'ACC-9009' to 'significantly-delinquent' via PUT '/api/accounts/ACC-9009/state' with payload:
      """
      { "collections": { "delinquencyState": "significantly-delinquent" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-9009"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-9009'
    Then the response body should contain 'Collection Notification'
    And the response body should not contain 'Collection Agency Involvement'
    When I send a GET request to '/api/artifacts?accountId=ACC-9009&type=Collection%20Notification'
    Then the response JSON at '$.items[0].content' should contain '8899'

  @api @state @proposal
  Scenario: Unable-to-pay branch generates Payment Plan Proposal and does not re-trigger Collection Notification
    Given the account 'ACC-1010' exists with last4 '5555'
    And a prior Collection Notification exists for 'ACC-1010'
    And I set 'unable to pay full overdue' for 'ACC-1010' via PUT '/api/accounts/ACC-1010/state' with payload:
      """
      { "collections": { "unableToPayFull": true } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-1010"], "scope": "currentCycle" }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/artifacts?accountId=ACC-1010&createdAfter={{now-10m}}'
    Then the response body should contain 'Payment Plan Proposal'
    And the response body should not contain 'Collection Notification'
    When I send a GET request to '/api/artifacts?accountId=ACC-1010&type=Payment%20Plan%20Proposal'
    Then the response JSON at '$.items[0].content' should contain '5555'

  @api @state @agency
  Scenario: Failing to respond triggers agency involvement, not legal action
    Given the account 'ACC-ST05' exists with last4 '8421'
    And prior Due Reminder and Overdue Balance Alert exist for 'ACC-ST05'
    And I set 'no response to previous notifications' for 'ACC-ST05' via PUT '/api/accounts/ACC-ST05/state' with payload:
      """
      { "notifications": { "responded": false } }
      """
    When I send a POST request to '/api/lifecycle/escalations/agency' with payload:
      """
      { "accounts": ["ACC-ST05"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/agency/handoffs?accountId=ACC-ST05'
    Then the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].payload' should contain '8421'
    And the response JSON at '$.items[0].payload' should not contain any 13–19 digit numeric sequences
    When I send a GET request to '/api/legal/documents?accountId=ACC-ST05&createdAfter={{now-10m}}'
    Then the response JSON at '$.total' should be 0

  @api @state @legal
  Scenario: Extreme default triggers Legal Action Initiation without earlier-stage notifications
    Given the account 'ACC-ST06' exists with last4 '5590'
    And I set legal escalation flag for 'ACC-ST06' via PUT '/api/accounts/ACC-ST06/state' with payload:
      """
      { "collections": { "extremeDefault": true } }
      """
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-ST06"] }
      """
    Then the response status should be 202
    And I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/legal/documents?accountId=ACC-ST06'
    Then the response JSON at '$.total' should be 1
    And I store 'docId' from the response JSON path '$.items[0].id'
    When I send a GET request to '/api/legal/documents/{{docId}}/content'
    Then the response status should be 200
    And the response body should contain '5590'
    And the response body should not contain any 13–19 digit numeric sequences
    When I send a GET request to '/api/artifacts?accountId=ACC-ST06&createdAfter={{now-10m}}'
    Then the response body should not contain 'Credit Card Due Reminder'
    And the response body should not contain 'Overdue Balance Alert'
    And the response body should not contain 'Collection Notification'

  # API Tests — E2E Paths

  @api @e2e @agency
  Scenario: End-to-end path to agency: Due → Overdue → Collection → Agency, with last-4-only at each step
    Given the account 'ACC-E2E01' exists with last4 '7712'
    And I set the due-date state for account 'ACC-E2E01' to 'upcoming' via PUT '/api/accounts/ACC-E2E01/state' with payload:
      """
      { "billing": { "dueState": "upcoming" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-E2E01"], "scope": "currentCycle" }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    And I send a GET request to '/api/artifacts?accountId=ACC-E2E01&type=Credit%20Card%20Due%20Reminder'
    And the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].content' should contain '7712'
    And the response JSON at '$.items[0].content' should not contain any 13–19 digit numeric sequences
    Given I set the due-date state for account 'ACC-E2E01' to 'missed' via PUT '/api/accounts/ACC-E2E01/state' with payload:
      """
      { "billing": { "dueState": "missed" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-E2E01"], "scope": "currentCycle" }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    And I send a GET request to '/api/artifacts?accountId=ACC-E2E01&type=Overdue%20Balance%20Alert'
    And the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].content' should contain '7712'
    Given I set the delinquency state for account 'ACC-E2E01' to 'significantly-delinquent' via PUT '/api/accounts/ACC-E2E01/state' with payload:
      """
      { "collections": { "delinquencyState": "significantly-delinquent" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-E2E01"], "scope": "currentCycle" }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    And I send a GET request to '/api/artifacts?accountId=ACC-E2E01&type=Collection%20Notification'
    And the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].content' should contain '7712'
    Given I set 'no response to previous notifications' for 'ACC-E2E01' via PUT '/api/accounts/ACC-E2E01/state' with payload:
      """
      { "notifications": { "responded": false } }
      """
    When I send a POST request to '/api/lifecycle/escalations/agency' with payload:
      """
      { "accounts": ["ACC-E2E01"] }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    And I send a GET request to '/api/agency/handoffs?accountId=ACC-E2E01'
    And the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].payload' should contain '7712'
    And the response JSON at '$.items[0].payload' should not contain any 13–19 digit numeric sequences

  @api @e2e @proposal
  Scenario: Branch to Payment Plan Proposal after Overdue when unable to pay full overdue, with last-4-only
    Given the account 'ACC-E2E02' exists with last4 '3398'
    And I set the due-date state for account 'ACC-E2E02' to 'missed' via PUT '/api/accounts/ACC-E2E02/state' with payload:
      """
      { "billing": { "dueState": "missed" } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-E2E02"], "scope": "currentCycle" }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    And I send a GET request to '/api/artifacts?accountId=ACC-E2E02&type=Overdue%20Balance%20Alert'
    And the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].content' should contain '3398'
    Given I set 'unable to pay full overdue' for 'ACC-E2E02' via PUT '/api/accounts/ACC-E2E02/state' with payload:
      """
      { "collections": { "unableToPayFull": true } }
      """
    When I send a POST request to '/api/lifecycle/evaluations' with payload:
      """
      { "accounts": ["ACC-E2E02"], "scope": "currentCycle" }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    And I send a GET request to '/api/artifacts?accountId=ACC-E2E02&type=Payment%20Plan%20Proposal'
    And the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].content' should contain '3398'
    And the response JSON at '$.items[0].content' should contain 'structured repayment schedule'
    And the response JSON at '$.items[0].content' should not contain 'Collection Agency Involvement'
    And the response JSON at '$.items[0].content' should not contain any 13–19 digit numeric sequences

  @api @e2e @legal
  Scenario: Escalation directly to Legal Action for extreme default with last-4-only in documentation
    Given the account 'ACC-E2E03' exists with last4 '0046'
    And I set legal escalation flag for 'ACC-E2E03' via PUT '/api/accounts/ACC-E2E03/state' with payload:
      """
      { "collections": { "extremeDefault": true } }
      """
    When I send a POST request to '/api/lifecycle/escalations/legal' with payload:
      """
      { "accounts": ["ACC-E2E03"] }
      """
    Then I poll GET '/api/jobs/{{lastResponse.jobId}}'
    When I send a GET request to '/api/legal/documents?accountId=ACC-E2E03'
    Then the response JSON at '$.total' should be 1
    And the response JSON at '$.items[0].content' should contain '0046'
    And the response JSON at '$.items[0].content' should not contain any 13–19 digit numeric sequences
    When I send a GET request to '/api/artifacts?accountId=ACC-E2E03&createdAfter={{now-10m}}'
    Then the response body should not contain 'Credit Card Due Reminder'
    And the response body should not contain 'Overdue Balance Alert'
    And the response body should not contain 'Collection Notification'
