Feature: E-commerce Store Product Purchase and Management

  Background:
    Given I am on the homepage at "https://share.google/gX4PkITYxjSjISHwh"

# UI Test Scenarios
# These scenarios test the user interface flow from browsing products to checkout.

  Scenario: Successfully purchase a product with complete and valid information
    Given I am on the product listing page after clicking "SHOP NOW"
    When I navigate to page "2" of the product list
    And I select the product named "Red Hoodie"
    And I click the "ADD TO CART" button
    And I click the "VIEW CART" button
    And I select "Delivery Express" as the shipping method
    And I click the "PROCEED TO CHECKOUT" button
    And I fill in the billing details:
      | Field         | Value              |
      | First name    | John               |
      | Last name     | Doe                |
      | Country       | United States (US) |
      | Street address| 123 Main St        |
      | Town / City   | Anytown            |
      | State         | California         |
      | Postcode / ZIP| 90210              |
      | Phone         | 555-123-4567       |
      | Email address | john.doe@test.com  |
    And I select a valid payment method
    When I click the "PLACE ORDER" button
    Then I should see the order confirmation page
    And I should see a success message "Thank you. Your order has been received."

  Scenario Outline: Attempt to checkout with missing required billing information
    Given I have added "Red Hoodie" to the cart and proceeded to checkout
    When I fill in all billing details except for "<MissingField>"
    And I click the "PLACE ORDER" button
    Then I should see a validation error message for the "<MissingField>" field
    And the error message should state "Billing <ErrorMessage> is a required field."

    Examples:
      | MissingField   | ErrorMessage |
      | First name     | First name   |
      | Last name      | Last name    |
      | Street address | Street address |
      | Town / City    | Town / City  |
      | Postcode / ZIP | Postcode / ZIP |
      | Phone          | Phone        |
      | Email address  | Email address|

  Scenario: User follows the specified flow leading to checkout errors
    Given I am on the product listing page after clicking "SHOP NOW"
    When I navigate to page "2" of the product list
    And I select the product named "Red Hoodie"
    And I click the "ADD TO CART" button
    And I click the "VIEW CART" button
    And I select "Local pickup" as the shipping method
    And I select "Delivery Express" as the shipping method
    And I select "Registered Mail" as the shipping method
    And I click the "PROCEED TO CHECKOUT" button
    And I fill in the billing details without the postcode:
      | Field         | Value              |
      | First name    | Jane               |
      | Last name     | Smith              |
      | Country       | United States (US) |
      | Street address| 456 Oak Ave        |
      | Town / City   | Sometown           |
      | State         | New York           |
      | Phone         | 555-987-6543       |
      | Email address | jane.smith@test.com|
    And I click the "PLACE ORDER" button
    Then I should see a validation error message stating the Postcode is required
    When I enter "10001" in the "Postcode / ZIP" field
    And I click the "PLACE ORDER" button
    Then I should see an error message "Invalid payment method."
    And I should remain on the checkout page

  Scenario: Update product quantity in the cart
    Given I have added "Red Hoodie" to the cart and I am on the cart page
    When I change the quantity of "Red Hoodie" to "3"
    And I click the "Update cart" button
    Then the cart subtotal should be updated correctly for 3 items
    And I should see a message "Cart updated."

  Scenario: Remove a product from the cart
    Given I have added "Red Hoodie" to the cart and I am on the cart page
    When I click the remove icon for the "Red Hoodie" product
    Then the product "Red Hoodie" should be removed from the cart
    And I should see a message "“Red Hoodie” removed. Undo?"
    And the cart should show as empty

  Scenario: Navigate through product pages using pagination controls
    Given I am on the product listing page
    When I click the "Next" arrow button for pagination
    Then the URL should contain "page/2"
    And I should see a different set of products
    When I click on the page number "1"
    Then the URL should contain "page/1"
    And I should see the initial set of products

