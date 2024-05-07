# ********RoostGPT********

# Test generated by RoostGPT for test CrediCard-Karate using AI Type Claude AI and AI Model claude-3-opus-20240229
# 
# Feature file generated for /payment-plan-proposal_post for http method type POST 
# RoostTestHash=d3a3b1cdaa
# 
# 

# ********RoostGPT********
Feature: Payment Plan Proposal API

  Background:
    * def urlBase = karate.properties['url.base'] || karate.get('urlBase', 'http://localhost:8080')
    * url urlBase
    * def authToken = karate.properties['AUTH_TOKEN']
    * configure headers = { 'Authorization': '#(authToken)' }

  Scenario Outline: Submit payment plan proposal
    Given path '/payment-plan-proposal'
    And request
      """
      {
        "outstandingBalance": "<outstandingBalance>",
        "paymentPlan": {
          "installmentAmount": "<installmentAmount>",
          "interestRate": "<interestRate>",
          "termLength": "<termLength>"
        },
        "cardLast4": "<cardLast4>"
      }
      """
    When method POST
    Then status 200
    And match response == "#string"

    Examples:
      | outstandingBalance | installmentAmount | interestRate | termLength | cardLast4 |
      | 1000.00            | 100.00            | 5.00         | 12         | 1234      |
      | 2500.50            | 250.00            | 3.50         | 10         | 5678      |

  Scenario: Submit payment plan proposal with missing required fields
    Given path '/payment-plan-proposal' 
    And request
      """
      {
        "outstandingBalance": "1000.00",
        "paymentPlan": {
          "installmentAmount": "100.00",
          "interestRate": "5.00"
        }
      }
      """
    When method POST
    Then status 400
    And match response contains "Missing required fields"

  Scenario: Submit payment plan proposal with invalid card last 4 digits
    Given path '/payment-plan-proposal'
    And request 
      """
      {
        "outstandingBalance": "1000.00",
        "paymentPlan": {
          "installmentAmount": "100.00", 
          "interestRate": "5.00",
          "termLength": "12"
        },
        "cardLast4": "12345"
      }
      """
    When method POST 
    Then status 400
    And match response contains "Invalid card last 4 digits"
