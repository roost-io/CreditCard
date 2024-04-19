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

Scenario Outline: Payment Plan Proposal - <scenario>
  Given path '/payment-plan-proposal'
  And header Authorization = 'Bearer ' + authToken
  And request 
  """
  {
    "outstandingBalance": "<outstandingBalance>" 
  }
    """
  
  When method POST
  Then status <statusCode>
  # And match response == <expectedResponse>

  Examples:
    | scenario         | outstandingBalance | installmentAmount | interestRate | termLength | cardLast4 | statusCode | expectedResponse |
    | Valid Proposal   | 1000.00            | 100.00            | 5.0          | 12         | "1234"    | 200        | "OK"             |
    | Missing Balance  | null               | 100.00            | 5.0          | 12         | "1234"    | 422        | "Bad Request"    |
    | Invalid Card     | 1000.00            | 100.00            | 5.0          | 12         | "123"     | 422        | "Bad Request"    |
    | Negative Balance | -1000.00           | 100.00            | 5.0          | 12         | "1234"    | 422        | "Bad Request"    |
