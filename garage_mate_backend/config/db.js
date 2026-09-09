const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    const connection = await mongoose.connect(process.env.MONGODB_URI,
      {
         family: 4,
      serverSelectionTimeoutMS: 15000,
      connectTimeoutMS: 10000,
      }
    );

    console.log(`MongoDB connected: ${connection.connection.host}`);
  } catch (error) {
    console.error("MongoDB connection failed:", error.message);
    process.exit(1);
  }
};

module.exports = connectDB;