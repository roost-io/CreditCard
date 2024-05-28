// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=legalStatus_637adf71f5
ROOST_METHOD_SIG_HASH=legalStatus_22ed04371c

Here are the JUnit test scenarios for the provided legalStatus method:

Scenario 1: Test setting legal status with a valid value

Details:
  TestName: legalStatusWithValidValue
  Description: This test checks if the legalStatus method correctly sets the legalStatus field when provided with a valid string value and returns the current instance of LegalActionInitiationRequest.
Execution:
  Arrange: Create an instance of LegalActionInitiationRequest.
  Act: Call the legalStatus method with a valid string value.
  Assert: Assert that the legalStatus field is set to the provided value and the method returns the current instance of LegalActionInitiationRequest.
Validation:
  The assertion verifies that the legalStatus field is properly set and the method maintains the fluent interface by returning the current instance. This test ensures the basic functionality of setting the legal status.

Scenario 2: Test setting legal status with null value

Details:
  TestName: legalStatusWithNullValue
  Description: This test checks if the legalStatus method allows setting the legalStatus field to null and returns the current instance of LegalActionInitiationRequest.
Execution:
  Arrange: Create an instance of LegalActionInitiationRequest.
  Act: Call the legalStatus method with a null value.
  Assert: Assert that the legalStatus field is set to null and the method returns the current instance of LegalActionInitiationRequest.
Validation:
  The assertion verifies that the legalStatus field can be set to null without throwing an exception and the method maintains the fluent interface. This test ensures that null values are handled correctly.

Scenario 3: Test setting legal status with an empty string

Details:
  TestName: legalStatusWithEmptyString
  Description: This test checks if the legalStatus method allows setting the legalStatus field to an empty string and returns the current instance of LegalActionInitiationRequest.
Execution:
  Arrange: Create an instance of LegalActionInitiationRequest.
  Act: Call the legalStatus method with an empty string.
  Assert: Assert that the legalStatus field is set to an empty string and the method returns the current instance of LegalActionInitiationRequest.
Validation:
  The assertion verifies that the legalStatus field can be set to an empty string without throwing an exception and the method maintains the fluent interface. This test ensures that empty strings are handled correctly.

Scenario 4: Test setting legal status after setting other fields

Details:
  TestName: legalStatusAfterSettingOtherFields
  Description: This test checks if the legalStatus method correctly sets the legalStatus field even after other fields (nonPaymentStatus and cardLast4) have been set, and returns the current instance of LegalActionInitiationRequest.
Execution:
  Arrange: Create an instance of LegalActionInitiationRequest and set the nonPaymentStatus and cardLast4 fields.
  Act: Call the legalStatus method with a valid string value.
  Assert: Assert that the legalStatus field is set to the provided value, the previously set fields (nonPaymentStatus and cardLast4) remain unchanged, and the method returns the current instance of LegalActionInitiationRequest.
Validation:
  The assertion verifies that the legalStatus method does not affect other fields and maintains the state of the object. This test ensures that the method operates independently and does not have any side effects on other fields.

Note: The test scenarios assume the existence of appropriate getter methods for the fields (getLegalStatus, getNonPaymentStatus, getCardLast4) to perform the assertions.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

class LegalActionInitiationRequestLegalStatusTest {

	private LegalActionInitiationRequest request;

	@BeforeEach
	void setUp() {
		request = new LegalActionInitiationRequest();
	}

	@ParameterizedTest
	@MethodSource("validLegalStatusProvider")
	void legalStatusWithValidValue(String legalStatus) {
		LegalActionInitiationRequest result = request.legalStatus(legalStatus);
		assertSame(request, result);
		assertEquals(legalStatus, request.getLegalStatus());
	}

	@Test
	void legalStatusWithNullValue() {
		LegalActionInitiationRequest result = request.legalStatus(null);
		assertSame(request, result);
		assertNull(request.getLegalStatus());
	}

	@Test
	void legalStatusWithEmptyString() {
		LegalActionInitiationRequest result = request.legalStatus("");
		assertSame(request, result);
		assertEquals("", request.getLegalStatus());
	}

	@Test
	void legalStatusAfterSettingOtherFields() {
		String nonPaymentStatus = "PENDING";
		String cardLast4 = "1234";
		request.nonPaymentStatus(nonPaymentStatus).cardLast4(cardLast4);
		String legalStatus = "LEGAL_ACTION";
		LegalActionInitiationRequest result = request.legalStatus(legalStatus);
		assertSame(request, result);
		assertEquals(legalStatus, request.getLegalStatus());
		assertEquals(nonPaymentStatus, request.getNonPaymentStatus());
		assertEquals(cardLast4, request.getCardLast4());
	}

	private static Stream<Arguments> validLegalStatusProvider() {
		return Stream.of(Arguments.of("LEGAL_ACTION"), Arguments.of("IN_PROGRESS"), Arguments.of("COMPLETED"));
	}

}