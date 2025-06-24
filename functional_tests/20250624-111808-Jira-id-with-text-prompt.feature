Feature: Comment Management API Testing

Scenario: Verify Comment Addition
  Given the API base URL 'http://localhost:3000'
  And a file endpoint '/files/123/comments'
  When I send a POST request to '/files/123/comments' with payload {"comment": "This test is created by Divyesh Maheshwari."}
  Then the response status should be 201
  And the response should contain "This test is created by Divyesh Maheshwari."

Scenario: Prevent Comment Addition to Read-Only File
  Given the API base URL 'http://localhost:3000'
  And a read-only file endpoint '/files/456/comments'
  When I send a POST request to '/files/456/comments' with payload {"comment": "This test is created by Divyesh Maheshwari."}
  Then the response status should be 403
  And the response should contain "Error: Cannot add comment to a read-only file."

Scenario: Verify Comment Format Preservation
  Given the API base URL 'http://localhost:3000'
  And a file endpoint '/files/123/comments'
  When I send a POST request to '/files/123/comments' with payload {"comment": "This   test\nis created by   Divyesh Maheshwari."}
  Then the response status should be 201
  And the response should contain "This   test\nis created by   Divyesh Maheshwari."

Scenario: Handle Excessive Whitespace and Special Characters
  Given the API base URL 'http://localhost:3000'
  And a file endpoint '/files/123/comments'
  When I send a POST request to '/files/123/comments' with payload {"comment": "This test is created by Divyesh Maheshwari.   !@#$%^&*()"}
  Then the response status should be 201
  And the response should contain "This test is created by Divyesh Maheshwari.   !@#$%^&*()"

Scenario: Verify Multiple Comment Additions
  Given the API base URL 'http://localhost:3000'
  And a file endpoint '/files/123/comments'
  When I send multiple POST requests to '/files/123/comments' with payload {"comment": "This test is created by Divyesh Maheshwari."}
  Then each response status should be 201
  And each response should contain "This test is created by Divyesh Maheshwari."

Scenario: Performance Under Load
  Given the API base URL 'http://localhost:3000'
  And a large file endpoint '/files/789/comments'
  When I send a POST request to '/files/789/comments' with payload {"comment": "This test is created by Divyesh Maheshwari."}
  Then the response status should be 201
  And the response time should be less than 2 seconds

Scenario: Usability of Comment Addition Interface
  Given the API base URL 'http://localhost:3000'
  And a user-friendly interface for '/files/123/comments'
  When a user attempts to add a comment "This test is created by Divyesh Maheshwari."
  Then the process should be intuitive and require minimal instructions

Scenario: Security - Unauthorized Access Prevention
  Given the API base URL 'http://localhost:3000'
  And a file endpoint '/files/123/comments'
  When an unauthorized user sends a POST request to '/files/123/comments' with payload {"comment": "This test is created by Divyesh Maheshwari."}
  Then the response status should be 401
  And the response should contain "Error: Unauthorized access attempt logged."
