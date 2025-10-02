// import User from "./models/userModel.js";
// import Product from "./models/productModel.js";
// import Order from "./models/orderModel.js";
// import products from "./data/products.js";

// /**
//  * Seeds the admin user if one doesn't exist.
//  * In DEV environment, creates admin@email.com with password 123456.
//  * Otherwise, reads credentials from environment variables injected by ECS/Secrets Manager.
//  * @returns {Promise<object|null>} The Mongoose user document for the admin, or null if creation failed.
//  */
// const seedAdminUser = async () => {
//   try {
//     let adminEmail, initialPassword;

//     // Check if we're in DEV environment
//     if (process.env.ENV === "DEV") {
//       // Use default dev credentials
//       adminEmail = "admin@email.com";
//       initialPassword = "123456";
//       console.log("DEV environment detected, using default admin credentials.");
//     } else {
//       // Use production credentials from environment variables
//       const adminCredsString = process.env.ADMIN_CREDENTIALS;
//       if (!adminCredsString) {
//         console.log("Admin credentials not found. Skipping admin seed.");
//         return null;
//       }

//       const adminCreds = JSON.parse(adminCredsString);
//       adminEmail = adminCreds.email;
//       initialPassword = adminCreds.password;
//     }

//     // 1. Check if the admin user already exists
//     let adminUser = await User.findOne({ email: adminEmail });

//     if (adminUser) {
//       console.log("Admin user already exists. Seeding not required.");
//       return adminUser; // Return the existing user document
//     }

//     // 2. If not, create the admin user
//     console.log("Admin user not found, creating new admin...");
//     adminUser = await User.create({
//       name: "Admin User",
//       email: adminEmail,
//       password: initialPassword, // The pre-save hook in userModel will hash this
//       isAdmin: true,
//     });

//     console.log("✅ SUCCESS: Admin user created and seeded.");
//     return adminUser; // Return the newly created user document
//   } catch (error) {
//     console.error("❌ ERROR during admin user seeding:", error);
//     return null;
//   }
// };

// /**
//  * Seeds the initial product catalog.
//  * It's idempotent and will only run if the products collection is empty.
//  * @param {string} adminUserId - The MongoDB ObjectId of the admin user to associate products with.
//  */
// const seedProducts = async (adminUserId) => {
//   // Guard clause: Don't run if we don't have an admin user to assign products to.
//   if (!adminUserId) {
//     console.log("Admin user ID not provided, skipping product seed.");
//     return;
//   }

//   try {
//     // 1. Check if products already exist to prevent re-seeding
//     const productCount = await Product.countDocuments();
//     if (productCount > 0) {
//       console.log("Product data already exists. Skipping product seed.");
//       return;
//     }

//     // 2. Clear out any old order data to ensure a clean slate.
//     // We do NOT delete users, as our admin was just created.
//     await Order.deleteMany({});
//     console.log("Cleared existing order data.");

//     // 3. Prepare the product data by associating each product with the admin user
//     const sampleProducts = products.map((product) => {
//       return { ...product, user: adminUserId };
//     });

//     // 4. Insert the prepared product data into the database
//     await Product.insertMany(sampleProducts);
//     console.log("✅ SUCCESS: Product data has been seeded.");
//   } catch (error) {
//     console.error("❌ ERROR during product seeding:", error);
//   }
// };

// /**
//  * Main seeder function to be called on application startup.
//  * Orchestrates the seeding of all necessary initial data.
//  */
// const runSeeders = async () => {
//   console.log("Running data seeders...");
//   const adminUser = await seedAdminUser();

//   // Only attempt to seed products if we successfully found or created an admin user
//   if (adminUser) {
//     await seedProducts(adminUser._id);
//   }
//   console.log("Data seeders finished.");
// };

// export default runSeeders;

import fs from "fs";
import path from "path";
import AWS from "aws-sdk";
import User from "./models/userModel.js";
import Product from "./models/productModel.js";
import Order from "./models/orderModel.js";

// --- The product data is now a local constant ---
const products = [
  {
    name: "Airpods Wireless Bluetooth Headphones",
    image: "/images/airpods.jpg",
    description:
      "Bluetooth technology lets you connect it with compatible devices wirelessly...",
    brand: "Apple",
    category: "Electronics",
    price: 89.99,
    countInStock: 10,
    rating: 4.5,
    numReviews: 12,
  },
  {
    name: "Samsung Galaxy Tab S7",
    image: "/images/tab-s7.jpg",
    description:
      "11-inch display with 120Hz refresh rate for smooth scrolling...",
    brand: "Samsung",
    category: "Tablets",
    price: 649.99,
    countInStock: 5,
    rating: 4.7,
    numReviews: 25,
  },
  {
    name: "Logitech MX Master 3 Mouse",
    image: "/images/mx-master-3.jpg",
    description:
      "Ergonomic design with customizable buttons for increased productivity...",
    brand: "Logitech",
    category: "Accessories",
    price: 99.99,
    countInStock: 15,
    rating: 4.8,
    numReviews: 30,
  },
  {
    name: "Dell XPS 13 Laptop",
    image: "/images/dell-xps-13.jpg",
    description: "13.3-inch InfinityEdge display with stunning visuals...",
    brand: "Dell",
    category: "Laptops",
    price: 1299.99,
    countInStock: 7,
    rating: 4.6,
    numReviews: 18,
  },
  {
    name: "Apple Watch Series 7",
    image: "/images/apple-watch-7.jpg",
    description: "Always-on Retina display for easy access to information...",
    brand: "Apple",
    category: "Wearables",
    price: 399.99,
    countInStock: 20,
    rating: 4.4,
    numReviews: 15,
  },
  {
    name: "Sony WH-1000XM4 Wireless Headphones",
    image: "/images/sony-wh-1000xm4.jpg",
    description: "Industry-leading noise cancellation technology...",
    brand: "Sony",
    category: "Audio",
    price: 349.99,
    countInStock: 0,
    rating: 4.9,
    numReviews: 50,
  },
];

