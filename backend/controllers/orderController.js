import asyncHandler from "../middleware/asyncHandler.js";
import Order from "../models/orderModel.js";

// @desc Create new order
// @route POST /api/orders
//  @access Private
const addOrderItems = asyncHandler(async (req, res) => {
  const {
    orderItems,
    shippingAddress,
    paymentMethod,
    itemsPrice,
    taxPrice,
    shippingPrice,
    totalPrice,
  } = req.body;
  // Checking if orderItems array is empty and returning an error if so
  if (orderItems && orderItems.length === 0) {
    res.status(400);
    throw new Error("No order items");
  } else {
    // Creating a new order document
    const order = new Order({
      orderItems: orderItems.map((x) => ({
        ...x, // Spread the current item
        product: x._id, // Set the product ID for each order item
        _id: undefined, // Remove the _id from the order item to avoid any issues with Mongoose saving
      })),
      user: req.user._id,
      shippingAddress,
      paymentMethod,
      itemsPrice,
      taxPrice,
      shippingPrice,
      totalPrice,
    });
    // Saving the new order to the database
    const createOrder = await order.save();
    // Sending a response with the newly created order object
    res.status(201).json(createOrder);
  }
});
// @desc Get logged in users orders
// @route GET /api/orders/myOrders
//  @access Private
const getMyOrders = asyncHandler(async (req, res) => {
  // Fetching all orders for the logged-in user (using the user ID from the request)
  const orders = await Order.find({ user: req.user._id });
  // Sending back the orders found for the user with a 200 (OK) status
  res.status(200).json(orders);
});

// @desc Get order by ID
// @route GET /api/orders/:id
//  @access Private
const getOrderById = asyncHandler(async (req, res) => {
  // Finding the order by the ID provided in the request parameters
  // Populating the user field with name and email from the user document
  const order = await Order.findById(req.params.id).populate(
    "user",
    "name email"
  );

  if (order) {
    res.status(200).json(order);
  } else {
    res.status(404);
    throw new Error("Order not found");
  }
});

// @desc Update order to paid
// @route PUT /api/orders/:id/pay
//  @access Private
const updateOrderToPaid = asyncHandler(async (req, res) => {
  // Finding the order by ID
  const order = await Order.findById(req.params.id);

  if (order) {
    // Marking the order as paid
    order.isPaid = true;
    order.paidAt = Date.now(); // Setting the paid timestamp
    // Storing payment result details
    order.paymentResult = {
      id: req.body.id, // Payment ID from the request
      status: req.body.status, // Payment status from the request
      update_time: req.body.update_time, // Payment update time
      email_address: req.body.payer.email_address, // Payer's email address
    };
    // Saving the updated order with the payment details
    const updatedOrder = await order.save();
    // Returning the updated order with a 200 (OK) status
    res.status(200).json(updatedOrder);
  } else {
    res.status(404); // Setting status to 404 if the order is not found
    throw new Error("Order not found");
  }
});

// @desc Update order to delivered
// @route PUT /api/orders/:id/deliver
//  @access Private/Admin
const updateOrderToDelivered = asyncHandler(async (req, res) => {
  const order = await Order.findById(req.params.id);

  if (order) {
    order.isDelivered = true;
    order.deliveredAt = Date.now();

    const updateOrder = await order.save();

    res.status(200).json(updateOrder);
  } else {
    res.status(404);
    throw new Error("Order not found");
  }
});

// @desc Get all orders
// @route GET /api/orders/
//  @access Private/Admin
const getOrders = asyncHandler(async (req, res) => {
  const orders = await Order.find({}).populate("user", "id name");
  res.status(200).json(orders);
});

export {
  addOrderItems,
  getMyOrders,
  getOrderById,
  updateOrderToPaid,
  updateOrderToDelivered,
  getOrders,
};
