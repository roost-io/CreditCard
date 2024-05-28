// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=setCardLast4_1ec3bfb1aa
ROOST_METHOD_SIG_HASH=setCardLast4_67db513785

Here are the JUnit test scenarios for the setCardLast4 method:

Scenario 1: Set Valid Card Last 4 Digits

Details:
  TestName: setValidCardLast4.
  Description: This test verifies that the setCardLast4 method correctly sets the cardLast4 field when a valid value is provided.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a valid 4-digit string value.
  Assert: Use assertEquals to verify that the cardLast4 field is set to the provided value.
Validation:
  The assertion ensures that the setCardLast4 method correctly updates the cardLast4 field with the provided value.
  This test is important to validate that the method behaves as expected when given valid input.

Scenario 2: Set Empty Card Last 4 Digits

Details:
  TestName: setEmptyCardLast4.
  Description: This test checks the behavior of the setCardLast4 method when an empty string is provided as input.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with an empty string value.
  Assert: Use assertEquals to verify that the cardLast4 field is set to an empty string.
Validation:
  The assertion confirms that the setCardLast4 method allows setting the cardLast4 field to an empty string.
  This test ensures that the method handles empty input gracefully without throwing any exceptions.

Scenario 3: Set Null Card Last 4 Digits

Details:
  TestName: setNullCardLast4.
  Description: This test verifies the behavior of the setCardLast4 method when a null value is provided as input.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a null value.
  Assert: Use assertNull to verify that the cardLast4 field is set to null.
Validation:
  The assertion ensures that the setCardLast4 method allows setting the cardLast4 field to null.
  This test validates that the method handles null input without throwing any exceptions, allowing the field to be reset.

Scenario 4: Set Card Last 4 Digits with Less Than 4 Characters

Details:
  TestName: setCardLast4WithLessThan4Chars.
  Description: This test checks the behavior of the setCardLast4 method when a string with less than 4 characters is provided as input.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a string value containing less than 4 characters.
  Assert: Use assertEquals to verify that the cardLast4 field is set to the provided value.
Validation:
  The assertion confirms that the setCardLast4 method allows setting the cardLast4 field with a string containing less than 4 characters.
  This test ensures that the method does not enforce any length validation on the input, accepting strings of any length.

Scenario 5: Set Card Last 4 Digits with More Than 4 Characters

Details:
  TestName: setCardLast4WithMoreThan4Chars.
  Description: This test verifies the behavior of the setCardLast4 method when a string with more than 4 characters is provided as input.
Execution:
  Arrange: Create an instance of the class containing the setCardLast4 method.
  Act: Invoke the setCardLast4 method with a string value containing more than 4 characters.
  Assert: Use assertEquals to verify that the cardLast4 field is set to the provided value.
Validation:
  The assertion ensures that the setCardLast4 method allows setting the cardLast4 field with a string containing more than 4 characters.
  This test validates that the method does not truncate or limit the input length, accepting strings of any length.

Note: The test scenarios assume that the class containing the setCardLast4 method has a getter method to retrieve the value of the cardLast4 field for assertion purposes.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class LegalActionInitiationRequestSetCardLast4Test {

	@Test
	void setValidCardLast4() {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		String validCardLast4 = "1234";
		request.setCardLast4(validCardLast4);
		assertEquals(validCardLast4, request.getCardLast4());
	}

	@Test
	void setEmptyCardLast4() {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		String emptyCardLast4 = "";
		request.setCardLast4(emptyCardLast4);
		assertEquals(emptyCardLast4, request.getCardLast4());
	}

	@Test
	void setNullCardLast4() {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		request.setCardLast4(null);
		assertNull(request.getCardLast4());
	}

	@Test
	void setCardLast4WithLessThan4Chars() {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		String lessThan4Chars = "123";
		request.setCardLast4(lessThan4Chars);
		assertEquals(lessThan4Chars, request.getCardLast4());
		// Consider adding validation in the setter method to enforce a 4-character limit
	}

	@Test
	void setCardLast4WithMoreThan4Chars() {
		LegalActionInitiationRequest request = new LegalActionInitiationRequest();
		String moreThan4Chars = "12345";
		request.setCardLast4(moreThan4Chars);
		assertEquals(moreThan4Chars, request.getCardLast4());
		// Consider adding validation in the setter method to enforce a 4-character limit
	}

}