/**
 * Seeds the admin user if one doesn't exist.
 * (No changes to this function)
 */
const seedAdminUser = async () => {
  // ... (existing code, no changes needed)
  try {
    let adminEmail, initialPassword;

    // Check if we're in DEV environment
    if (process.env.ENV === "DEV") {
      // Use default dev credentials
      adminEmail = "admin@email.com";
      initialPassword = "123456";
      console.log("DEV environment detected, using default admin credentials.");
    } else {
      // Use production credentials from environment variables
      const adminCredsString = process.env.ADMIN_CREDENTIALS;
      if (!adminCredsString) {
        console.log("Admin credentials not found. Skipping admin seed.");
        return null;
      }

      const adminCreds = JSON.parse(adminCredsString);
      adminEmail = adminCreds.email;
      initialPassword = adminCreds.password;
    }

    // 1. Check if the admin user already exists
    let adminUser = await User.findOne({ email: adminEmail });

    if (adminUser) {
      console.log("Admin user already exists. Seeding not required.");
      return adminUser; // Return the existing user document
    }

    // 2. If not, create the admin user
    console.log("Admin user not found, creating new admin...");
    adminUser = await User.create({
      name: "Admin User",
      email: adminEmail,
      password: initialPassword, // The pre-save hook in userModel will hash this
      isAdmin: true,
    });

    console.log("✅ SUCCESS: Admin user created and seeded.");
    return adminUser; // Return the newly created user document
  } catch (error) {
    console.error("❌ ERROR during admin user seeding:", error);
    return null;
  }
};

/**
 * Seeds the initial product catalog.
 * If running on AWS, it first uploads the seed images to S3 if they don't exist.
 * @param {string} adminUserId - The MongoDB ObjectId of the admin user to associate products with.
 */
const seedProducts = async (adminUserId) => {
  if (!adminUserId) {
    console.log("Admin user ID not provided, skipping product seed.");
    return;
  }

  try {
    const productCount = await Product.countDocuments();
    if (productCount > 0) {
      console.log("Product data already exists. Skipping product seed.");
      return;
    }

    // --- NEW: S3 Image Seeding Logic ---
    const nodeEnv = process.env.ENV || "DEV";
    if (nodeEnv !== "DEV") {
      console.log(
        "AWS environment detected. Checking and seeding images to S3..."
      );
      const s3 = new AWS.S3({
        region: process.env.AWS_REGION || "eu-central-1",
      });
      const bucketName = process.env.AWS_IMAGES_BUCKET_NAME;

      if (!bucketName) {
        throw new Error(
          "AWS_IMAGES_BUCKET_NAME env var not set. Cannot seed images."
        );
      }

      // For each product, check and upload its image
      for (const product of products) {
        const imageName = path.basename(product.image); // "airpods.jpg"
        const s3Key = `images/${imageName}`; // "images/airpods.jpg"

        try {
          // Check if object already exists
          await s3.headObject({ Bucket: bucketName, Key: s3Key }).promise();
          console.log(`- Image "${s3Key}" already exists in S3. Skipping.`);
        } catch (error) {
          if (error.code === "NotFound") {
            // Image not found, so upload it
            console.log(`- Image "${s3Key}" not found in S3. Uploading...`);
            const imagePath = path.resolve(
              process.cwd(),
              `./seed-images/${imageName}`
            );

            if (!fs.existsSync(imagePath)) {
              console.warn(
                `  - WARNING: Local image not found at ${imagePath}. Skipping upload.`
              );
              continue;
            }

            const fileContent = fs.readFileSync(imagePath);

            await s3
              .upload({
                Bucket: bucketName,
                Key: s3Key,
                Body: fileContent,
              })
              .promise();

            console.log(`  - ✅ SUCCESS: Uploaded "${s3Key}" to S3.`);
          } else {
            // Some other error
            throw error;
          }
        }
      }
    } else {
      console.log("Local DEV environment detected. Skipping S3 image seeding.");
    }

    // Clear old order data
    await Order.deleteMany({});
    console.log("Cleared existing order data.");

    // Prepare and insert product data (this part is unchanged)
    const sampleProducts = products.map((product) => {
      return { ...product, user: adminUserId };
    });

    await Product.insertMany(sampleProducts);
    console.log("✅ SUCCESS: Product data has been seeded into the database.");
  } catch (error) {
    console.error("❌ ERROR during product seeding:", error);
  }
};

/**
 * Main seeder function to be called on application startup.
 * (No changes to this function)
 */
const runSeeders = async () => {
  console.log("Running data seeders...");
  const adminUser = await seedAdminUser();

  if (adminUser) {
    await seedProducts(adminUser._id);
  }
  console.log("Data seeders finished.");
};

// This is now the one and only default export
export default runSeeders;
