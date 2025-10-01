// import path from "path";
// import express from "express";
// import multer from "multer";

// const router = express.Router();

// const storage = multer.diskStorage({
//   destination(req, file, cb) {
//     cb(null, "uploads/");
//   },
//   filename(req, file, cb) {
//     cb(
//       null,
//       `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`
//     );
//   },
// });

// function checkFileType(file, cb) {
//   const filetypes = /jpg|jpeg|png/;
//   const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
//   const mimetype = filetypes.test(file.mimetype);
//   if (extname && mimetype) {
//     return cb(null, true);
//   } else {
//     cb("Images only");
//   }
// }

// const upload = multer({
//   storage,
// });

// router.post("/", upload.single("image"), (req, res) => {
//   res.send({
//     // message: "Image uploaded",
//     image: `/${req.file.path}`,
//   });
// });

// export default router;

import path from "path";
import express from "express";
import multer from "multer";
import AWS from "aws-sdk";
import fs from "fs";
import { promisify } from "util";

const router = express.Router();

/**
 * Checks if the uploaded file is a valid image type.
 * @param {object} file - The file object from Multer.
 * @param {function} cb - The callback function.
 */
function checkFileType(file, cb) {
  const filetypes = /jpg|jpeg|png/;
  const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = filetypes.test(file.mimetype);
  if (extname && mimetype) {
    return cb(null, true);
  } else {
    cb(new Error("Images only!"));
  }
}

// Use 'memoryStorage' to keep the file in a buffer. This is necessary
// for uploading to S3 without first saving to the local disk.
const storage = multer.memoryStorage();

// Initialize multer with memory storage and the file type check.
const upload = multer({
  storage,
  fileFilter: function (req, file, cb) {
    checkFileType(file, cb);
  },
});

// Configure the AWS SDK. It will automatically use the IAM role from the ECS Task
// when running on AWS. For local testing, you would need to configure credentials.
const s3 = new AWS.S3({
  region: process.env.AWS_REGION || "eu-central-1", // Make sure region is set via env var
});

/**
 * @route   POST /api/uploads
 * @desc    Upload an image file.
 * @access  Private (Assumed, as it's part of product editing)
 */
router.post("/", upload.single("image"), async (req, res) => {
  // Use the NODE_ENV variable set in the ECS Task Definition to determine behavior.
  // Default to "DEV" if it's not set.
  const nodeEnv = process.env.NODE_ENV || "DEV";

  // Check if a file was actually uploaded.
  if (!req.file) {
    res.status(400);
    throw new Error("Please select an image file to upload.");
  }

  if (nodeEnv === "DEV") {
    // --- LOCAL DEVELOPMENT FLOW ---
    // Save file to the local 'uploads' directory.
    const uploadsDir = path.resolve(process.cwd(), "uploads");
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const fileName = `${req.file.fieldname}-${Date.now()}${path.extname(
      req.file.originalname
    )}`;
    const filePath = path.join(uploadsDir, fileName);

    try {
      // Write the file from the buffer to the disk.
      await promisify(fs.writeFile)(filePath, req.file.buffer);
      console.log("Image saved locally to:", filePath);

      res.status(200).send({
        message: "Image uploaded locally",
        // The path must be compatible with how the static folder is served.
        // In server.js: app.use('/uploads', express.static(...))
        // So the URL becomes http://localhost:8080/uploads/filename.jpg
        image: `/uploads/${fileName}`,
      });
    } catch (err) {
      console.error("Error saving file locally:", err);
      res.status(500);
      throw new Error("Error saving image file locally.");
    }
  } else {
    // --- AWS DEPLOYMENT FLOW (DEV-AWS or PROD-AWS) ---
    const bucketName = process.env.AWS_IMAGES_BUCKET_NAME;
    if (!bucketName) {
      res.status(500);
      throw new Error("S3 Bucket name is not configured on the server.");
    }

    // Create a unique key for the S3 object.
    // The "images/" prefix is important because CloudFront uses it for routing.
    const fileKey = `images/${Date.now()}-${req.file.originalname.replace(
      /\s+/g,
      "-"
    )}`;

    // Define the parameters for the S3 upload.
    const params = {
      Bucket: bucketName,
      Key: fileKey,
      Body: req.file.buffer, // The file content from memory.
      ContentType: req.file.mimetype,
    };

    try {
      // Upload the file to S3.
      const data = await s3.upload(params).promise();
      console.log("Image uploaded to S3:", data.Location);

      // IMPORTANT: Respond with the CloudFront path, not the raw S3 URL.
      // This ensures the request goes through the CDN.
      // e.g., /images/1678886400000-my-image.jpg
      res.status(200).send({
        message: "Image uploaded successfully",
        image: `/${fileKey}`,
      });
    } catch (err) {
      console.error("Error uploading image to S3:", err);
      res.status(500);
      throw new Error("Failed to upload image.");
    }
  }
});

export default router;
