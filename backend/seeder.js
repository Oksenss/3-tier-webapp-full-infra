import User from "./models/userModel.js";
import Product from "./models/productModel.js";
import Order from "./models/orderModel.js";
import products from "./data/products.js";

/**
 * Seeds the admin user if one doesn't exist.
 * In DEV environment, creates admin@email.com with password 123456.
 * Otherwise, reads credentials from environment variables injected by ECS/Secrets Manager.
 * @returns {Promise<object|null>} The Mongoose user document for the admin, or null if creation failed.
 */
const seedAdminUser = async () => {
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
 * It's idempotent and will only run if the products collection is empty.
 * @param {string} adminUserId - The MongoDB ObjectId of the admin user to associate products with.
 */
const seedProducts = async (adminUserId) => {
  // Guard clause: Don't run if we don't have an admin user to assign products to.
  if (!adminUserId) {
    console.log("Admin user ID not provided, skipping product seed.");
    return;
  }

  try {
    // 1. Check if products already exist to prevent re-seeding
    const productCount = await Product.countDocuments();
    if (productCount > 0) {
      console.log("Product data already exists. Skipping product seed.");
      return;
    }

    // 2. Clear out any old order data to ensure a clean slate.
    // We do NOT delete users, as our admin was just created.
    await Order.deleteMany({});
    console.log("Cleared existing order data.");

    // 3. Prepare the product data by associating each product with the admin user
    const sampleProducts = products.map((product) => {
      return { ...product, user: adminUserId };
    });

    // 4. Insert the prepared product data into the database
    await Product.insertMany(sampleProducts);
    console.log("✅ SUCCESS: Product data has been seeded.");
  } catch (error) {
    console.error("❌ ERROR during product seeding:", error);
  }
};

/**
 * Main seeder function to be called on application startup.
 * Orchestrates the seeding of all necessary initial data.
 */
const runSeeders = async () => {
  console.log("Running data seeders...");
  const adminUser = await seedAdminUser();

  // Only attempt to seed products if we successfully found or created an admin user
  if (adminUser) {
    await seedProducts(adminUser._id);
  }
  console.log("Data seeders finished.");
};

export default runSeeders;
