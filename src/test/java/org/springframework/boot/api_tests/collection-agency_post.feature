# ********RoostGPT********

# Test generated by RoostGPT for test CrediCard-Karate using AI Type Claude AI and AI Model claude-3-opus-20240229
# 
# Feature file generated for /collection-agency_post for http method type POST 
# RoostTestHash=644e698815
# 
# 

# ********RoostGPT********
Feature: Collection Agency Involvement API

Background:
  * def urlBase = karate.properties['url.base'] || karate.get('urlBase', 'http://localhost:8080')
  * url urlBase
  * def authToken = karate.properties['AUTH_TOKEN']

Scenario Outline: Test Collection Agency Involvement API with valid inputs
  Given path '/collection-agency'
  And header Authorization = 'Bearer ' + authToken
  And request
    """
    {
      "previousNotifications": "<previousNotifications>",
      "responseStatus": "<responseStatus>",
      "cardLast4": "<cardLast4>"
    }
    """
  When method POST
  Then status 200
  And match response == "#string"

  Examples:
    | previousNotifications | responseStatus | cardLast4 |
    | Notified              | Success        | 1234      |
    | Not Notified          | Failed         | 5678      |

Scenario: Test Collection Agency Involvement API with missing required fields
  Given path '/collection-agency'
  And header Authorization = 'Bearer ' + authToken
  And request
    """
    {
      "previousNotifications": "Notified"
    }
    """
  When method POST
  Then status 422
  # And match response contains "Missing required fields"

Scenario: Test Collection Agency Involvement API with invalid cardLast4 length
  Given path '/collection-agency'  
  And header Authorization = 'Bearer ' + authToken
  And request
    """
    {
      "previousNotifications": "Notified",
      "responseStatus": "Success", 
      "cardLast4": "12345"
    }
    """
  When method POST
  Then status 422
  # And match response contains "Invalid cardLast4 length"
