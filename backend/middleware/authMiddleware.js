//middleware for authentication
//import jwt to generate it
import jwt from "jsonwebtoken";
// Import out async handler
import asyncHandler from "./asyncHandler.js";
// get the user model
import User from "../models/userModel.js";

// Middleware to protect routes by ensuring the user is authenticated
const protect = asyncHandler(async (req, res, next) => {
  let token;

  // Attempt to read the JWT from the 'jwt' cookie
  token = req.cookies.jwt;

  // If a token is found, proceed to verify it
  if (token) {
    try {
      // Verify the token using the secret key from environment variables
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Find the user in the database by the ID decoded from the JWT
      // Exclude the password field from the user data
      req.user = await User.findById(decoded.userId).select("-password");

      // Proceed to the next middleware or route handler
      next();
    } catch (error) {
      // Log the error for debugging purposes
      console.error(error);

      // Respond with a 401 Unauthorized status if token verification fails
      res.status(401);
      throw new Error("Not authorized, token failed");
    }
  } else {
    // Respond with a 401 Unauthorized status if no token is provided
    res.status(401);
    throw new Error("Not authorized, no token");
  }
});

// User must be an admin
const admin = (req, res, next) => {
  // if user is admin
  if (req.user && req.user.isAdmin) {
    // Proceed to the next middleware or route handler
    next();
  } else {
    res.status(401);
    throw new Error("Not authorized as an admin");
  }
};

export { protect, admin };
