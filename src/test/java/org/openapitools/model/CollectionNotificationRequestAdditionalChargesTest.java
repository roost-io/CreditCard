// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=additionalCharges_6fb76b3996
ROOST_METHOD_SIG_HASH=additionalCharges_a47610217a

Here are the JUnit test scenarios for the `additionalCharges` method:

Scenario 1: Set Additional Charges

Details:
  TestName: setAdditionalCharges_validValue_updatesAdditionalCharges
  Description: This test verifies that the `additionalCharges` method correctly sets the `additionalCharges` field when a valid value is provided.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `additionalCharges` method with a valid string value.
  Assert: Assert that the `additionalCharges` field of the `CollectionNotificationRequest` instance is equal to the provided value.
Validation:
  The assertion ensures that the `additionalCharges` field is properly updated with the provided value.
  This test is important to validate that the setter method behaves as expected and allows setting the additional charges for the collection notification request.

Scenario 2: Set Additional Charges to Null

Details:
  TestName: setAdditionalCharges_null_updatesAdditionalChargesToNull
  Description: This test checks that the `additionalCharges` method allows setting the `additionalCharges` field to null.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `additionalCharges` method with a null value.
  Assert: Assert that the `additionalCharges` field of the `CollectionNotificationRequest` instance is null.
Validation:
  The assertion verifies that the `additionalCharges` field can be set to null using the setter method.
  This test is crucial to ensure that the method handles null values correctly and allows resetting the additional charges if needed.

Scenario 3: Set Additional Charges and Check Fluent Interface

Details:
  TestName: setAdditionalCharges_validValue_returnsSameInstance
  Description: This test verifies that the `additionalCharges` method returns the same instance of `CollectionNotificationRequest` after setting the `additionalCharges` field, following the fluent interface pattern.
Execution:
  Arrange: Create an instance of the `CollectionNotificationRequest` class.
  Act: Invoke the `additionalCharges` method with a valid string value and store the returned instance.
  Assert: Assert that the returned instance is the same as the original `CollectionNotificationRequest` instance.
Validation:
  The assertion confirms that the `additionalCharges` method follows the fluent interface pattern by returning the same instance of `CollectionNotificationRequest`.
  This test is important to ensure that the method allows chaining of method calls and supports a fluent API style.

These test scenarios cover the basic functionality of the `additionalCharges` method, including setting a valid value, setting null, and verifying the fluent interface. They ensure that the method behaves as expected and handles different scenarios correctly.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
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

class CollectionNotificationRequestAdditionalChargesTest {

	private CollectionNotificationRequest collectionNotificationRequest;

	@BeforeEach
	void setUp() {
		collectionNotificationRequest = new CollectionNotificationRequest();
	}

	@Test
	void setAdditionalCharges_validValue_updatesAdditionalCharges() {
		// Arrange
		String additionalCharges = "10.00";
		// Act
		collectionNotificationRequest.additionalCharges(additionalCharges);
		// Assert
		assertEquals(additionalCharges, collectionNotificationRequest.getAdditionalCharges());
	}

	@Test
	void setAdditionalCharges_null_updatesAdditionalChargesToNull() {
		// Arrange
		String additionalCharges = null;
		// Act
		collectionNotificationRequest.additionalCharges(additionalCharges);
		// Assert
		assertNull(collectionNotificationRequest.getAdditionalCharges());
	}

	@Test
	void setAdditionalCharges_validValue_returnsSameInstance() {
		// Arrange
		String additionalCharges = "10.00";
		// Act
		CollectionNotificationRequest result = collectionNotificationRequest.additionalCharges(additionalCharges);
		// Assert
		assertSame(collectionNotificationRequest, result);
	}

}