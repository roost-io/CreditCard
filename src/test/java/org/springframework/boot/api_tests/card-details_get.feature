# ********RoostGPT********

# Test generated by RoostGPT for test CrediCard-Karate using AI Type Claude AI and AI Model claude-3-opus-20240229
# 
# Feature file generated for /card-details_get for http method type GET 
# RoostTestHash=5ddd408670
# 
# 

# ********RoostGPT********
Feature: Card Details API

Background:
    * def urlBase = karate.properties['url.base'] || karate.get('urlBase', 'http://localhost:8080')
    * url urlBase
    * def authToken = karate.properties['AUTH_TOKEN']

Scenario: Get card details successfully
    Given path '/card-details'
    And header Authorization = 'Bearer ' + authToken
    When method GET
    Then status 200
    And match response == { cardNumberPartial: '#string' }
    # And match responseHeaders['Content-Type'][0] contains 'application/json'

# Not implemented in spec
Scenario: Get card details with missing authorization token
    * configure headers = null
    Given path '/card-details'
    When method GET
    Then status 401
    And match responseHeaders['Content-Type'][0] contains 'application/json'

# Scenario: Get card details with invalid authorization token
#     Given path '/card-details'
#     And header Authorization = 'Bearer invalid_token'
#     When method GET
#     Then status 401
#     And match responseHeaders['Content-Type'][0] contains 'application/json'
