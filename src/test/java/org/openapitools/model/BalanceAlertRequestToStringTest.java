// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=toString_4f6c6df0bb
ROOST_METHOD_SIG_HASH=toString_ceffa8036e

Here are some JUnit test scenarios for the given toString() method:

Scenario 1: Test toString() with valid data

Details:
  TestName: toStringWithValidData()
  Description: This test checks if the toString() method returns the expected string representation when provided with valid data for paymentDueDate, currentDate, and cardLast4 fields.
Execution:
  Arrange: Create a BalanceAlertRequest object and set valid values for paymentDueDate, currentDate, and cardLast4 fields.
  Act: Call the toString() method on the BalanceAlertRequest object.
  Assert: Use assertEquals to verify that the returned string matches the expected format and contains the correct field values.
Validation:
  The assertion verifies that the toString() method correctly generates the string representation of the BalanceAlertRequest object, including indentation and field values. This test ensures that the method adheres to the expected format and displays the object's state accurately.

Scenario 2: Test toString() with null values

Details:
  TestName: toStringWithNullValues()
  Description: This test checks if the toString() method handles null values correctly for paymentDueDate, currentDate, and cardLast4 fields.
Execution:
  Arrange: Create a BalanceAlertRequest object and set null values for paymentDueDate, currentDate, and cardLast4 fields.
  Act: Call the toString() method on the BalanceAlertRequest object.
  Assert: Use assertEquals to verify that the returned string matches the expected format and displays "null" for the fields with null values.
Validation:
  The assertion verifies that the toString() method handles null values gracefully and includes them in the string representation without throwing any exceptions. This test ensures that the method can handle missing or undefined field values.

Scenario 3: Test toString() with empty values

Details:
  TestName: toStringWithEmptyValues()
  Description: This test checks if the toString() method handles empty values correctly for paymentDueDate, currentDate, and cardLast4 fields.
Execution:
  Arrange: Create a BalanceAlertRequest object and set empty values (e.g., empty strings or default values) for paymentDueDate, currentDate, and cardLast4 fields.
  Act: Call the toString() method on the BalanceAlertRequest object.
  Assert: Use assertEquals to verify that the returned string matches the expected format and displays the empty values for the respective fields.
Validation:
  The assertion verifies that the toString() method handles empty values correctly and includes them in the string representation without any formatting issues. This test ensures that the method can handle fields with empty or default values.

Scenario 4: Test toString() with special characters

Details:
  TestName: toStringWithSpecialCharacters()
  Description: This test checks if the toString() method handles special characters correctly in the paymentDueDate, currentDate, and cardLast4 fields.
Execution:
  Arrange: Create a BalanceAlertRequest object and set values containing special characters (e.g., symbols, non-ASCII characters) for paymentDueDate, currentDate, and cardLast4 fields.
  Act: Call the toString() method on the BalanceAlertRequest object.
  Assert: Use assertEquals to verify that the returned string matches the expected format and displays the special characters correctly in the respective fields.
Validation:
  The assertion verifies that the toString() method handles special characters properly and includes them in the string representation without any encoding or formatting issues. This test ensures that the method can handle fields with special characters and displays them accurately.

These test scenarios cover different aspects of the toString() method, including handling valid data, null values, empty values, and special characters. They ensure that the method generates the expected string representation of the BalanceAlertRequest object in various scenarios.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
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

class BalanceAlertRequestToStringTest {

	private BalanceAlertRequest balanceAlertRequest;

	@BeforeEach
	void setUp() {
		balanceAlertRequest = new BalanceAlertRequest();
	}

	@Test
	@DisplayName("Test toString() with valid data")
	void toStringWithValidData() {
		// Arrange
		LocalDate paymentDueDate = LocalDate.of(2023, 6, 15);
		LocalDate currentDate = LocalDate.of(2023, 6, 10);
		String cardLast4 = "1234";
		balanceAlertRequest.setPaymentDueDate(paymentDueDate);
		balanceAlertRequest.setCurrentDate(currentDate);
		balanceAlertRequest.setCardLast4(cardLast4);
		// Act
		String result = balanceAlertRequest.toString();
		// Assert
		String expected = "class BalanceAlertRequest {\n" + "    paymentDueDate: 2023-06-15\n"
				+ "    currentDate: 2023-06-10\n" + "    cardLast4: 1234\n" + "}";
		assertEquals(expected, result);
	}

	@Test
	@DisplayName("Test toString() with null values")
	void toStringWithNullValues() {
		// Arrange
		balanceAlertRequest.setPaymentDueDate(null);
		balanceAlertRequest.setCurrentDate(null);
		balanceAlertRequest.setCardLast4(null);
		// Act
		String result = balanceAlertRequest.toString();
		// Assert
		String expected = "class BalanceAlertRequest {\n" + "    paymentDueDate: null\n" + "    currentDate: null\n"
				+ "    cardLast4: null\n" + "}";
		assertEquals(expected, result);
	}

	@Test
	@DisplayName("Test toString() with empty values")
	void toStringWithEmptyValues() {
		// Arrange
		balanceAlertRequest.setPaymentDueDate(LocalDate.MIN);
		balanceAlertRequest.setCurrentDate(LocalDate.MIN);
		balanceAlertRequest.setCardLast4("");
		// Act
		String result = balanceAlertRequest.toString();
		// Assert
		String expected = "class BalanceAlertRequest {\n" + "    paymentDueDate: -999999999-01-01\n"
				+ "    currentDate: -999999999-01-01\n" + "    cardLast4: \n" + "}";
		assertEquals(expected, result);
	}

	@ParameterizedTest
	@CsvSource({ "'2023-06-15', '2023-06-10', 'Sp3c!@l'", "'2023-06-15', '2023-06-10', '!@#$%^&*()_+'",
			"'2023-06-15', '2023-06-10', 'áéíóúñ'" })
	@DisplayName("Test toString() with special characters")
	void toStringWithSpecialCharacters(String paymentDueDateStr, String currentDateStr, String cardLast4) {
		// Arrange
		LocalDate paymentDueDate = LocalDate.parse(paymentDueDateStr);
		LocalDate currentDate = LocalDate.parse(currentDateStr);
		balanceAlertRequest.setPaymentDueDate(paymentDueDate);
		balanceAlertRequest.setCurrentDate(currentDate);
		balanceAlertRequest.setCardLast4(cardLast4);
		// Act
		String result = balanceAlertRequest.toString();
		// Assert
		String expected = "class BalanceAlertRequest {\n" + "    paymentDueDate: " + paymentDueDate + "\n"
				+ "    currentDate: " + currentDate + "\n" + "    cardLast4: " + cardLast4 + "\n" + "}";
		assertEquals(expected, result);
	}

}