Feature: E-commerce Website Shopping and Checkout Workflow

  As a user, I want to browse products, add them to my cart, and complete the checkout process,
  so that I can purchase items from the online store.

  #-----------------------------------------------------#
  #                  UI Test Scenarios                  #
  #-----------------------------------------------------#

  Background:
    Given I am on the homepage at "https://share.google/gX4PkITYxjSjISHwh"

  Scenario: Successful end-to-end purchase of a product
    When I click the "SHOP NOW" button in the "Latest Eyewear For You" category
    And I navigate to page "2" of the product list
    And I click on the product named "Red Hoodie"
    And I click the "ADD TO CART" button
    Then I should see a confirmation message containing "Red Hoodie has been added to your cart"
    When I click the "VIEW CART" button
    And I select the "Delivery Express" shipping option
    And I click the "PROCEED TO CHECKOUT" button
    And I fill in the billing details:
      | First name    | John                  |
      | Last name     | Doe                   |
      | Company name  | ACME Corp             |
      | Country       | United States (US)    |
      | Street address| 123 Main St           |
      | Town / City   | Beverly Hills         |
      | State         | California            |
      | Postcode / ZIP| 90210                 |
      | Phone         | 555-123-4567          |
      | Email address | john.doe@example.com  |
    And I select the "Check payments" payment method
    And I click the "PLACE ORDER" button
    Then I should be redirected to the order confirmation page
    And I should see the message "Thank you. Your order has been received."

  Scenario Outline: User fails to checkout due to missing required fields
    Given I have added the "Red Hoodie" product to the cart from page "2"
    When I proceed to the checkout page
    And I fill in all billing details except for "<MissingField>"
    And I click the "PLACE ORDER" button
    Then I should see an error message stating "<ErrorMessage>"
    And I should remain on the checkout page

    Examples:
      | MissingField   | ErrorMessage                                        |
      | First name     | "Billing First name is a required field."           |
      | Last name      | "Billing Last name is a required field."            |
      | Street address | "Billing Street address is a required field."       |
      | Town / City    | "Billing Town / City is a required field."          |
      | Postcode / ZIP | "Billing Postcode / ZIP is a required field."       |
      | Phone          | "Billing Phone is a required field."                |
      | Email address  | "Billing Email address is a required field."        |

  Scenario: User follows the specified flow leading to checkout errors
    When I click the "SHOP NOW" button in the "Latest Eyewear For You" category
    And I navigate to page "2" of the product list
    And I click on the product named "Red Hoodie"
    And I click the "ADD TO CART" button
    And I click the "VIEW CART" button
    And I select the "Local pickup" shipping option
    And I select the "Delivery Express" shipping option
    And I select the "Registered Mail" shipping option
    And I click the "PROCEED TO CHECKOUT" button
    And I fill in the billing details:
      | First name    | Jane                  |
      | Last name     | Smith                 |
      | Country       | United States (US)    |
      | Street address| 456 Oak Ave           |
      | Town / City   | Anytown               |
      | State         | California            |
      | Phone         | 555-987-6543          |
      | Email address | jane.smith@test.com   |
    And I click the "PLACE ORDER" button
    Then I should see an error message "Billing Postcode / ZIP is a required field."
    When I enter "90210" in the "Postcode / ZIP" field
    And I click the "PLACE ORDER" button
    Then I should see an error message "Invalid payment method."

  Scenario: Update product quantity in the cart
    Given I have added the "Red Hoodie" product to the cart from page "2"
    When I navigate to the cart page
    And I change the quantity for "Red Hoodie" to "3"
    And I click the "UPDATE CART" button
    Then the cart subtotal should be updated correctly for 3 items
    And I should see the message "Cart updated."

  Scenario: Remove a product from the cart
    Given I have added the "Red Hoodie" product to the cart from page "2"
    When I navigate to the cart page
    And I remove the "Red Hoodie" from the cart
    Then I should see the message "Cart is currently empty."
    And the cart subtotal should be "$0.00"

  Scenario: Navigate product pages using pagination controls
    When I click the "SHOP NOW" button in the "Latest Eyewear For You" category
    Then I should be on page "1" of the product list
    When I click the "Next" pagination arrow
    Then I should see products listed on page "2"
    When I click the "Previous" pagination arrow
    Then I should see products listed on page "1"

  #-----------------------------------------------------#
  #                  API Test Scenarios                 #
  #-----------------------------------------------------#

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the content type is 'application/json'
    And I have a valid user session token from 'AUTH_TOKEN'

  Scenario: Retrieve a list of products from the first page
    When I send a GET request to '/api/products'
    Then the response status should be 200
    And the response body should be a JSON array
    And the response should contain a 'pagination' object with 'currentPage' as 1
    And each product object in the response should contain 'id', 'name', and 'price'

  Scenario: Retrieve a list of products from a specific page
    When I send a GET request to '/api/products?page=2'
    Then the response status should be 200
    And the response body should be a JSON array
    And the response should contain a 'pagination' object with 'currentPage' as 2

  Scenario: Retrieve details for a specific product successfully
    When I send a GET request to '/api/products/red-hoodie'
    Then the response status should be 200
    And the response body 'name' should be 'Red Hoodie'
    And the response body should contain 'id', 'description', 'price', and 'stock_quantity'

  Scenario: Attempt to retrieve details for a non-existent product
    When I send a GET request to '/api/products/non-existent-product-123'
    Then the response status should be 404
    And the response body should contain an 'error' message "Product not found"

  Scenario: Add a product to the cart successfully
    Given the request body:
      '''
      {
        "product_id": "red-hoodie",
        "quantity": 1
      }
      '''
    When I send a POST request to '/api/cart/items'
    Then the response status should be 200
    And the response body 'message' should be 'Item added to cart successfully'
    And the response body 'cart.items' array should contain an item with 'product_id' as 'red-hoodie'

  Scenario: Attempt to add a product with invalid quantity to the cart
    Given the request body:
      '''
      {
        "product_id": "red-hoodie",
        "quantity": 0
      }
      '''
    When I send a POST request to '/api/cart/items'
    Then the response status should be 400
    And the response body should contain an 'error' message "Quantity must be greater than zero"

  Scenario: View the contents of the user's cart
    Given I have already added 'Red Hoodie' with quantity 1 to the cart via API
    When I send a GET request to '/api/cart'
    Then the response status should be 200
    And the response body 'items' array should have a size of 1
    And the first item in the 'items' array should have 'name' as 'Red Hoodie'
    And the response body should contain 'subtotal' and 'total' fields

  Scenario: Update the quantity of an item in the cart
    Given I have already added 'Red Hoodie' with quantity 1 to the cart via API
    And the request body:
      '''
      {
        "quantity": 3
      }
      '''
    When I send a PUT request to '/api/cart/items/red-hoodie'
    Then the response status should be 200
    And the response body 'message' should be 'Cart updated successfully'
    And the response body 'cart.items[0].quantity' should be 3

  Scenario: Remove an item from the cart
    Given I have already added 'Red Hoodie' to the cart via API
    When I send a DELETE request to '/api/cart/items/red-hoodie'
    Then the response status should be 200
    And the response body 'message' should be 'Item removed from cart'
    And the response body 'cart.items' array should be empty

  Scenario: Successfully place an order with valid data
    Given I have items in my cart
    And the request body:
      '''
      {
        "billing_address": {
          "first_name": "John",
          "last_name": "Doe",
          "address_1": "123 Main St",
          "city": "Beverly Hills",
          "state": "CA",
          "postcode": "90210",
          "country": "US",
          "email": "john.doe@example.com",
          "phone": "555-123-4567"
        },
        "shipping_method": "delivery_express",
        "payment_method": "check_payments"
      }
      '''
    When I send a POST request to '/api/checkout/place-order'
    Then the response status should be 201
    And the response body should contain an 'order_id'
    And the response body 'status' should be 'processing'

  Scenario: Fail to place an order with missing billing information
    Given I have items in my cart
    And the request body:
      '''
      {
        "billing_address": {
          "first_name": "John",
          "last_name": "Doe",
          "postcode": "90210"
        },
        "shipping_method": "delivery_express",
        "payment_method": "check_payments"
      }
      '''
    When I send a POST request to '/api/checkout/place-order'
    Then the response status should be 400
    And the response body should contain an 'error' field
    And the response body 'error.details' should contain "Missing required billing fields: address_1, city, state, country, email, phone"

  Scenario: Fail to place an order with an invalid payment method
    Given I have items in my cart
    And a complete and valid billing address payload
    And the request body contains 'payment_method' as 'invalid_payment_gateway'
    When I send a POST request to '/api/checkout/place-order'
    Then the response status should be 400
    And the response body 'error' should be 'Invalid payment method.'
