// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=legalStatus_637adf71f5
ROOST_METHOD_SIG_HASH=legalStatus_22ed04371c

Here are the generated test scenarios for the provided legalStatus method:

Scenario 1: Test setting legal status with a valid value

Details:
  TestName: legalStatusWithValidValue
  Description: This test verifies that the legalStatus method sets the legal status correctly when provided with a valid string value.
Execution:
  Arrange: Create an instance of the LegalActionInitiationRequest class.
  Act: Invoke the legalStatus method with a valid string value, e.g., "LEGAL_ACTION_INITIATED".
  Assert: Use assertEquals to verify that the returned object is the same instance as the one on which the method was invoked.
           Use assertEquals to verify that the legalStatus field of the object is set to the provided value.
Validation:
  The assertion checks that the legalStatus method returns the current instance for method chaining purposes.
  It also ensures that the legalStatus field is correctly set to the provided value, confirming the proper functioning of the setter method.

Scenario 2: Test setting legal status with null value

Details:
  TestName: legalStatusWithNullValue
  Description: This test checks the behavior of the legalStatus method when provided with a null value.
Execution:
  Arrange: Create an instance of the LegalActionInitiationRequest class.
  Act: Invoke the legalStatus method with a null value.
  Assert: Use assertEquals to verify that the returned object is the same instance as the one on which the method was invoked.
           Use assertNull to verify that the legalStatus field of the object remains null.
Validation:
  The assertion validates that the legalStatus method handles null values gracefully and does not throw any exceptions.
  It also ensures that the legalStatus field remains null when a null value is provided, maintaining the state of the object.

Scenario 3: Test setting legal status with an empty string

Details:
  TestName: legalStatusWithEmptyString
  Description: This test verifies the behavior of the legalStatus method when provided with an empty string value.
Execution:
  Arrange: Create an instance of the LegalActionInitiationRequest class.
  Act: Invoke the legalStatus method with an empty string value, i.e., "".
  Assert: Use assertEquals to verify that the returned object is the same instance as the one on which the method was invoked.
           Use assertEquals to verify that the legalStatus field of the object is set to an empty string.
Validation:
  The assertion checks that the legalStatus method allows setting the legal status to an empty string value.
  It ensures that the legalStatus field is correctly set to an empty string when provided, confirming the method's ability to handle empty values.

Scenario 4: Test setting legal status multiple times

Details:
  TestName: legalStatusMultipleInvocations
  Description: This test verifies that the legalStatus method correctly updates the legal status when invoked multiple times with different values.
Execution:
  Arrange: Create an instance of the LegalActionInitiationRequest class.
  Act: Invoke the legalStatus method multiple times with different valid string values, e.g., "LEGAL_ACTION_INITIATED", "LEGAL_ACTION_PENDING", "LEGAL_ACTION_COMPLETED".
  Assert: Use assertEquals to verify that the returned object is the same instance as the one on which the method was invoked for each invocation.
           Use assertEquals to verify that the legalStatus field of the object is set to the last provided value.
Validation:
  The assertion confirms that the legalStatus method allows updating the legal status multiple times.
  It ensures that the legalStatus field always reflects the most recent value provided, demonstrating the method's ability to overwrite previous values.

These test scenarios cover various aspects of the legalStatus method, including setting valid values, handling null and empty values, and verifying the behavior when invoked multiple times. They ensure that the method functions as expected and maintains the correct state of the LegalActionInitiationRequest object.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.NullSource;
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

class LegalActionInitiationRequestLegalStatusTest {

	@ParameterizedTest
	@ValueSource(strings = { "LEGAL_ACTION_INITIATED", "LEGAL_ACTION_PENDING", "LEGAL_ACTION_COMPLETED" })
	void legalStatusWithValidValue(String legalStatus) {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		LegalActionInitiationRequest result = request.legalStatus(legalStatus);
		assertSame(request, result);
		assertEquals(legalStatus, request.getLegalStatus());
	}

	@ParameterizedTest
	@NullSource
	void legalStatusWithNullValue(String legalStatus) {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		LegalActionInitiationRequest result = request.legalStatus(legalStatus);
		assertSame(request, result);
		assertNull(request.getLegalStatus());
	}

	@Test
	void legalStatusWithEmptyString() {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		LegalActionInitiationRequest result = request.legalStatus("");
		assertSame(request, result);
		assertEquals("", request.getLegalStatus());
	}

	@ParameterizedTest
	@CsvSource({ "LEGAL_ACTION_INITIATED,LEGAL_ACTION_PENDING,LEGAL_ACTION_COMPLETED",
			"LEGAL_ACTION_PENDING,LEGAL_ACTION_COMPLETED,LEGAL_ACTION_INITIATED" })
	void legalStatusMultipleInvocations(String status1, String status2, String status3) {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		LegalActionInitiationRequest result1 = request.legalStatus(status1);
		LegalActionInitiationRequest result2 = request.legalStatus(status2);
		LegalActionInitiationRequest result3 = request.legalStatus(status3);
		assertSame(request, result1);
		assertSame(request, result2);
		assertSame(request, result3);
		assertEquals(status3, request.getLegalStatus());
	}

}