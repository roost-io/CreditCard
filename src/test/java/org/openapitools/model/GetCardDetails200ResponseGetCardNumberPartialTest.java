// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=getCardNumberPartial_27efd95369
ROOST_METHOD_SIG_HASH=getCardNumberPartial_572693db41

Here are the JUnit test scenarios for the provided getCardNumberPartial() method:

Scenario 1: Retrieve Partial Card Number

Details:
  TestName: getCardNumberPartialReturnsValue()
  Description: This test verifies that the getCardNumberPartial() method returns the correct value of the cardNumberPartial field.
Execution:
  Arrange: Create an instance of the class containing the getCardNumberPartial() method.
  Act: Call the getCardNumberPartial() method on the instance.
  Assert: Use assertEquals to compare the returned value with the expected cardNumberPartial value.
Validation:
  The assertion checks if the getCardNumberPartial() method correctly retrieves the value of the private cardNumberPartial field.
  This test ensures that the getter method functions as expected and returns the correct value.

Scenario 2: Partial Card Number is Null

Details:
  TestName: getCardNumberPartialReturnsNull()
  Description: This test checks if the getCardNumberPartial() method returns null when the cardNumberPartial field is not set.
Execution:
  Arrange: Create an instance of the class containing the getCardNumberPartial() method, without setting the cardNumberPartial field.
  Act: Call the getCardNumberPartial() method on the instance.
  Assert: Use assertNull to verify that the returned value is null.
Validation:
  The assertion confirms that the getCardNumberPartial() method returns null when the cardNumberPartial field is not initialized.
  This test ensures that the method handles the case when the field is not set and returns null instead of throwing an exception.

Scenario 3: Partial Card Number is Empty String

Details:
  TestName: getCardNumberPartialReturnsEmptyString()
  Description: This test verifies that the getCardNumberPartial() method returns an empty string when the cardNumberPartial field is set to an empty string.
Execution:
  Arrange: Create an instance of the class containing the getCardNumberPartial() method and set the cardNumberPartial field to an empty string.
  Act: Call the getCardNumberPartial() method on the instance.
  Assert: Use assertEquals to compare the returned value with an empty string.
Validation:
  The assertion checks if the getCardNumberPartial() method correctly returns an empty string when the cardNumberPartial field is set to an empty string.
  This test ensures that the method handles empty string values properly and returns them as expected.

Scenario 4: Partial Card Number is Not Modified

Details:
  TestName: getCardNumberPartialDoesNotModifyValue()
  Description: This test verifies that the getCardNumberPartial() method does not modify the value of the cardNumberPartial field.
Execution:
  Arrange: Create an instance of the class containing the getCardNumberPartial() method and set the cardNumberPartial field to a specific value.
  Act: Call the getCardNumberPartial() method on the instance and store the returned value.
  Assert: Use assertEquals to compare the stored value with the original cardNumberPartial value.
Validation:
  The assertion confirms that the getCardNumberPartial() method does not modify the value of the cardNumberPartial field.
  This test ensures that the getter method only retrieves the value without altering it, maintaining the integrity of the field.

These test scenarios cover different aspects of the getCardNumberPartial() method, including retrieving the correct value, handling null and empty string cases, and ensuring that the method does not modify the field value. They help validate the behavior of the method under various conditions.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import java.util.stream.Stream;
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

class GetCardDetails200ResponseGetCardNumberPartialTest {

	@Test
	void getCardNumberPartialReturnsValue() {
		// Arrange
		GetCardDetails200Response response = new GetCardDetails200Response();
		String expectedCardNumberPartial = "1234";
		response.setCardNumberPartial(expectedCardNumberPartial);
		// Act
		String actualCardNumberPartial = response.getCardNumberPartial();
		// Assert
		assertEquals(expectedCardNumberPartial, actualCardNumberPartial);
	}

	@Test
	void getCardNumberPartialReturnsNull() {
		// Arrange
		GetCardDetails200Response response = new GetCardDetails200Response();
		// Act
		String actualCardNumberPartial = response.getCardNumberPartial();
		// Assert
		assertNull(actualCardNumberPartial);
	}

	@Test
	void getCardNumberPartialReturnsEmptyString() {
		// Arrange
		GetCardDetails200Response response = new GetCardDetails200Response();
		String expectedCardNumberPartial = "";
		response.setCardNumberPartial(expectedCardNumberPartial);
		// Act
		String actualCardNumberPartial = response.getCardNumberPartial();
		// Assert
		assertEquals(expectedCardNumberPartial, actualCardNumberPartial);
	}

	@Test
	void getCardNumberPartialDoesNotModifyValue() {
		// Arrange
		GetCardDetails200Response response = new GetCardDetails200Response();
		String expectedCardNumberPartial = "5678";
		response.setCardNumberPartial(expectedCardNumberPartial);
		// Act
		String actualCardNumberPartial = response.getCardNumberPartial();
		// Assert
		assertEquals(expectedCardNumberPartial, actualCardNumberPartial);
		assertEquals(expectedCardNumberPartial, response.getCardNumberPartial());
	}

	@ParameterizedTest
	@MethodSource("provideCardNumberPartialValues")
	void getCardNumberPartialReturnsExpectedValue(String expectedCardNumberPartial) {
		// Arrange
		GetCardDetails200Response response = new GetCardDetails200Response();
		response.setCardNumberPartial(expectedCardNumberPartial);
		// Act
		String actualCardNumberPartial = response.getCardNumberPartial();
		// Assert
		assertEquals(expectedCardNumberPartial, actualCardNumberPartial);
	}

	private static Stream<Arguments> provideCardNumberPartialValues() {
		return Stream.of(Arguments.of("1234"), Arguments.of("5678"), Arguments.of("9012"), Arguments.of(""));
	}

}