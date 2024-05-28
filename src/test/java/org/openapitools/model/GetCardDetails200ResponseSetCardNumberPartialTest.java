// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=setCardNumberPartial_fb62bdef0c
ROOST_METHOD_SIG_HASH=setCardNumberPartial_d7e6156ba5

Here are some JUnit test scenarios for the setCardNumberPartial method:

Scenario 1: Setting a Valid Card Number Partial

Details:
  TestName: setValidCardNumberPartial
  Description: This test checks if the setCardNumberPartial method correctly sets a valid card number partial string to the cardNumberPartial field.
Execution:
  Arrange: Create an instance of the class containing the setCardNumberPartial method.
  Act: Call setCardNumberPartial with a valid card number partial string.
  Assert: Use assertEquals to verify that the cardNumberPartial field is set to the provided value.
Validation:
  The assertion verifies that the setter method properly assigns the provided value to the private field.
  This test ensures the basic functionality of updating the card number partial value.

Scenario 2: Setting a Null Card Number Partial

Details:
  TestName: setNullCardNumberPartial
  Description: This test validates the behavior when setting the card number partial to null.
Execution:
  Arrange: Create an instance of the class containing the setCardNumberPartial method.
  Act: Call setCardNumberPartial with a null value.
  Assert: Use assertNull to check if the cardNumberPartial field is set to null.
Validation:
  The assertion confirms that the setter allows setting the card number partial to null.
  This test handles the case where no card number partial is provided.

Scenario 3: Setting an Empty Card Number Partial

Details:
  TestName: setEmptyCardNumberPartial
  Description: This test verifies the behavior when setting an empty string as the card number partial.
Execution:
  Arrange: Create an instance of the class containing the setCardNumberPartial method.
  Act: Call setCardNumberPartial with an empty string.
  Assert: Use assertEquals to check if the cardNumberPartial field is set to an empty string.
Validation:
  The assertion ensures that the setter allows setting the card number partial to an empty string.
  This test covers the scenario where an empty card number partial is provided.

Scenario 4: Setting a Card Number Partial with Special Characters

Details:
  TestName: setCardNumberPartialWithSpecialChars
  Description: This test checks if the setCardNumberPartial method handles card number partials containing special characters.
Execution:
  Arrange: Create an instance of the class containing the setCardNumberPartial method.
  Act: Call setCardNumberPartial with a string containing special characters.
  Assert: Use assertEquals to verify that the cardNumberPartial field is set to the provided value.
Validation:
  The assertion confirms that the setter allows card number partials with special characters.
  This test ensures the method can handle non-alphanumeric characters in the card number partial.

Scenario 5: Setting a Long Card Number Partial

Details:
  TestName: setLongCardNumberPartial
  Description: This test verifies the behavior when setting a very long card number partial string.
Execution:
  Arrange: Create an instance of the class containing the setCardNumberPartial method.
  Act: Call setCardNumberPartial with a long string exceeding the expected length.
  Assert: Use assertEquals to check if the cardNumberPartial field is set to the provided long value.
Validation:
  The assertion ensures that the setter can handle long card number partial strings.
  This test covers the scenario where an unusually long card number partial is provided.

These test scenarios cover different aspects of the setCardNumberPartial method, including valid inputs, null and empty values, special characters, and long input strings. They help ensure the robustness and expected behavior of the setter method.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

class GetCardDetails200ResponseSetCardNumberPartialTest {

	@ParameterizedTest
	@MethodSource("validCardNumberPartialProvider")
	void setValidCardNumberPartial(String cardNumberPartial) {
		GetCardDetails200Response response = new GetCardDetails200Response();
		response.setCardNumberPartial(cardNumberPartial);
		assertEquals(cardNumberPartial, response.getCardNumberPartial());
	}

	@Test
	void setNullCardNumberPartial() {
		GetCardDetails200Response response = new GetCardDetails200Response();
		response.setCardNumberPartial(null);
		assertNull(response.getCardNumberPartial());
	}

	@Test
	void setEmptyCardNumberPartial() {
		GetCardDetails200Response response = new GetCardDetails200Response();
		response.setCardNumberPartial("");
		assertEquals("", response.getCardNumberPartial());
	}

	@ParameterizedTest
	@MethodSource("specialCharsCardNumberPartialProvider")
	void setCardNumberPartialWithSpecialChars(String cardNumberPartial) {
		GetCardDetails200Response response = new GetCardDetails200Response();
		response.setCardNumberPartial(cardNumberPartial);
		assertEquals(cardNumberPartial, response.getCardNumberPartial());
	}

	@ParameterizedTest
	@MethodSource("longCardNumberPartialProvider")
	void setLongCardNumberPartial(String cardNumberPartial) {
		GetCardDetails200Response response = new GetCardDetails200Response();
		response.setCardNumberPartial(cardNumberPartial);
		assertEquals(cardNumberPartial, response.getCardNumberPartial());
	}

	private static Stream<Arguments> validCardNumberPartialProvider() {
		return Stream.of(Arguments.of("1234"), Arguments.of("5678"), Arguments.of("9012"));
	}

	private static Stream<Arguments> specialCharsCardNumberPartialProvider() {
		return Stream.of(Arguments.of("1234-5678"), Arguments.of("9012_3456"), Arguments.of("7890.1234"));
	}

	private static Stream<Arguments> longCardNumberPartialProvider() {
		return Stream.of(Arguments.of("1234567890123456"), Arguments.of("9876543210987654"),
				Arguments.of("1111222233334444"));
	}

}