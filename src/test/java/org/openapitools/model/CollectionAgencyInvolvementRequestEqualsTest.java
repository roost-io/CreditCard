// ********RoostGPT********
/*
Test generated by RoostGPT for test CreditCard-Unit using AI Type Claude AI and AI Model claude-3-opus-20240229

ROOST_METHOD_HASH=equals_ee72d9c54f
ROOST_METHOD_SIG_HASH=equals_ded257778a

Here are the test scenarios for the given equals method:

Scenario 1: Comparing object with itself

Details:
  TestName: equalsComparingWithSelf
  Description: This test checks if the equals method returns true when an object is compared with itself.
Execution:
  Arrange: Create an instance of CollectionAgencyInvolvementRequest.
  Act: Invoke the equals method, passing the same instance as the argument.
  Assert: Assert that the method returns true.
Validation:
  The assertion verifies that the equals method correctly identifies an object as equal to itself.
  This test ensures the reflexive property of equality.

Scenario 2: Comparing object with null

Details:
  TestName: equalsComparingWithNull
  Description: This test checks if the equals method returns false when an object is compared with null.
Execution:
  Arrange: Create an instance of CollectionAgencyInvolvementRequest.
  Act: Invoke the equals method, passing null as the argument.
  Assert: Assert that the method returns false.
Validation:
  The assertion verifies that the equals method correctly handles comparison with null and returns false.
  This test ensures the equals method does not throw a NullPointerException and follows the contract of returning false when compared with null.

Scenario 3: Comparing object with an instance of a different class

Details:
  TestName: equalsComparingWithDifferentClass
  Description: This test checks if the equals method returns false when an object is compared with an instance of a different class.
Execution:
  Arrange: Create an instance of CollectionAgencyInvolvementRequest and an instance of a different class (e.g., String).
  Act: Invoke the equals method, passing the instance of the different class as the argument.
  Assert: Assert that the method returns false.
Validation:
  The assertion verifies that the equals method correctly identifies objects of different classes as not equal.
  This test ensures the equals method properly compares the class of the objects and returns false when they are different.

Scenario 4: Comparing objects with equal field values

Details:
  TestName: equalsComparingWithEqualFields
  Description: This test checks if the equals method returns true when comparing two objects with equal values for all fields.
Execution:
  Arrange: Create two instances of CollectionAgencyInvolvementRequest with equal values for previousNotifications, responseStatus, and cardLast4 fields.
  Act: Invoke the equals method, passing one instance as the argument to compare with the other instance.
  Assert: Assert that the method returns true.
Validation:
  The assertion verifies that the equals method correctly identifies objects as equal when all their fields have equal values.
  This test ensures the equals method properly compares the relevant fields of the objects and returns true when they are equal.

Scenario 5: Comparing objects with unequal field values

Details:
  TestName: equalsComparingWithUnequalFields
  Description: This test checks if the equals method returns false when comparing two objects with unequal values for any of the fields.
Execution:
  Arrange: Create two instances of CollectionAgencyInvolvementRequest with unequal values for at least one of the fields (previousNotifications, responseStatus, or cardLast4).
  Act: Invoke the equals method, passing one instance as the argument to compare with the other instance.
  Assert: Assert that the method returns false.
Validation:
  The assertion verifies that the equals method correctly identifies objects as not equal when any of their fields have unequal values.
  This test ensures the equals method properly compares the relevant fields of the objects and returns false when they are not equal.

These test scenarios cover the essential cases for testing the equals method, including comparing an object with itself, null, an instance of a different class, and objects with equal and unequal field values. They ensure the correctness of the equals method implementation and its adherence to the equality contract.
*/

// ********RoostGPT********
package org.openapitools.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.Objects;

class CollectionAgencyInvolvementRequestEqualsTest {

	@Test
	void equalsComparingWithSelf() {
		CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		assertTrue(request.equals(request));
	}

	@Test
	void equalsComparingWithNull() {
		CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		assertFalse(request.equals(null));
	}

	@Test
	void equalsComparingWithDifferentClass() {
		CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		assertFalse(request.equals("SomeString"));
	}

	@Test
	void equalsComparingWithEqualFields() {
		CollectionAgencyInvolvementRequest request1 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		CollectionAgencyInvolvementRequest request2 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		assertTrue(request1.equals(request2));
	}

	@Test
	void equalsComparingWithUnequalFields() {
		CollectionAgencyInvolvementRequest request1 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		CollectionAgencyInvolvementRequest request2 = new CollectionAgencyInvolvementRequest("Notification2", "Status2",
				"5678");
		assertFalse(request1.equals(request2));
	}

	@Test
	void equalsComparingWithUnequalPreviousNotifications() {
		CollectionAgencyInvolvementRequest request1 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		CollectionAgencyInvolvementRequest request2 = new CollectionAgencyInvolvementRequest("Notification2", "Status1",
				"1234");
		assertFalse(request1.equals(request2));
	}

	@Test
	void equalsComparingWithUnequalResponseStatus() {
		CollectionAgencyInvolvementRequest request1 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		CollectionAgencyInvolvementRequest request2 = new CollectionAgencyInvolvementRequest("Notification1", "Status2",
				"1234");
		assertFalse(request1.equals(request2));
	}

	@Test
	void equalsComparingWithUnequalCardLast4() {
		CollectionAgencyInvolvementRequest request1 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"1234");
		CollectionAgencyInvolvementRequest request2 = new CollectionAgencyInvolvementRequest("Notification1", "Status1",
				"5678");
		assertFalse(request1.equals(request2));
	}

}