import asyncHandler from "../middleware/asyncHandler.js";
import User from "../models/userModel.js";
import generateToken from "../utils/generateToken.js";

// @desc Auth user & get token
// @route POST /api/users/login
// @access Public

const authUser = asyncHandler(async (req, res) => {
  // get email and password from the body
  const { email, password } = req.body;
  // look for email in db
  const user = await User.findOne({ email: email });
  // if user exists and the password matches
  if (user && (await user.matchPassword(password))) {
    // create token for the user
    generateToken(res, user._id);
    // respond with 200 but not return password (it will be stored in cookie)
    res.status(200).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      isAdmin: user.isAdmin,
    });
  } else {
    // if invalid email or password (or user dont exist)
    res.status(401);
    throw new Error("Invalid email or password");
  }
});

// @desc Register user
// @route POST /api/users
// @access Public

const registerUser = asyncHandler(async (req, res) => {
  // get the name email and password from the body
  const { name, email, password } = req.body;

  // check whether user already exists
  const userExists = await User.findOne({ email });

  // if exists return an error
  if (userExists) {
    res.status(400);
    throw new Error("User already exists");
  }

  // if user does not exist then create the user
  const user = await User.create({
    name,
    email,
    password,
  });

  // if creation was successful
  if (user) {
    // generate a jwt token
    generateToken(res, user._id);
    // return the data
    res.status(201).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      isAdmin: user.isAdmin,
    });
  } else {
    //if failed return 400
    res.status(400);
    throw new Error("Invalid user data");
  }
});

// @desc Logout user / clear the cookie
// @route POST /api/users/logout
// @access Private

const logoutUser = asyncHandler(async (req, res) => {
  // destroy the cookie
  res.cookie("jwt", "", {
    httpOnly: true,
    expires: new Date(0),
  });
  // return user friendly message
  res.status(200).json({ message: "Logged out successfully" });
});

// @desc Get user profile
// @route GET /api/users/profile
// @access Private

const getUserProfile = asyncHandler(async (req, res) => {
  // get the info of user profile
  const user = await User.findById(req.user._id);
  // if user exists return data
  if (user) {
    res.status(200).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      isAdmin: user.isAdmin,
    });
  } else {
    // if user does not exist throw 404
    res.status(404);
    throw new Error("User not found");
  }
});

// @desc Update user profile
// @route PUT /api/users/profile
// @access Private

const updateUserProfile = asyncHandler(async (req, res) => {
  // find the user by id
  const user = await User.findById(req.user._id);
  // if user exists
  if (user) {
    // depending on body change the values
    user.name = req.body.name || user.name;
    user.email = req.body.email || user.email;

    // if user passed new password then change it
    if (req.body.password) {
      user.password = req.body.password;
    }
    // save the new data
    const updatedUser = await user.save();
    // return new data
    res.status(200).json({
      _id: updatedUser._id,
      name: updatedUser.name,
      email: updatedUser.email,
      isAdmin: updatedUser.isAdmin,
    });
  } else {
    // if failed throw 404
    res.status(404);
    throw new Error("User not found");
  }
});

// @desc Get all users
// @route GET /api/users/
// @access Private/Admin

const getUsers = asyncHandler(async (req, res) => {
  // get all users
  const users = await User.find({});
  res.status(200).json(users);
});

// @desc Get all users
// @route GET /api/users/:id
// @access Private/Admin

const getUserById = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id).select("-password");
  if (user) {
    res.status(200).json(user);
  } else {
    res.status(404);
    throw new Error("User not found");
  }
});

// @desc Get all users
// @route DELETE /api/users/:id
// @access Private/Admin

const deleteUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);

  if (user) {
    if (user.isAdmin) {
      res.status(400);
      throw new Error("Cannot delete admin user");
    }
    await User.deleteOne({ _id: user._id });
    res.status(201).json({ message: "User deleted successfully" });
  } else {
    res.status(404);
    throw new Error("User not found");
  }
});

// @desc Update user
// @route PUT /api/users/:id
// @access Private/Admin

const updateUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);

  if (user) {
    user.name = req.body.name || user.name;
    user.email = req.body.email || user.email;
    user.isAdmin = Boolean(req.body.isAdmin);

    const updatedUser = await user.save();

    res.status(200).json({
      _id: updatedUser._id,
      name: updatedUser.name,
      email: updatedUser.email,
      isAdmin: updatedUser.isAdmin,
    });
  } else {
    res.status(404);
    throw new Error("User not found");
  }
});

export {
  authUser,
  registerUser,
  logoutUser,
  getUserProfile,
  updateUserProfile,
  getUsers,
  deleteUser,
  getUserById,
  updateUser,
};
