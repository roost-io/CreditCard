// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=paymentDueDate_ede8a708e5
ROOST_METHOD_SIG_HASH=paymentDueDate_2c21b6ecde

Here are the JUnit test scenarios for the provided `paymentDueDate` method:

Scenario 1: Valid Payment Due Date

Details:
  TestName: validPaymentDueDate
  Description: This test verifies that the `paymentDueDate` method correctly sets the `paymentDueDate` field when a valid `LocalDate` is provided.
Execution:
  Arrange: Create an instance of the `BalanceAlertRequest` class.
  Act: Invoke the `paymentDueDate` method with a valid `LocalDate` object.
  Assert: Use JUnit assertions to verify that the `paymentDueDate` field is set to the provided `LocalDate` value.
Validation:
  The assertion ensures that the `paymentDueDate` field is properly updated when a valid `LocalDate` is passed to the method.
  This test is important to ensure that the payment due date is correctly stored in the `BalanceAlertRequest` object for further processing.

Scenario 2: Null Payment Due Date

Details:
  TestName: nullPaymentDueDate
  Description: This test verifies that the `paymentDueDate` method handles a null `LocalDate` input gracefully and does not throw any exceptions.
Execution:
  Arrange: Create an instance of the `BalanceAlertRequest` class.
  Act: Invoke the `paymentDueDate` method with a null `LocalDate` value.
  Assert: Use JUnit assertions to verify that no exceptions are thrown and the `paymentDueDate` field remains null.
Validation:
  The assertion ensures that the method does not throw any exceptions when a null `LocalDate` is provided.
  This test is important to ensure that the method can handle null input without causing any unexpected behavior or crashes in the application.

Scenario 3: Payment Due Date Before Current Date

Details:
  TestName: paymentDueDateBeforeCurrentDate
  Description: This test verifies that the `paymentDueDate` method allows setting a payment due date that is before the current date.
Execution:
  Arrange: Create an instance of the `BalanceAlertRequest` class and set the `currentDate` field to a specific `LocalDate` value.
  Act: Invoke the `paymentDueDate` method with a `LocalDate` that is before the `currentDate`.
  Assert: Use JUnit assertions to verify that the `paymentDueDate` field is set to the provided `LocalDate` value.
Validation:
  The assertion ensures that the method allows setting a payment due date that is before the current date.
  This test is important to ensure that the method does not impose any restrictions on the payment due date being set, allowing flexibility in the application's business logic.

Scenario 4: Payment Due Date After Current Date

Details:
  TestName: paymentDueDateAfterCurrentDate
  Description: This test verifies that the `paymentDueDate` method allows setting a payment due date that is after the current date.
Execution:
  Arrange: Create an instance of the `BalanceAlertRequest` class and set the `currentDate` field to a specific `LocalDate` value.
  Act: Invoke the `paymentDueDate` method with a `LocalDate` that is after the `currentDate`.
  Assert: Use JUnit assertions to verify that the `paymentDueDate` field is set to the provided `LocalDate` value.
Validation:
  The assertion ensures that the method allows setting a payment due date that is after the current date.
  This test is important to ensure that the method allows setting future payment due dates, which is a common scenario in real-world applications.

These test scenarios cover different aspects of the `paymentDueDate` method, including valid input, null input, and edge cases related to the current date. They ensure that the method behaves as expected and handles different scenarios gracefully.
*/

// ********RoostGPT********
package org.openapitools.model;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
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

class BalanceAlertRequestPaymentDueDateTest {

	private BalanceAlertRequest balanceAlertRequest;

	@BeforeEach
	void setUp() {
		balanceAlertRequest = new BalanceAlertRequest();
	}

	@Test
	void validPaymentDueDate() {
		LocalDate paymentDueDate = LocalDate.of(2023, 6, 15);
		balanceAlertRequest.paymentDueDate(paymentDueDate);
		assertEquals(paymentDueDate, balanceAlertRequest.getPaymentDueDate());
	}

	@Test
	void nullPaymentDueDate() {
		balanceAlertRequest.paymentDueDate(null);
		assertNull(balanceAlertRequest.getPaymentDueDate());
	}

	@Test
	void paymentDueDateBeforeCurrentDate() {
		LocalDate currentDate = LocalDate.of(2023, 6, 10);
		LocalDate paymentDueDate = LocalDate.of(2023, 6, 5);
		balanceAlertRequest.setCurrentDate(currentDate);
		balanceAlertRequest.paymentDueDate(paymentDueDate);
		assertEquals(paymentDueDate, balanceAlertRequest.getPaymentDueDate());
	}

	@Test
	void paymentDueDateAfterCurrentDate() {
		LocalDate currentDate = LocalDate.of(2023, 6, 10);
		LocalDate paymentDueDate = LocalDate.of(2023, 6, 15);
		balanceAlertRequest.setCurrentDate(currentDate);
		balanceAlertRequest.paymentDueDate(paymentDueDate);
		assertEquals(paymentDueDate, balanceAlertRequest.getPaymentDueDate());
	}

}