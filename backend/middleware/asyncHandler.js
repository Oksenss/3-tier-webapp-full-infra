// async handler logic for creating api
// The asyncHandler function takes an asynchronous function fn as an argument.
// It returns a new function that takes the standard Express.js req, res, and next parameters.
// Inside this returned function, it calls the original fn function and wraps it with Promise.resolve().
// If the promise is rejected (i.e., an error occurs), the .catch(next) method ensures
//that the error is passed to the next middleware.
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

export default asyncHandler;
