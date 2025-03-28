const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors()); // Enables CORS to allow requests from other origins (like your Flutter app)

// Replace with your MongoDB Atlas URI
require('dotenv').config();
const uri = process.env.MONGODB_URI;
const client = new MongoClient(uri);

// MongoDB Database Reference
let db;

async function connectToDatabase() {
  try {
    if (!client.topology || !client.topology.isConnected()) {
      console.log('Connecting to MongoDB...');
      await client.connect();
      db = client.db('sample_book'); // Replace with your database name
      console.log('Connected');
    }
  } catch (err) {
    console.error('Error connecting to MongoDB:', err);
    process.exit(1); // Exit the process if connection fails
  }
}

// Call the function to connect at server startup
connectToDatabase();

app.post('/bookmark', async (req, res) => {
  try {
    const bookmarkCollection = db.collection('bookmark');

    // Access data from the request body:
    const newBookmark = req.body; // Assuming your data is sent as JSON

    // Validate the data (optional but recommended):
    // You can add checks to ensure required fields are present and have valid formats.

    // Add the new bookmark to the collection:
    const result = await bookmarkCollection.insertOne(newBookmark);

    // Respond with success or error:
    if (result.insertedId) {
      res.json({ message: 'Bookmark added successfully!', bookmarkId: result.insertedId });
    } else {
      res.status(500).send('Error adding bookmark');
    }
  } catch (err) {
    console.error(err);
    res.status(500).send('Error adding bookmark');
  }
});
// app.post('/bookmark', async (req, res) => {
//   try {
//     const bookmarkCollection = db.collection('bookmark'); // Replace with your collection name
//     const bookmark = await bookmarkCollection.find({}).toArray(); // Fetch all documents in the collection
//     res.json(bookmark); // Return the books as a JSON response
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Error fetching books'); // Handle errors
//   }
// });

app.get('/bookmark', async (req, res) => {
  try {
    const bookmarkCollection = db.collection('bookmark');
    const bookmark = await bookmarkCollection.find({}).toArray();
    res.json(bookmark);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching books');
  }
});

app.get('/books', async (req, res) => {
  try {
    const booksCollection = db.collection('table_book'); // 
    const books = await booksCollection.find({}).toArray(); // Fetch dokumen dari collection
    res.json(books); // gunakan response JSON untuk nama ebook
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching books');
  }
});

const PORT = process.env.PORT || 3000; // Use an environment variable for the port or default to 3000
// app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on http://0.0.0.0:${PORT}`));




