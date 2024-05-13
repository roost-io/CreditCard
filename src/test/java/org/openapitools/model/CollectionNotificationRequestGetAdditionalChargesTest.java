// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=getAdditionalCharges_47cd6feb53
ROOST_METHOD_SIG_HASH=getAdditionalCharges_cb4be130e2

Based on the provided method `getAdditionalCharges()` and the list of imports, here are the generated test scenarios:

Scenario 1: Retrieve Additional Charges

Details:
  TestName: retrieveAdditionalCharges()
  Description: This test verifies that the `getAdditionalCharges()` method correctly retrieves the value of the `additionalCharges` field.
Execution:
  Arrange: Create an instance of the class containing the `getAdditionalCharges()` method and set the `additionalCharges` field to a known value.
  Act: Invoke the `getAdditionalCharges()` method on the instance.
  Assert: Use JUnit's `assertEquals()` to compare the returned value with the expected value.
Validation:
  The assertion verifies that the `getAdditionalCharges()` method returns the correct value of the `additionalCharges` field.
  This test ensures that the getter method is functioning as expected and retrieving the correct value.

Scenario 2: Handle Null Additional Charges

Details:
  TestName: handleNullAdditionalCharges()
  Description: This test checks the behavior of the `getAdditionalCharges()` method when the `additionalCharges` field is null.
Execution:
  Arrange: Create an instance of the class containing the `getAdditionalCharges()` method and set the `additionalCharges` field to null.
  Act: Invoke the `getAdditionalCharges()` method on the instance.
  Assert: Use JUnit's `assertNull()` to verify that the returned value is null.
Validation:
  The assertion verifies that the `getAdditionalCharges()` method returns null when the `additionalCharges` field is null.
  This test ensures that the getter method handles null values correctly and doesn't throw any exceptions.

Scenario 3: Empty Additional Charges

Details:
  TestName: emptyAdditionalCharges()
  Description: This test verifies the behavior of the `getAdditionalCharges()` method when the `additionalCharges` field is an empty string.
Execution:
  Arrange: Create an instance of the class containing the `getAdditionalCharges()` method and set the `additionalCharges` field to an empty string.
  Act: Invoke the `getAdditionalCharges()` method on the instance.
  Assert: Use JUnit's `assertEquals()` to compare the returned value with an empty string.
Validation:
  The assertion verifies that the `getAdditionalCharges()` method returns an empty string when the `additionalCharges` field is set to an empty string.
  This test ensures that the getter method handles empty strings correctly and returns the expected value.

Note: Since the `getAdditionalCharges()` method is a simple getter method without any complex logic or dependencies, the test scenarios are focused on verifying the basic functionality and handling of different input values (normal value, null, and empty string).
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import static org.junit.jupiter.api.Assertions.*;
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

class CollectionNotificationRequestGetAdditionalChargesTest {

	private CollectionNotificationRequest request;

	@BeforeEach
	void setUp() {
		request = new CollectionNotificationRequest();
	}

	@Test
	void retrieveAdditionalCharges() {
		// Arrange
		String expectedCharges = "10.50";
		request.setAdditionalCharges(expectedCharges);
		// Act
		String actualCharges = request.getAdditionalCharges();
		// Assert
		assertEquals(expectedCharges, actualCharges);
	}

	@Test
	void handleNullAdditionalCharges() {
		// Arrange
		request.setAdditionalCharges(null);
		// Act
		String actualCharges = request.getAdditionalCharges();
		// Assert
		assertNull(actualCharges);
	}

	@ParameterizedTest
	@ValueSource(strings = { "", "   " })
	void emptyAdditionalCharges(String emptyCharges) {
		// Arrange
		request.setAdditionalCharges(emptyCharges);
		// Act
		String actualCharges = request.getAdditionalCharges();
		// Assert
		assertEquals(emptyCharges, actualCharges);
	}

}