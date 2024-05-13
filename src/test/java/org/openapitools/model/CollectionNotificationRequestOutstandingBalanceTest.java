// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=outstandingBalance_3aeba44d36
ROOST_METHOD_SIG_HASH=outstandingBalance_040ce8880b

Here are some JUnit test scenarios for the `outstandingBalance` method:

Scenario 1: Valid Outstanding Balance

Details:
  TestName: validOutstandingBalance()
  Description: This test verifies that the `outstandingBalance` method correctly sets the `outstandingBalance` field when a valid string value is provided.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `outstandingBalance` method with a valid string value.
  Assert: Use JUnit assertions to verify that the `outstandingBalance` field is set to the provided value.
Validation:
  The assertion ensures that the `outstandingBalance` field is correctly set when a valid string value is passed to the method.
  This test is important to validate that the method behaves as expected and properly updates the `outstandingBalance` field.

Scenario 2: Null Outstanding Balance

Details:
  TestName: nullOutstandingBalance()
  Description: This test checks the behavior of the `outstandingBalance` method when a null value is provided as the outstanding balance.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `outstandingBalance` method with a null value.
  Assert: Use JUnit assertions to verify that the `outstandingBalance` field is set to null.
Validation:
  The assertion confirms that the `outstandingBalance` field is set to null when a null value is passed to the method.
  This test is crucial to ensure that the method handles null values correctly and doesn't throw any exceptions.

Scenario 3: Empty Outstanding Balance

Details:
  TestName: emptyOutstandingBalance()
  Description: This test verifies the behavior of the `outstandingBalance` method when an empty string is provided as the outstanding balance.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `outstandingBalance` method with an empty string value.
  Assert: Use JUnit assertions to verify that the `outstandingBalance` field is set to an empty string.
Validation:
  The assertion ensures that the `outstandingBalance` field is set to an empty string when an empty string value is passed to the method.
  This test is important to validate that the method handles empty string values correctly and doesn't throw any exceptions.

Scenario 4: Return Value Check

Details:
  TestName: returnValueCheck()
  Description: This test verifies that the `outstandingBalance` method returns the instance of the `CollectionNotificationRequest` class after setting the `outstandingBalance` field.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `outstandingBalance` method with a valid string value and store the returned value.
  Assert: Use JUnit assertions to verify that the returned value is the same instance of the `CollectionNotificationRequest` class.
Validation:
  The assertion confirms that the `outstandingBalance` method returns the instance of the `CollectionNotificationRequest` class, allowing for method chaining.
  This test is important to ensure that the method follows the fluent interface pattern and enables method chaining for convenience.

These test scenarios cover different aspects of the `outstandingBalance` method, including valid input, null input, empty string input, and the return value. They help ensure the correctness and robustness of the method implementation.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;
import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonTypeName;
import org.openapitools.jackson.nullable.JsonNullable;
import java.time.OffsetDateTime;
import javax.validation.Valid;
import javax.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.*;
import javax.annotation.Generated;

class CollectionNotificationRequestOutstandingBalanceTest {

	@Test
	void validOutstandingBalance() {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		String validBalance = "100.00";
		// Act
		CollectionNotificationRequest result = request.outstandingBalance(validBalance);
		// Assert
		Assertions.assertEquals(validBalance, result.getOutstandingBalance());
		Assertions.assertSame(request, result);
	}

	@ParameterizedTest
	@NullSource
	void nullOutstandingBalance(String nullBalance) {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		// Act
		CollectionNotificationRequest result = request.outstandingBalance(nullBalance);
		// Assert
		Assertions.assertNull(result.getOutstandingBalance());
		Assertions.assertSame(request, result);
	}

	@ParameterizedTest
	@ValueSource(strings = { "", " " })
	void emptyOrBlankOutstandingBalance(String emptyOrBlankBalance) {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		// Act
		CollectionNotificationRequest result = request.outstandingBalance(emptyOrBlankBalance);
		// Assert
		Assertions.assertEquals(emptyOrBlankBalance, result.getOutstandingBalance());
		Assertions.assertSame(request, result);
	}

	@Test
	void returnValueCheck() {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		String validBalance = "100.00";
		// Act
		CollectionNotificationRequest result = request.outstandingBalance(validBalance);
		// Assert
		Assertions.assertSame(request, result);
	}

}