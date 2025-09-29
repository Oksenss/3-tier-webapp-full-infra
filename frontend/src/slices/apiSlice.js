// Import necessary functions from Redux Toolkit Query for creating API slices
// create API is async and we need it for API
import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

// Import the BASE_URL constant, which contains the base URL for the API
import { BASE_URL } from "../constants";

// Define a custom base query using fetchBaseQuery
// fetchBaseQuery is a utility that helps to make HTTP requests to a specified base URL.
const baseQuery = fetchBaseQuery({
  baseUrl: BASE_URL, // The API base URL defined in your constants file
});

// Create an API slice using createApi from Redux Toolkit
// The API slice is responsible for managing API requests and responses.
export const apiSlice = createApi({
  // The baseQuery determines how the API requests will be made (e.g., which base URL to use).
  baseQuery: baseQuery,

  // Tag types are used to optimize cache management in Redux Toolkit Query.
  // It helps to mark which pieces of data are associated with specific endpoints,
  // allowing you to invalidate or refetch certain data based on the tags.
  tagTypes: ["Product", "Order", "User"],

  // The endpoints field is where you define all of your API endpoints.
  // Here, the `builder` function is passed which helps to define specific API endpoints.
  // The endpoints will be added inside this function. Right now it's an empty object, meaning no endpoints are defined yet.
  endpoints: (builder) => ({}),
});
