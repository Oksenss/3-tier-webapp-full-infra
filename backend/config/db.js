// import mongoose from "mongoose";

// const connectDB = async () => {
//   const endpoint = process.env.DOCUMENTDB_ENDPOINT;
//   const port = process.env.DOCUMENTDB_PORT || "27017";
//   const username = process.env.DOCUMENTDB_USERNAME;
//   const password = process.env.DOCUMENTDB_PASSWORD;

//   if (!endpoint || !username || !password) {
//     console.error("CRITICAL ERROR: Missing DocumentDB connection parameters.");
//     console.error(
//       "Required: DOCUMENTDB_ENDPOINT, DOCUMENTDB_USERNAME, DOCUMENTDB_PASSWORD"
//     );
//     process.exit(1);
//   }

//   try {
//     // Connection URI without credentials
//     const connectionUri = `mongodb://${endpoint}:${port}/?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false`;

//     console.log(`Attempting to connect to DocumentDB at: ${endpoint}:${port}`);

//     const conn = await mongoose.connect(connectionUri, {
//       // Pass credentials as options instead of in the URI
//       user: username,
//       pass: password,
//       tls: true,
//       tlsCAFile: `global-bundle.pem`,
//     });

//     console.log(`DocumentDB Connected: ${conn.connection.host}`);
//   } catch (error) {
//     console.error(`Error connecting to DocumentDB: ${error.message}`);
//     process.exit(1);
//   }
// };

// export default connectDB;

import mongoose from "mongoose";

const connectDB = async () => {
  // Check if we're in DEV environment
  if (process.env.ENV === "DEV") {
    // Use simple MongoDB connection for development
    const mongoUri = process.env.MONGO_URI;

    if (!mongoUri) {
      console.error(
        "CRITICAL ERROR: MONGO_URI is required in DEV environment."
      );
      process.exit(1);
    }

    try {
      console.log("DEV environment detected, connecting to MongoDB...");
      const conn = await mongoose.connect(mongoUri);
      console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
      console.error(`Error connecting to MongoDB: ${error.message}`);
      process.exit(1);
    }
  } else {
    // Production DocumentDB connection
    const endpoint = process.env.DOCUMENTDB_ENDPOINT;
    const port = process.env.DOCUMENTDB_PORT || "27017";
    const username = process.env.DOCUMENTDB_USERNAME;
    const password = process.env.DOCUMENTDB_PASSWORD;

    if (!endpoint || !username || !password) {
      console.error(
        "CRITICAL ERROR: Missing DocumentDB connection parameters."
      );
      console.error(
        "Required: DOCUMENTDB_ENDPOINT, DOCUMENTDB_USERNAME, DOCUMENTDB_PASSWORD"
      );
      process.exit(1);
    }

    try {
      // Connection URI without credentials
      const connectionUri = `mongodb://${endpoint}:${port}/?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false`;

      console.log(
        `Attempting to connect to DocumentDB at: ${endpoint}:${port}`
      );

      const conn = await mongoose.connect(connectionUri, {
        // Pass credentials as options instead of in the URI
        user: username,
        pass: password,
        tls: true,
        tlsCAFile: `global-bundle.pem`,
      });

      console.log(`DocumentDB Connected: ${conn.connection.host}`);
    } catch (error) {
      console.error(`Error connecting to DocumentDB: ${error.message}`);
      process.exit(1);
    }
  }
};

export default connectDB;
