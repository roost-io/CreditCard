Feature: User Registration and Consent

Background:
  Given the API base URL 'http://api.financialapp.com'
  And the authorization header is set
  And the content type is 'application/json'

Scenario: Successful User Registration and Consent
  Given Sarah has the app installed on her mobile device
  When I send a POST request to '/users/register' with the following payload:
    | name     | email             | password  |
    | Sarah    | sarah@example.com | password1 |
  Then the response status should be 201
  And the response should contain 'account created successfully'
  When I send a POST request to '/users/consent' with the following payload:
    | consent | true |
  Then the response status should be 200
  And the response should contain 'consent granted'