# API Test Scenarios
# These scenarios test the backend API endpoints for products, cart, and orders.

  Feature: E-commerce Store API

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the content type is 'application/json'
    And I have a valid user session token in the 'Authorization' header

  Scenario: Retrieve the list of products on the second page
    When I send a GET request to '/api/products?page=2'
    Then the response status should be 200
    And the response body should be a JSON object
    And the response body should contain a 'products' array
    And the response body should contain pagination info with 'currentPage' as 2

  Scenario: Retrieve details for a specific product
    When I send a GET request to '/api/products/red-hoodie'
    Then the response status should be 200
    And the response body 'name' should be 'Red Hoodie'
    And the response body should contain 'id', 'price', 'description', and 'stock_quantity'

  Scenario: Add a product to the cart successfully
    Given the request body:
      '''
      {
        "product_id": "red-hoodie",
        "quantity": 1
      }
      '''
    When I send a POST request to '/api/cart/add'
    Then the response status should be 200
    And the response body 'message' should be 'Product added to cart successfully'
    And the response body should contain a 'cart_items' array with the added product

  Scenario: Attempt to add a product with insufficient stock to the cart
    Given the request body:
      '''
      {
        "product_id": "out-of-stock-item",
        "quantity": 1
      }
      '''
    When I send a POST request to '/api/cart/add'
    Then the response status should be 400
    And the response body 'error' should be 'Insufficient stock for this product'

  Scenario: View the contents of the cart
    When I send a GET request to '/api/cart'
    Then the response status should be 200
    And the response body should contain a 'cart_items' array
    And the response body should contain 'subtotal' and 'total' fields

  Scenario: Update the quantity of an item in the cart
    Given the request body:
      '''
      {
        "product_id": "red-hoodie",
        "quantity": 3
      }
      '''
    When I send a PUT request to '/api/cart/update'
    Then the response status should be 200
    And the response body 'message' should be 'Cart updated successfully'
    And the response body 'cart_items[0].quantity' should be 3

  Scenario: Remove an item from the cart
    Given the request body:
      '''
      {
        "product_id": "red-hoodie"
      }
      '''
    When I send a DELETE request to '/api/cart/remove'
    Then the response status should be 200
    And the response body 'message' should be 'Item removed from cart'

  Scenario: Successfully place an order (Checkout)
    Given the request body:
      '''
      {
        "billing_address": {
          "first_name": "John",
          "last_name": "Doe",
          "country": "US",
          "address_1": "123 Main St",
          "city": "Anytown",
          "state": "CA",
          "postcode": "90210",
          "phone": "555-123-4567",
          "email": "john.doe@test.com"
        },
        "shipping_method": "delivery_express",
        "payment_details": {
          "method": "credit_card",
          "token": "tok_valid_payment_token"
        }
      }
      '''
    When I send a POST request to '/api/orders'
    Then the response status should be 201
    And the response body should contain an 'order_id'
    And the response body 'status' should be 'processing'
    And the response body 'message' should be 'Order placed successfully'

  Scenario: Attempt to place an order with missing postcode
    Given the request body:
      '''
      {
        "billing_address": {
          "first_name": "Jane",
          "last_name": "Smith",
          "country": "US",
          "address_1": "456 Oak Ave",
          "city": "Sometown",
          "state": "NY",
          "phone": "555-987-6543",
          "email": "jane.smith@test.com"
        },
        "shipping_method": "registered_mail",
        "payment_details": {
          "method": "credit_card",
          "token": "tok_valid_payment_token"
        }
      }
      '''
    When I send a POST request to '/api/orders'
    Then the response status should be 400
    And the response body 'error' should be 'Validation Failed'
    And the response body 'details' should contain 'billing_address.postcode is a required field'

  Scenario: Attempt to place an order with an invalid payment method
    Given the request body:
      '''
      {
        "billing_address": {
          "first_name": "John",
          "last_name": "Doe",
          "country": "US",
          "address_1": "123 Main St",
          "city": "Anytown",
          "state": "CA",
          "postcode": "90210",
          "phone": "555-123-4567",
          "email": "john.doe@test.com"
        },
        "shipping_method": "delivery_express",
        "payment_details": {
          "method": "credit_card",
          "token": "tok_invalid_or_expired_token"
        }
      }
      '''
    When I send a POST request to '/api/orders'
    Then the response status should be 402
    And the response body 'error' should be 'Payment Failed'
    And the response body 'message' should be 'Invalid payment method.'

  Scenario: Attempt to view cart without authentication
    Given I do not have a valid user session token
    When I send a GET request to '/api/cart'
    Then the response status should be 401
    And the response body 'error' should be 'Unauthorized'
