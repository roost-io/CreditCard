Feature: API Testing for Comment Addition Functionality

Scenario: Verify Comment Addition
  Given the API base URL 'http://localhost:3000'
  And the file is empty
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201
  And the response should contain 'Comment added successfully'
  And the file should contain the comment "this test is created by Divyesh Maheshwari"

Scenario: Verify Comment Format
  Given the API base URL 'http://localhost:3000'
  And the file is a Java file
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201
  And the response should contain 'Comment added successfully'
  And the file should contain the comment "// this test is created by Divyesh Maheshwari"

Scenario: Verify Multiple Comment Additions
  Given the API base URL 'http://localhost:3000'
  And the file contains existing comments
  When I send multiple POST requests to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201 for each request
  And the response should contain 'Comment added successfully' for each request
  And the file should contain all comments without overwriting

Scenario: Verify Comment Position
  Given the API base URL 'http://localhost:3000'
  And the file contains existing content
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari", "position": "top"}'
  Then the response status should be 201
  And the response should contain 'Comment added successfully'
  And the comment should be at the top of the file

Scenario: Performance Test for Comment Addition
  Given the API base URL 'http://localhost:3000'
  And the file is extremely large
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201
  And the response time should be less than 2 seconds

Scenario: Usability Test for Comment Addition
  Given the API base URL 'http://localhost:3000'
  When I access the user interface for adding comments
  Then the interface should be intuitive and user-friendly
  And users with minimal technical knowledge should be able to add comments easily

Scenario: Security Test for Comment Addition
  Given the API base URL 'http://localhost:3000'
  When I send a POST request to '/add-comment' with payload '{"comment": "<script>alert('malicious')</script>"}'
  Then the response status should be 400
  And the response should contain 'Malicious content detected'
  And the file should not contain any malicious code

Scenario: Compatibility Test for Comment Addition
  Given the API base URL 'http://localhost:3000'
  And the file format is .txt
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201
  And the response should contain 'Comment added successfully'
  And the comment should be added to the .txt file

  Given the file format is .java
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201
  And the response should contain 'Comment added successfully'
  And the comment should be added to the .java file

  Given the file format is .py
  When I send a POST request to '/add-comment' with payload '{"comment": "this test is created by Divyesh Maheshwari"}'
  Then the response status should be 201
  And the response should contain 'Comment added successfully'
  And the comment should be added to the .py file
