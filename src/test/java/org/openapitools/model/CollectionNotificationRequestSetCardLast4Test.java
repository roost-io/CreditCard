// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=setCardLast4_1ec3bfb1aa
ROOST_METHOD_SIG_HASH=setCardLast4_67db513785

Here are the generated test scenarios for the setCardLast4 method:

Scenario 1: Valid cardLast4 value

Details:
  TestName: setCardLast4WithValidValue
  Description: This test verifies that the setCardLast4 method correctly sets the cardLast4 field when provided with a valid value.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a valid cardLast4 value, such as "1234".
  Assert: Use assertEquals to verify that the cardLast4 field of the instance is equal to the provided value.
Validation:
  The assertion ensures that the setCardLast4 method correctly assigns the provided value to the cardLast4 field.
  This test is important to validate that the setter method functions as expected for valid input.

Scenario 2: Null cardLast4 value

Details:
  TestName: setCardLast4WithNullValue
  Description: This test checks the behavior of the setCardLast4 method when provided with a null value.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a null value.
  Assert: Use assertNull to verify that the cardLast4 field of the instance remains null after the method invocation.
Validation:
  The assertion confirms that the setCardLast4 method does not throw an exception or modify the cardLast4 field when given a null value.
  This test ensures that the method handles null input gracefully and does not introduce unexpected behavior.

Scenario 3: Empty cardLast4 value

Details:
  TestName: setCardLast4WithEmptyValue
  Description: This test verifies the behavior of the setCardLast4 method when provided with an empty string value.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with an empty string value, such as "".
  Assert: Use assertEquals to verify that the cardLast4 field of the instance is set to the empty string value.
Validation:
  The assertion ensures that the setCardLast4 method allows setting the cardLast4 field to an empty string value.
  This test validates that the method does not impose any restrictions on the length of the cardLast4 value.

Scenario 4: cardLast4 value with whitespace

Details:
  TestName: setCardLast4WithWhitespaceValue
  Description: This test checks the behavior of the setCardLast4 method when provided with a value containing whitespace characters.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a value containing whitespace characters, such as " 1234 ".
  Assert: Use assertEquals to verify that the cardLast4 field of the instance is set to the provided value, including the whitespace characters.
Validation:
  The assertion confirms that the setCardLast4 method preserves any whitespace characters in the provided value.
  This test ensures that the method does not perform any trimming or modification of the input value.

Note: The test scenarios assume that the class containing the setCardLast4 method has a default constructor or an appropriate constructor to create instances for testing. If additional setup or teardown is required, it should be included in the test class.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.EmptySource;
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

class CollectionNotificationRequestSetCardLast4Test {

	@Test
	void setCardLast4WithValidValue() {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		String validCardLast4 = "1234";
		// Act
		request.setCardLast4(validCardLast4);
		// Assert
		assertEquals(validCardLast4, request.getCardLast4());
	}

	@ParameterizedTest
	@NullSource
	void setCardLast4WithNullValue(String nullCardLast4) {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		// Act
		request.setCardLast4(nullCardLast4);
		// Assert
		assertNull(request.getCardLast4());
	}

	@ParameterizedTest
	@EmptySource
	void setCardLast4WithEmptyValue(String emptyCardLast4) {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		// Act
		request.setCardLast4(emptyCardLast4);
		// Assert
		assertEquals(emptyCardLast4, request.getCardLast4());
	}

	@ParameterizedTest
	@ValueSource(strings = { " 1234 ", "  5678  " })
	void setCardLast4WithWhitespaceValue(String whitespaceCardLast4) {
		// Arrange
		CollectionNotificationRequest request = new CollectionNotificationRequest();
		// Act
		request.setCardLast4(whitespaceCardLast4);
		// Assert
		assertEquals(whitespaceCardLast4, request.getCardLast4());
	}

}