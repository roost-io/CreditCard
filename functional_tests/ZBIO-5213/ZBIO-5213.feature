Feature: Collections communications lifecycle and PAN minimization compliance

  # API Tests
  Background:
    Given the API base URL is set from environment variable 'API_BASE_URL'
    And I have a valid OAuth2 access token from environment variable 'API_TOKEN'
    And I set header 'Authorization' to 'Bearer ${API_TOKEN}'
    And I set header 'Content-Type' to 'application/json'

  @api @security
  Scenario Outline: Communications include exact last 4 digits and contain no 5+ digit runs
    Given account '<accountId>' exists and is eligible for '<stage>'
    When I send a POST request to '<trigger_endpoint>' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<last4>"
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'artifactId'
    When I poll GET '<fetch_endpoint>/${artifactId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain the exact string "<last4>"
    And the artifact body should have zero matches for regex "[0-9]{5,}"
    And I mark the artifact '${artifactId}' as test-only via PATCH '<fetch_endpoint>/${artifactId}':
      """
      { "testOnly": true }
      """

    Examples:
      | stage           | accountId | last4 | trigger_endpoint                                    | fetch_endpoint                         |
      | Due Reminder    | ACC-1001  | 1234  | /api/collections/communications/due-reminders       | /api/collections/communications       |
      | Overdue Alert   | ACC-2001  | 5678  | /api/collections/communications/overdue-alerts      | /api/collections/communications       |

  @api @boundary
  Scenario Outline: Leading zeros in last4 are preserved in communications/documents
    Given account '<accountId>' exists and is eligible for '<stage>'
    When I send a POST request to '<trigger_endpoint>' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "0123"
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'artifactId'
    When I poll GET '<fetch_endpoint>/${artifactId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain the exact string "0123"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

    Examples:
      | stage             | accountId | trigger_endpoint                                    | fetch_endpoint                         |
      | Due Reminder      | ACC-1002  | /api/collections/communications/due-reminders       | /api/collections/communications       |
      | Payment Proposal  | ACC-PP04  | /api/collections/proposals/payment-plans            | /api/collections/proposals            |

  @api @negative @boundary
  Scenario Outline: Reject generation when last4 length is not exactly 4
    Given account '<accountId>' exists and is eligible for '<stage>'
    When I send a POST request to '<trigger_endpoint>' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<invalidLast4>"
      }
      """
    Then the response status should be 400 or 422
    And the error message should mention "last4" and "4"
    When I send a GET request to '<outbox_endpoint>?accountId=<accountId>&stage=<stage>'
    Then the response status should be 200
    And the list should have size 0

    Examples:
      | stage                | accountId | invalidLast4 | trigger_endpoint                                       | outbox_endpoint                         |
      | Due Reminder         | ACC-1003  | 123          | /api/collections/communications/due-reminders          | /api/collections/communications/outbox  |
      | Due Reminder         | ACC-1003  | 12345        | /api/collections/communications/due-reminders          | /api/collections/communications/outbox  |
      | Overdue Alert        | ACC-2003  | 89101        | /api/collections/communications/overdue-alerts         | /api/collections/communications/outbox  |
      | Overdue Alert        | ACC-2003  | 12345        | /api/collections/communications/overdue-alerts         | /api/collections/communications/outbox  |
      | Collection Notice    | ACC-3004  | 123          | /api/collections/communications/collection-notifications| /api/collections/communications/outbox  |

  @api @negative
  Scenario Outline: Reject generation when last4 is missing (empty or null)
    Given account 'ACC-2002' exists and is eligible for 'Overdue Alert'
    When I send a POST request to '/api/collections/communications/overdue-alerts' with body:
      """
      {
        "accountId": "ACC-2002",
        "last4": <json_last4>
      }
      """
    Then the response status should be 400 or 422
    And the error message should mention "last4" and "required"
    When I send a GET request to '/api/collections/communications/outbox?accountId=ACC-2002&stage=Overdue Alert'
    Then the response status should be 200
    And the list should have size 0

    Examples:
      | json_last4 |
      | ""         |
      | null       |

  @api @negative @security
  Scenario: Block Overdue Alert when body contains a 5+ digit sequence
    Given account 'ACC-PAN-OVD-01' exists and is eligible for 'Overdue Alert'
    When I send a POST request to '/api/collections/communications/overdue-alerts' with body:
      """
      {
        "accountId": "ACC-PAN-OVD-01",
        "last4": "7890"
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'validId'
    When I poll GET '/api/collections/communications/${validId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain the exact string "7890"
    And the artifact body should have zero matches for regex "[0-9]{5,}"
    When I send a POST request to '/api/collections/communications/overdue-alerts' with body:
      """
      {
        "accountId": "ACC-PAN-OVD-01",
        "last4": "7890",
        "overrideBody": "Tampered body including 56789 to simulate violation."
      }
      """
    Then the response status should be 400 or 422
    And the error message should contain "digit sequence longer than 4" or "PAN policy"
    When I send a GET request to '/api/collections/communications/outbox?accountId=ACC-PAN-OVD-01&stage=Overdue Alert'
    Then the response status should be 200
    And the list should contain exactly 1 item with id '${validId}'

  @api
  Scenario Outline: Collection Notification includes amount owed, additional charges, and last4
    Given account '<accountId>' exists and is eligible for 'Collection Notification'
    When I send a POST request to '/api/collections/communications/collection-notifications' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<last4>",
        "context": {
          "amountOwed": "<amountOwed>",
          "additionalCharges": "<additionalCharges>"
        }
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'cnId'
    When I poll GET '/api/collections/communications/${cnId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain "amount owed"
    And the artifact body should contain "<amountOwed>"
    And the artifact body should contain "additional charges"
    And the artifact body should contain "<additionalCharges>"
    And the artifact body should contain the exact string "<last4>"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 | amountOwed | additionalCharges |
      | ACC-3001  | 4321  | 250.00     | 25.00             |

  @api @negative
  Scenario Outline: Reject Collection Notification when required monetary fields are omitted
    Given account '<accountId>' exists and is eligible for 'Collection Notification'
    When I send a POST request to '/api/collections/communications/collection-notifications' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<last4>",
        "context": <context_json>
      }
      """
    Then the response status should be 400 or 422
    And the error message should contain "<expectedError>"
    When I send a GET request to '/api/collections/communications/outbox?accountId=<accountId>&stage=Collection Notification'
    Then the response status should be 200
    And the list should have size 0

    Examples:
      | accountId | last4 | context_json                                                                 | expectedError           |
      | ACC-3002  | 2468  | {"additionalCharges":"25.00"}                                                | missing amount owed     |
      | ACC-3003  | 1357  | {"amountOwed":"275.00"}                                                      | missing additional      |

  @api @security
  Scenario: Collection Notification content and persisted copy never expose full PAN
    Given account 'ACC-2005' exists and is eligible for 'Collection Notification'
    When I send a POST request to '/api/collections/communications/collection-notifications' with body:
      """
      {
        "accountId": "ACC-2005",
        "last4": "9876",
        "context": { "amountOwed":"100.00", "additionalCharges":"10.00" }
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'cnId'
    When I poll GET '/api/collections/communications/${cnId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain the exact string "9876"
    And the artifact body should have zero matches for regex "[0-9]{5,}"
    When I send a GET request to '/api/collections/communications/${cnId}/audit'
    Then the response status should be 200
    And the field 'last4' should equal "9876"
    And the 'storedCopy' text should have zero matches for regex "[0-9]{5,}"
    And the 'redactionWarnings' list should be empty

  @api
  Scenario Outline: Missed due date generates Overdue Balance Alert with last4 only
    Given account '<accountId>' exists
    And I send a PATCH request to '/api/collections/accounts/<accountId>/state' with body:
      """
      { "status":"due_date_missed" }
      """
    Then the response status should be 200
    When I send a POST request to '/api/collections/lifecycle/evaluations' with body:
      """
      { "accountId":"<accountId>" }
      """
    Then the response status should be 200
    When I send a GET request to '/api/collections/communications/outbox?accountId=<accountId>&stage=Overdue Alert'
    Then the response status should be 200
    And the list should contain exactly 1 item and save its 'id' as 'ovdId'
    When I send a GET request to '/api/collections/communications/${ovdId}'
    Then the response status should be 200
    And the artifact body should contain the exact string "<last4>"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 |
      | ACC-4001  | 1230  |
      | ACC-DCRT1 | 3456  |

  @api
  Scenario Outline: Significantly delinquent generates a Collection Notification with required sections
    Given account '<accountId>' exists
    And I send a PATCH request to '/api/collections/accounts/<accountId>/state' with body:
      """
      { "status":"significantly_delinquent" }
      """
    Then the response status should be 200
    When I send a POST request to '/api/collections/lifecycle/evaluations' with body:
      """
      { "accountId":"<accountId>" }
      """
    Then the response status should be 200
    When I send a GET request to '/api/collections/communications/outbox?accountId=<accountId>&stage=Collection Notification'
    Then the response status should be 200
    And the list should contain exactly 1 item and save its 'id' as 'cnId'
    When I send a GET request to '/api/collections/communications/${cnId}'
    Then the response status should be 200
    And the artifact body should contain "amount owed"
    And the artifact body should contain "additional charges"
    And the artifact body should contain the exact string "<last4>"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 |
      | ACC-4002  | 5555  |
      | ACC-DCRT2 | 7777  |

  @api
  Scenario Outline: Non-response escalates to Collection Agency involvement with last4-only payload
    Given account '<accountId>' exists
    And the account '<accountId>' has prior notifications 'Due Reminder' and 'Collection Notification' with no response
    When I send a POST request to '/api/collections/lifecycle/evaluations' with body:
      """
      { "accountId":"<accountId>", "evaluateAgencyInvolvement": true }
      """
    Then the response status should be 200
    When I send a GET request to '/api/integrations/collection-agency/handoffs?accountId=<accountId>'
    Then the response status should be 200
    And the list should contain exactly 1 item and save its 'id' as 'handoffId'
    When I send a GET request to '/api/integrations/collection-agency/handoffs/${handoffId}'
    Then the response status should be 200
    And the field 'identification.last4' should equal "<last4>"
    And the payload text should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 |
      | ACC-4003  | 8642  |
      | ACC-DCRT3 | 3333  |

  @api
  Scenario: Persistent default escalates to Legal Action with last4-only legal document
    Given account 'ACC-4004' exists
    And I send a PATCH request to '/api/collections/accounts/ACC-4004/state' with body:
      """
      { "status":"default_persistent" }
      """
    Then the response status should be 200
    When I send a POST request to '/api/collections/lifecycle/evaluations' with body:
      """
      { "accountId":"ACC-4004", "evaluateLegalAction": true }
      """
    Then the response status should be 200
    When I send a GET request to '/api/collections/legal/documents?accountId=ACC-4004'
    Then the response status should be 200
    And the list should contain at least 1 item and save its 'id' as 'docId'
    When I send a GET request to '/api/collections/legal/documents/${docId}'
    Then the response status should be 200
    And the document text should contain the exact string "7410"
    And the document text should have zero matches for regex "[0-9]{5,}"

  @api
  Scenario Outline: Agency handoff payload includes only last4 for identification
    Given account '<accountId>' exists and is queued for agency involvement
    When I send a POST request to '/api/integrations/collection-agency/handoffs' with body:
      """
      {
        "accountId": "<accountId>",
        "identification": { "last4": "<last4>" }
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'handoffId'
    When I poll GET '/api/integrations/collection-agency/handoffs/${handoffId}' until 'status' equals 'ready' or for up to 60 seconds
    Then the response status should be 200
    And the field 'identification.last4' should equal "<last4>"
    And the payload text should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 |
      | ACC-AG02  | 5678  |
      | ACC-2005  | 1234  |

  @api @negative
  Scenario: Agency handoff is blocked when payload contains more than last 4 digits
    Given account 'ACC-AG03' exists and is queued for agency involvement
    When I send a POST request to '/api/integrations/collection-agency/handoffs' with body:
      """
      {
        "accountId": "ACC-AG03",
        "identification": { "last4": "123456" }
      }
      """
    Then the response status should be 400 or 422
    And the error message should contain "last4" and "4"
    When I send a GET request to '/api/integrations/collection-agency/handoffs?accountId=ACC-AG03'
    Then the response status should be 200
    And the list should have size 0
    When I send a POST request to '/api/integrations/collection-agency/handoffs' with body:
      """
      {
        "accountId": "ACC-AG03",
        "identification": { "last4": "2468" }
      }
      """
    Then the response status should be 202

  @api @negative
  Scenario: Agency handoff rejects non-numeric last4
    Given account 'ACC-AG04' exists and is queued for agency involvement
    When I send a POST request to '/api/integrations/collection-agency/handoffs' with body:
      """
      {
        "accountId": "ACC-AG04",
        "identification": { "last4": "12A4" }
      }
      """
    Then the response status should be 400 or 422
    And the error message should contain "numeric"
    When I send a GET request to '/api/integrations/collection-agency/handoffs?accountId=ACC-AG04'
    Then the response status should be 200
    And the list should have size 0
    When I send a POST request to '/api/integrations/collection-agency/handoffs' with body:
      """
      {
        "accountId": "ACC-AG04",
        "identification": { "last4": "3456" }
      }
      """
    Then the response status should be 202

  @api
  Scenario: Do not involve agency when customer responded to previous notifications
    Given account 'ACC-2006' exists with prior notifications and a recorded customer response
    When I send a POST request to '/api/collections/lifecycle/evaluations' with body:
      """
      { "accountId":"ACC-2006", "evaluateAgencyInvolvement": true }
      """
    Then the response status should be 200
    When I send a GET request to '/api/integrations/collection-agency/handoffs?accountId=ACC-2006'
    Then the response status should be 200
    And the list should have size 0
    When I send a GET request to '/api/integrations/collection-agency/logs?accountId=ACC-2006'
    Then the response status should be 200
    And the list should have size 0

  @api @security
  Scenario Outline: Legal documentation includes only last4 and never full PAN
    Given account '<accountId>' exists and is eligible for 'Legal Action'
    When I send a POST request to '/api/collections/legal/actions' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<last4>"
      }
      """
    Then the response status should be 202
    And I save the 'documentId' field from the response as 'docId'
    When I poll GET '/api/collections/legal/documents/${docId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the document text should contain the exact string "<last4>"
    And the document text should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 |
      | ACC-3001  | 9876  |
      | ACC-3002  | 2468  |

  @api
  Scenario: Extreme non-payment/default initiates Legal Action and produces documentation
    Given account 'ACC-3003' exists with condition 'extreme_non_payment_default'
    When I send a POST request to '/api/collections/legal/actions' with body:
      """
      { "accountId":"ACC-3003", "last4":"1357" }
      """
    Then the response status should be 202
    And I save the 'documentId' field from the response as 'docId'
    When I poll GET '/api/collections/legal/documents/${docId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the document text should contain the exact string "1357"
    And the document text should have zero matches for regex "[0-9]{5,}"

  @api
  Scenario Outline: Payment Plan Proposal contains structured schedule, reduced interest/fees, and last4
    Given account '<accountId>' exists and is overdue with hardship eligibility
    When I send a POST request to '/api/collections/proposals/payment-plans' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<last4>"
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'ppId'
    When I poll GET '/api/collections/proposals/${ppId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain "structured repayment schedule"
    And the artifact body should contain "reduced interest" or "reduced fees"
    And the artifact body should contain the exact string "<last4>"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

    Examples:
      | accountId | last4 |
      | ACC-PP01  | 1234  |
      | ACC-PANPP | 6011  |

  @api @negative
  Scenario Outline: Payment Plan Proposal is rejected when required section is missing
    Given account '<accountId>' exists and is overdue with hardship eligibility
    When I send a POST request to '/api/collections/proposals/payment-plans' with body:
      """
      {
        "accountId": "<accountId>",
        "last4": "<last4>",
        "suppressSections": ["<missingSection>"]
      }
      """
    Then the response status should be 400 or 422
    And the error message should contain "<errorContains>"
    When I send a GET request to '/api/collections/proposals?accountId=<accountId>'
    Then the response status should be 200
    And the list should have size 0

    Examples:
      | accountId | last4 | missingSection      | errorContains                 |
      | ACC-PP02  | 7788  | structured_schedule | structured repayment schedule |
      | ACC-PP03  | 9911  | reduced_interest    | reduced interest              |

  @api
  Scenario: Overdue Alert references the correct card for multi-card holder
    Given customer 'CUST-MULTI-01' exists with two cards A(last4='1111') and B(last4='2222')
    And I mark only card B as due_date_missed
    When I send a POST request to '/api/collections/lifecycle/evaluations' with body:
      """
      { "customerId":"CUST-MULTI-01" }
      """
    Then the response status should be 200
    When I send a GET request to '/api/collections/communications/outbox?customerId=CUST-MULTI-01&stage=Overdue Alert'
    Then the response status should be 200
    And the list should contain exactly 1 item and save its 'id' as 'ovdId'
    When I send a GET request to '/api/collections/communications/${ovdId}'
    Then the response status should be 200
    And the artifact body should contain the exact string "2222"
    And the artifact body should not contain the string "1111"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

  @api @negative
  Scenario: Block communication when provided last4 does not match the targeted card
    Given customer 'CUST-2001' exists with CardA(last4='1234') and CardB(last4='5678')
    And a payment due event exists for CardA
    When I send a POST request to '/api/collections/communications/due-reminders' with body:
      """
      {
        "customerId": "CUST-2001",
        "cardRef": "CardA",
        "last4": "5679"
      }
      """
    Then the response status should be 400 or 422
    And the error message should contain "last4 does not match"
    When I send a GET request to '/api/collections/communications/outbox?customerId=CUST-2001&cardRef=CardA&stage=Due Reminder'
    Then the response status should be 200
    And the list should have size 0
    When I send a POST request to '/api/collections/communications/due-reminders' with body:
      """
      {
        "customerId": "CUST-2001",
        "cardRef": "CardA",
        "last4": "1234"
      }
      """
    Then the response status should be 202
    And I save the 'id' field from the response as 'drId'
    When I poll GET '/api/collections/communications/${drId}' until 'status' equals 'generated' or for up to 60 seconds
    Then the response status should be 200
    And the artifact body should contain the exact string "1234"
    And the artifact body should have zero matches for regex "[0-9]{5,}"

  @api @security
  Scenario: Cross-artifact scan enforces last-4-only across all stages
    Given account 'ACC-ALL-0123' exists with last4 '0123'
    When I sequentially generate the artifacts Due Reminder, Overdue Alert, Collection Notification, Payment Plan Proposal, and Legal Document for 'ACC-ALL-0123'
    Then each artifact should contain the exact string "0123"
    And each artifact should have zero matches for regex "[0-9]{5,}"

  @api @e2e
  Scenario: End-to-end non-responder escalation to legal with last-4-only at every stage
    Given customer 'CUST-5001' exists with masked card **** **** **** 9876
    When I generate a Due Reminder for 'CUST-5001' and verify only "9876" appears
    And I set status to 'missed due date' and generate an Overdue Alert verifying only "9876" appears
    And I set status to 'significantly delinquent' and generate a Collection Notification verifying amount owed, additional charges, and only "9876" appears
    And I mark 'no response' and initiate Collection Agency involvement verifying the handoff payload contains only "9876"
    And I set 'persistent default' and generate Legal Documentation verifying only "9876" appears
    Then a final cross-artifact audit should confirm no artifact contains any match for regex "[0-9]{5,}"

  @api @e2e
  Scenario: End-to-end hardship path to Payment Plan Proposal with last-4-only
    Given customer 'CUST-6001' exists with masked card **** **** **** 0456 and hardship eligibility
    When I generate a Due Reminder and an Overdue Alert verifying only "0456" appears
    And I generate a Payment Plan Proposal verifying it contains a structured repayment schedule and reduced interest/fees and only "0456" appears
    Then all generated artifacts should have zero matches for regex "[0-9]{5,}"
