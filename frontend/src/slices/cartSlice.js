// create API is not async and for card functionality its fine
// Import the necessary functions from Redux Toolkit and utility functions for cart management
import { createSlice } from "@reduxjs/toolkit";
import { updateCart } from "../utils/cartUtils"; // A utility function used to update the cart and localStorage

// Define the initial state of the cart
// If a cart exists in localStorage, it will be parsed and used as the initial state.
// Otherwise, a default cart state is created with an empty `cartItems` array, empty `shippingAddress`,
// and a default `paymentMethod` of "PayPal".
const initialState = localStorage.getItem("cart")
  ? JSON.parse(localStorage.getItem("cart")) // If the cart exists in localStorage, parse and use it
  : { cartItems: [], shippingAddress: {}, paymentMethod: "PayPal" }; // Default initial state if no cart in localStorage

// Create the `cart` slice using Redux Toolkit's `createSlice` function
const cartSlice = createSlice({
  name: "cart", // Name of the slice, used to identify the reducer in the Redux store
  initialState, // The initial state defined above
  reducers: {
    // `addToCart` reducer: Adds a product to the cart or updates the quantity if the product is already in the cart
    addToCart: (state, action) => {
      const item = action.payload; // Get the item (product) to add from the action's payload

      // Check if the item already exists in the cart (by matching the product ID)
      const existItem = state.cartItems.find((x) => x._id === item._id);

      if (existItem) {
        // If the item already exists, update its quantity or details
        state.cartItems = state.cartItems.map(
          (x) => (x._id === existItem._id ? item : x) // Replace the existing item with the updated one
        );
      } else {
        // If the item doesn't exist in the cart, add it to the cart
        state.cartItems = [...state.cartItems, item];
      }

      // Update the cart state and synchronize it with localStorage
      return updateCart(state);
    },

    // `removeFromCart` reducer: Removes an item from the cart by its ID
    removeFromCart: (state, action) => {
      // Filter out the item to be removed from the cart by its ID
      state.cartItems = state.cartItems.filter((x) => x._id !== action.payload);

      // Update the cart state and synchronize it with localStorage
      return updateCart(state);
    },

    // `saveShippingAddress` reducer: Saves the shipping address in the cart state
    saveShippingAddress: (state, action) => {
      state.shippingAddress = action.payload; // Set the shipping address to the payload from the action

      // Update the cart state and synchronize it with localStorage
      return updateCart(state);
    },

    // `savePaymentMethod` reducer: Saves the selected payment method in the cart state
    savePaymentMethod: (state, action) => {
      state.paymentMethod = action.payload; // Set the payment method to the payload from the action

      // Update the cart state and synchronize it with localStorage
      return updateCart(state);
    },

    // `clearCartItems` reducer: Clears all items from the cart
    clearCartItems: (state, action) => {
      state.cartItems = []; // Set the cartItems array to an empty array

      // Update the cart state and synchronize it with localStorage
      return updateCart(state);
    },
  },
});

// Export the action creators for use in other parts of the app
// These actions can be dispatched from anywhere to modify the cart state
export const {
  addToCart,
  removeFromCart,
  saveShippingAddress,
  savePaymentMethod,
  clearCartItems,
} = cartSlice.actions;

// Export the reducer to be used in the Redux store
// This will handle changes to the cart state based on the dispatched actions
export default cartSlice.reducer;
