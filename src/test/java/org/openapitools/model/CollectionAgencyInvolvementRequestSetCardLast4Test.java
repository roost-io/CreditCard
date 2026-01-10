

package org.openapitools.model;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
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

public class CollectionAgencyInvolvementRequestSetCardLast4Test {
    @Test
    @Tag("valid")
    public void testSetValidCardLast4() {
        // Arrange
        CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest(null, null, null);
        // Act
        request.setCardLast4("1234");
        // Assert
        assertEquals("1234", request.getCardLast4());
    }
    @Test
    @Tag("invalid")
    public void testSetInvalidCardLast4TooShort() {
        // Arrange
        CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest(null, null, null);
        // Act
        request.setCardLast4("123");
        // Assert
        assertEquals("123", request.getCardLast4()); // no validation in the setter method
    }
    @Test
    @Tag("invalid")
    public void testSetInvalidCardLast4TooLong() {
        // Arrange
        CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest(null, null, null);
        // Act
        request.setCardLast4("12345");
        // Assert
        assertEquals("12345", request.getCardLast4()); // no validation in the setter method
    }
    @Test
    @Tag("invalid")
    public void testSetInvalidCardLast4NonNumeric() {
        // Arrange
        CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest(null, null, null);
        // Act
        request.setCardLast4("abcd");
        // Assert
        assertEquals("abcd", request.getCardLast4()); // no validation in the setter method
    }
    @Test
    @Tag("boundary")
    public void testSetNullCardLast4() {
        // Arrange
        CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest(null, null, null);
        // Act
        request.setCardLast4(null);
        // Assert
        assertEquals(null, request.getCardLast4());
    }
    @Test
    @Tag("boundary")
    public void testSetEmptyCardLast4() {
        // Arrange
        CollectionAgencyInvolvementRequest request = new CollectionAgencyInvolvementRequest(null, null, null);
        // Act
        request.setCardLast4("");
        // Assert
        assertEquals("", request.getCardLast4());
    }
}