Feature: Credit Card Payment Lifecycle Notifications & PII Masking

  # Backgrounds for API and UI tests to set base context and key variables.
  Background:
    Given the system API base URL is "https://api.cardissuer.test"
    And notification, collection, and legal modules are enabled
    And valid test users exist for cardholder, issuer operator, agency, and legal team roles

  # --- API Test Scenarios: Notification generation, delivery, masking, and authorization ---

  @api @functional @security @negative @audit @resilience @performance
  Scenario Outline: Validate Notification Generation and Masking for Payment Lifecycle Events
    Given cardholder "<cardholder_email>" exists with card ending "<card_last4>"
    And notification channel "<notification_channel>" is configured
    And account status is "<account_status>" with balance "<account_balance>"
    When the system triggers "<event_type>" notification for cardholder
    Then the notification is sent via "<notification_channel>"
    And the notification includes only the last 4 digits "<card_last4>"
    And no additional card digits, partial PAN segments, or full PAN ("<card_full>") ever appear in the notification content, metadata, headers, or logs
    And audit logs reflect only last 4 digits, never full card number

    Examples:
      | cardholder_email           | card_last4 | notification_channel | account_status        | account_balance | event_type           | card_full                 |
      | test+user123@example.com   | 4242       | email               | payment_due           | 150.00         | due reminder         | 4242 4242 4242 4242       |
      | test+user124@example.com   | 6589       | portal              | overdue               | 240.70         | overdue alert        | 6589 6589 6589 6589       |
      | test+user125@example.com   | 3478       | letter              | delinquent            | 800.25         | collection notice    | 3478 3478 3478 3478       |
      | test+user126@example.com   | 2314       | email               | legal_escalation      | 1050.00        | legal action notice  | 2314 2314 2314 2314       |
      | test+multi@example.com     | 1111       | email               | payment_due           | 177.00         | due reminder         | 1111 1111 1111 1111       |
      | test+multi@example.com     | 2222       | portal              | overdue               | 299.99         | overdue alert        | 2222 2222 2222 2222       |
      | test+highvol@example.com   | 1001       | email               | payment_due           | 67.00          | due reminder         | 1001 1001 1001 1001       |
      | test+highvol@example.com   | 1002       | email               | overdue               | 87.50          | overdue alert        | 1002 1002 1002 1002       |

  @api @security @negative
  Scenario Outline: Negative - Verify Full Card Number Never Appears in Any Output or Artifact
    Given test account "<cardholder_email>" with card number "<card_full>"
    When system triggers "<event_type>" notification or document for the account
    Then search all system outputs, logs, documents, and API payloads for "<card_full>"
    And no instance of "<card_full>" is ever found
    And only "<card_last4>" is included for card identification

    Examples:
      | cardholder_email         | card_full               | event_type           | card_last4 |
      | test+user123@example.com | 4444333322227210        | due reminder         | 7210      |
      | test+user124@example.com | 4111111111111111        | collection notice    | 1111      |
      | test+user125@example.com | 5999123456789101        | payment plan proposal| 9101      |
      | test+user126@example.com | 5408123456789876        | agency escalation    | 9876      |

  @api @boundary
  Scenario Outline: Boundary Testing - Multi-Cardholder Notification Masking
    Given cardholder "<cardholder_email>" has two credit cards "<cardA_last4>" and "<cardB_last4>"
    When due reminder for card "<cardA_last4>" and overdue alert for "<cardB_last4>" are triggered
    Then each notification references only the relevant last 4 digits of the specific card
    And there is no cross-leakage of digits or PAN segments between notifications

    Examples:
      | cardholder_email       | cardA_last4 | cardB_last4 |
      | test+multi@example.com | 4242        | 6810        |
      | test+multi@example.com | 1111        | 2222        |

  @api @performance
  Scenario Outline: Performance - High Volume Notification Masking and Throughput
    Given bulk upload of "<user_count>" synthetic cardholders with unique cards "<start_last4>" to "<end_last4>"
    When mass due reminder and overdue alert campaigns are triggered
    Then every notification sent contains only the card's last 4 digits
    And system throughput and latency are within "<latency_threshold>" seconds per notification
    And no full card numbers or excess digits appear in sampled outputs

    Examples:
      | user_count | start_last4 | end_last4 | latency_threshold |
      | 1000       | 1000        | 1999      | 1.5              |
      | 2000       | 2000        | 3999      | 2.0              |

  @api @resilience
  Scenario: Resilience - Data Masking Persists After System Crash/Rollback
    Given cardholder account "test+2024@example.com" with card ending "9876"
    And system crash simulation capability is enabled
    When sending an overdue alert, simulate backend failure and crash before completion
    And after recovery, resend overdue alert
    Then all post-crash/recovery logs, notifications, and database entries contain only last 4 digits ("9876")
    And no full card number is exposed due to partial writes or error handling

  @api @audit
  Scenario: Audit - Log Records and Audit Trails Show Only Last 4 Digits
    Given notifications and communications are triggered for test cardholder "test+1001@example.com" with card "**** **** **** 4242"
    When audit logs are downloaded and searched
    Then only last 4 digits ("4242") are found for identification
    And no partial or full card number exposures exist in logs

  # --- API Test Scenarios: Authorization and Privacy for Notification/Collection/Legal Data ---

  @api @security @role
  Scenario Outline: Authorization - Notification Delivery is Restricted to Intended Recipient
    Given cardholder "<cardholder_email>" with card "<card_last4>" is due for reminder
    When due reminder is triggered
    Then only "<cardholder_email>" receives the notification
    And unauthorized user "<unauth_user_email>" cannot access the due reminder via any means
    And access attempts are denied and logged

    Examples:
      | cardholder_email           | card_last4 | unauth_user_email         |
      | test+authz@example.com     | 3086       | test+intruder@example.com |

  @api @security @role
  Scenario Outline: Authorization - Collection Agency Receives Only Case Details with Last 4 Digits
    Given case is assigned to agency user "<agency_user_email>" for cardholder "<cardholder_email>" with card "<card_last4>"
    When collection notification is escalated and delivered to agency
    Then only "<agency_user_email>" receives the case details with only last 4 digits
    And other users "<other_agency_email>", "<other_user_email>" are denied access
    And no card digits beyond last 4 ever appear

    Examples:
      | agency_user_email          | cardholder_email        | card_last4 | other_agency_email     | other_user_email         |
      | collagcy+agent@test.com    | test+collagcy@example.com | 9001       | collagcy+other@test.com | test+intruder@example.com |

  @api @security @role
  Scenario Outline: Authorization - Legal Team Access Controls Legal Documentation
    Given legal team user "<legal_user_email>" accesses documentation for cardholder "<cardholder_email>" with card "<card_last4>"
    When document is opened
    Then only last 4 digits ("<card_last4>") are present anywhere in the content
    And unauthorized user "<unauth_user_email>" is denied access
    And audit logs confirm exclusive access by legal team

    Examples:
      | legal_user_email      | cardholder_email        | card_last4 | unauth_user_email         |
      | legalteam+1@test.com  | test+legal@example.com  | 7165       | test+intruder@example.com |

  @api @negative @role
  Scenario Outline: Negative - Unauthorized Users Cannot Access Sensitive Notification Data
    Given cardholder "<cardholder_email>" has overdue notification sent
    When unauthorized user "<unauth_user_email>" attempts to access notification via UI, API, or direct URL
    Then access is denied, error returned
    And no last 4 digits or other card number segments are present in response or logs

    Examples:
      | cardholder_email         | unauth_user_email         |
      | test+user123@example.com | test+intruder@example.com |

  # --- UI Test Scenarios: Portal, Email, and Letter Document Display/Review ---

  @ui @functional @security @negative
  Scenario Outline: UI - Verify Notification Content Only Displays Last 4 Digits (Portal, Email, Letter)
    Given I am logged in as "<role>" on the "<channel>" (portal/email/letter)
    And my account card is "<card_last4>"
    When I receive or open "<notification_type>" caused by "<trigger_event>"
    Then I should see only the last 4 digits "<card_last4>" referenced for identification
    And no other digits, masked or unmasked, are visible in the subject, body, headers, or attachments

    Examples:
      | role            | channel    | notification_type         | trigger_event         | card_last4 |
      | cardholder      | portal     | overdue alert             | missed payment        | 6589      |
      | cardholder      | email      | due reminder              | payment due upcoming  | 4242      |
      | collections agent | letter   | collection notice         | significant delinquency| 3478      |
      | legal support   | letter     | legal action notice       | legal escalation      | 2314      |

  @ui @boundary @functional
  Scenario Outline: UI - Notifications for Multi-Cardholders Show Individual Last 4 Digits
    Given I am logged in as "cardholder" with multiple cards "<cardA_last4>", "<cardB_last4>"
    When I navigate to notifications section for "<card_ref>"
    Then only "<card_ref>" (last 4 digits) is shown in the notification for the relevant card
    And no digits of the other card appear in content or logs

    Examples:
      | cardA_last4 | cardB_last4 | card_ref |
      | 4242        | 6810        | 4242     |
      | 4242        | 6810        | 6810     |

  # --- UI Test Scenarios: State-Transitions and End-to-End Masking ---

  @ui @state-transition @e2e
  Scenario Outline: UI - End-to-End Notification Journey Masking at Each Stage
    Given I am "<role>" for account "<cardholder_email>" with card "<card_last4>"
    When the workflow transitions through "<stage>" (due reminder, overdue, collection, payment plan, agency, legal)
    Then the relevant notification/document is available in "<channel>"
    And only last 4 digits ("<card_last4>") appear in content and identification fields
    And never any partial or full card number anywhere

    Examples:
      | role              | cardholder_email         | card_last4 | stage                | channel        |
      | cardholder        | test+user123@example.com | 4242       | due reminder         | email          |
      | cardholder        | test+user124@example.com | 6589       | overdue              | portal         |
      | collections agent | test+user125@example.com | 3478       | collection notice    | letter         |
      | legal support     | test+user126@example.com | 2314       | legal action notice  | letter/email   |

  @ui @state-transition
  Scenario Outline: UI - Payment Status Updates Only After Predecessor Events
    Given I am a cardholder with account "<account_status>"
    When I miss payment and due date passes
    Then my account status changes to "<next_status>"
    And the alert or notification includes only last 4 digits of my card ("<card_last4>")
    And audit logs confirm no extra PII is exposed

    Examples:
      | account_status | next_status | card_last4 |
      | payment_due    | overdue     | 7623      |
      | overdue        | delinquent  | 8842      |
      | delinquent     | plan_proposed| 5567     |
      | plan_proposed  | legal       | 7165     |

  # --- API Test Scenarios: State-Transition Enforcement for Escalation and Masking ---

  @api @state-transition
  Scenario Outline: State-Transition - Escalation Only After Previous Notifications Unanswered
    Given cardholder account "<cardholder_email>" with overdue balance "<card_last4>"
    And prior notifications are sent and unacknowledged
    When the system triggers escalation to "<escalation_type>"
    Then only last 4 digits ("<card_last4>") are included in communication to "<recipient>"
    And escalation occurs only after all predecessor events are completed

    Examples:
      | cardholder_email         | card_last4 | escalation_type     | recipient          |
      | test+user123@example.com | 4242       | collection agency   | agency_user        |
      | test+user124@example.com | 6589       | legal action        | legal_support_user |

  # --- API Test Scenarios: Boundary/Threshold-Driven Escalations ---

  @api @boundary
  Scenario Outline: Boundary - Escalation Triggers Only at Threshold Amounts
    Given test account "<cardholder_email>" with overdue balance "<balance>"
    When overdue balance equals or crosses escalation threshold "<threshold>"
    And notifications and escalations are triggered
    Then notification/escalation is sent with only last 4 digits ("<card_last4>")
    And events do not occur below threshold

    Examples:
      | cardholder_email         | balance | threshold | card_last4 |
      | test+legalbound@example.com | 48.99  | 50.00     | 7623      |
      | test+legalbound@example.com | 50.00  | 50.00     | 7623      |
      | test+legalbound@example.com | 51.00  | 50.00     | 7623      |

  # --- API Test Scenarios: Payment Plan Proposal and Terms Masking ---

  @api @functional @security
  Scenario Outline: Payment Plan Proposal and Reduced Rates Masking
    Given overdue cardholder "<cardholder_email>" eligible for plan, card "<card_last4>"
    When payment plan proposal is generated with reduced rate/fee "<rate>"
    And proposal is sent to cardholder
    Then proposal contains only last 4 digits ("<card_last4>") and reduced rate/fee ("<rate>")
    And no part of full card number is present

    Examples:
      | cardholder_email         | card_last4 | rate       |
      | test+plan@example.com    | 5567       | 12%        |
      | test+plan2@example.com   | 6329       | 9.9%       |

  # --- API Test Scenarios: Agency Integration and Privacy Enforcement ---

  @api @security @state-transition
  Scenario Outline: Collection Agency Integration Only Discloses Last 4 Digits
    Given cardholder "<cardholder_email>" with overdue balance, account escalated to agency
    When integration package is prepared and transmitted to agency endpoint
    Then only last 4 digits ("<card_last4>") are sent in API payloads and artifacts
    And search for full or partial PAN fails in all agency outputs/logs

    Examples:
      | cardholder_email         | card_last4 |
      | test+collagcy@example.com| 9001      |
      | test+agency@example.com  | 9876      |

  # --- API Test Scenarios: Legal Action Initiation and Legal Document Masking ---

  @api @security @functional
  Scenario Outline: Legal Action Documentation Only Shows Last 4 Digits
    Given account "<account_email>" is escalated to legal action with card ending "<card_last4>"
    When legal documentation is generated for external correspondence
    Then only last 4 digits ("<card_last4>") appear in every document and attachment
    And no full or partial PAN is exposed in content, metadata, headers, or logs

    Examples:
      | account_email           | card_last4 |
      | test+legal@example.com  | 7165      |
      | test+legalbound@example.com | 7623   |

  # --- API Test Scenarios: End-to-End Lifecycle Masking Enforcement ---

  @api @e2e
  Scenario: End-to-End - Notification Masking Through Entire Payment Lifecycle
    Given credit card account "test+user123@example.com" is active with card ending "4242"
    When lifecycle progresses from due reminder, overdue alert, collection notification, payment plan proposal, agency collection, to legal action
    Then at every stage, only last 4 digits ("4242") are present in notification/documents, and full card number is never exposed
    And privacy and compliance rules are maintained throughout

