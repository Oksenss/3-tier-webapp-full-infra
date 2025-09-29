import jwt from "jsonwebtoken";
// logic for token generation
const generateToken = (res, userId) => {
  // token expires in 30 days
  // generate token for user with certain Id
  const token = jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: "30d",
  });

  // Set JWT as HTTP-Only cookie
  res.cookie("jwt", token, {
    // for better security
    httpOnly: true,
    //Set to true in production
    secure: process.env.NODE_ENV !== "development",
    // only the same page can access it
    sameSite: "strict",
    maxAge: 30 * 24 * 60 * 60 * 1000,
  });
};

export default generateToken;
