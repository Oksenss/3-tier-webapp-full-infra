// Import the necessary function from Redux Toolkit to create a slice
import { createSlice } from "@reduxjs/toolkit";

// Define the initial state for the auth slice.
// The userInfo will be initialized from localStorage if available, or set to `null` if not.
// This ensures the user remains logged in between page reloads if their info was saved in localStorage.
const initialState = {
  userInfo: localStorage.getItem("userInfo")
    ? JSON.parse(localStorage.getItem("userInfo")) // If userInfo exists in localStorage, parse it to an object
    : null, // If no userInfo is in localStorage, set it to null (logged out state)
};

// Create the `auth` slice using Redux Toolkit's `createSlice` function.
// A slice is essentially a reducer with actions and its corresponding state.
const authSlice = createSlice({
  name: "auth", // Name of the slice, used to identify the reducer in the Redux store
  initialState, // The initial state defined above
  reducers: {
    // The `setCredentials` reducer updates the `userInfo` state with the action's payload
    // and saves the `userInfo` to localStorage for persistence across page reloads.
    setCredentials: (state, action) => {
      state.userInfo = action.payload; // Update the `userInfo` in the state with the provided payload
      localStorage.setItem("userInfo", JSON.stringify(action.payload)); // Save the payload to localStorage as a JSON string
    },

    // The `logout` reducer clears the `userInfo` state and removes `userInfo` from localStorage.
    // This is useful for logging the user out.
    logout: (state, action) => {
      state.userInfo = null; // Set the `userInfo` to null, indicating the user is logged out
      localStorage.removeItem("userInfo"); // Remove the `userInfo` from localStorage
    },
  },
});

// Export the action creators for use in other parts of the app.
// These action creators will be used to dispatch actions that modify the auth state.
export const { setCredentials, logout } = authSlice.actions;

// Export the reducer to be included in the Redux store.
// This will handle the changes to the state based on the dispatched actions.
export default authSlice.reducer;
