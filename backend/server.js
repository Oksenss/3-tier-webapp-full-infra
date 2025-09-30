// here is all the backend logic
import path from "path";
import express from "express";
import dotenv from "dotenv";
import productRoutes from "./routes/productRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";
import uploadRoutes from "./routes/uploadRoutes.js";
import { notFound, errorHandler } from "./middleware/errorMiddleware.js";
import connectDB from "./config/db.js";
import cookieParser from "cookie-parser";
import runSeeders from "./seeder.js";
// get env variables
dotenv.config();

// set a port
const port = process.env.PORT || 8080;

// connect to db
connectDB();

// ADDED JUST NOW
runSeeders();

// start the backend
const app = express();

// Body parser middleware for authentication
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(cookieParser());

// ADD THIS HEALTH CHECK ENDPOINT
app.get("/api/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    port: port,
  });
});

// app.get("/api/new-test-endpoint", (req, res) => {
//   res.status(200).json({
//     message: "This is a new test endpoint!",
//     timestamp: new Date().toISOString(),
//   });
// });

// test route
// route for products go to /routes/productRoutes
app.use("/api/products", productRoutes);
app.use("/api/users", userRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/uploads", uploadRoutes);

app.get("/api/config/paypal", (req, res) =>
  res.send({ clientId: process.env.PAYPAL_CLIENT_ID })
);

const __dirname = path.resolve();
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

if (process.env.NODE_ENV === "production") {
  app.use(express.static(path.join(__dirname, "/frontend/build")));

  app.get("*", (req, res) =>
    res.sendFile(path.resolve(__dirname, "frontend", "build", "index.html"))
  );
} else {
  app.get("/", (req, res) => {
    res.send("API is running....");
  });
}

// error handling logic
app.use(notFound);
app.use(errorHandler);

// start the app
app.listen(port, () => console.log(`Server running on port ${port}`));
