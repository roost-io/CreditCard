// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=getPaymentDueDate_915156d673
ROOST_METHOD_SIG_HASH=getPaymentDueDate_01dab947d7

Here are the JUnit test scenarios for the provided `getPaymentDueDate` method:

Scenario 1: Test retrieving payment due date when it is set

Details:
  TestName: retrievesPaymentDueDateWhenSet
  Description: This test verifies that the `getPaymentDueDate` method correctly retrieves the payment due date when it has been previously set.
Execution:
  Arrange: Create an instance of the class containing the `getPaymentDueDate` method and set a specific payment due date.
  Act: Invoke the `getPaymentDueDate` method.
  Assert: Use `assertEquals` to compare the retrieved payment due date with the expected date.
Validation:
  The assertion verifies that the `getPaymentDueDate` method returns the same date that was set earlier.
  This test ensures that the getter method correctly retrieves the stored payment due date value.

Scenario 2: Test retrieving payment due date when it is not set

Details:
  TestName: returnsNullWhenPaymentDueDateNotSet
  Description: This test checks that the `getPaymentDueDate` method returns null when the payment due date has not been set.
Execution:
  Arrange: Create an instance of the class containing the `getPaymentDueDate` method without setting a payment due date.
  Act: Invoke the `getPaymentDueDate` method.
  Assert: Use `assertNull` to verify that the returned payment due date is null.
Validation:
  The assertion confirms that the `getPaymentDueDate` method returns null when no payment due date has been set.
  This test ensures that the getter method handles the case when the payment due date is not initialized and returns null instead of throwing an exception or returning an invalid date.

Scenario 3: Test retrieving payment due date with different date values

Details:
  TestName: retrievesCorrectPaymentDueDateWithDifferentValues
  Description: This test verifies that the `getPaymentDueDate` method correctly retrieves the payment due date for different date values.
Execution:
  Arrange: Create multiple instances of the class containing the `getPaymentDueDate` method and set different payment due dates for each instance.
  Act: Invoke the `getPaymentDueDate` method on each instance.
  Assert: Use `assertEquals` to compare the retrieved payment due dates with the expected dates for each instance.
Validation:
  The assertions verify that the `getPaymentDueDate` method returns the correct payment due date for each instance, regardless of the date value.
  This test ensures that the getter method consistently retrieves the stored payment due date value across different instances and date values.

Note: Since the provided method is a simple getter without any complex logic or error handling, the test scenarios focus on verifying the basic functionality of retrieving the payment due date under different conditions.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonTypeName;
import org.springframework.format.annotation.DateTimeFormat;
import org.openapitools.jackson.nullable.JsonNullable;
import java.time.OffsetDateTime;
import javax.validation.Valid;
import javax.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.*;
import javax.annotation.Generated;

class BalanceAlertRequestGetPaymentDueDateTest {

	private BalanceAlertRequest balanceAlertRequest;

	@BeforeEach
	void setUp() {
		balanceAlertRequest = new BalanceAlertRequest();
	}

	@Test
	void retrievesPaymentDueDateWhenSet() {
		// Arrange
		LocalDate expectedDate = LocalDate.now();
		balanceAlertRequest.setPaymentDueDate(expectedDate);
		// Act
		LocalDate actualDate = balanceAlertRequest.getPaymentDueDate();
		// Assert
		assertEquals(expectedDate, actualDate);
	}

	@Test
	void returnsNullWhenPaymentDueDateNotSet() {
		// Act
		LocalDate actualDate = balanceAlertRequest.getPaymentDueDate();
		// Assert
		assertNull(actualDate);
	}

	@ParameterizedTest
	@ValueSource(strings = { "2023-06-01", "2023-12-31", "2024-01-01" })
	void retrievesCorrectPaymentDueDateWithDifferentValues(String dateString) {
		// Arrange
		LocalDate expectedDate = LocalDate.parse(dateString);
		balanceAlertRequest.setPaymentDueDate(expectedDate);
		// Act
		LocalDate actualDate = balanceAlertRequest.getPaymentDueDate();
		// Assert
		assertEquals(expectedDate, actualDate);
	}

}