// Middleware to handle 404 Not Found errors
const notFound = (req, res, next) => {
  // Create a new error with a message indicating the requested URL was not found
  const error = new Error(`Not found - ${req.originalUrl}`);

  // Set the response status to 404 Not Found
  res.status(404);

  // Pass the error to the next middleware
  next(error);
};

// General error handling middleware
const errorHandler = (err, req, res, next) => {
  // Determine the status code: use 500 Internal Server Error if the status code is still 200
  let statusCode = res.statusCode === 200 ? 500 : res.statusCode;

  // Use the error message from the error object
  let message = err.message;

  // Check for Mongoose CastError, which indicates a bad ObjectId
  if (err.name === "CastError" && err.kind === "ObjectId") {
    // Set a user-friendly message and change the status code to 404 Not Found
    message = `Resource not found`;
    statusCode = 404;
  }

  // Send the error response as JSON
  res.status(statusCode).json({
    message,
    // Include the stack trace in non-production environments for debugging
    stack: process.env.NODE_ENV === "production" ? "Cheeese" : err.stack,
  });
};

// Export the notFound and errorHandler middleware functions
export { notFound, errorHandler };
