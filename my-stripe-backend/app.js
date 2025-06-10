const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config({ path: '../.env' });
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
app.use(cors({
  origin: 'http://192.168.0.191:3000'  // Adjust to match your frontend's URL
}));
app.use(bodyParser.json());

// Create Payment Intent Endpoint
app.post('/create-payment-intent', async (req, res) => {
    console.log("Received body:", req.body); // Add this line

  try {
    const { amount, applicantId, shiftId } = req.body;  // amount in cents, applicantId, and shiftId

    if (!amount || !applicantId || !shiftId) {
      return res.status(400).send({
        error: 'Amount, applicantId, and shiftId are required.',
      });
    }

    // Create the Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'myr', // Change the currency if needed
      metadata: {
        applicantId: applicantId,
        shiftId: shiftId,
      },
    });

    // Send the client secret to the client (Flutter app)
    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error("Payment Intent creation failed:", error);
    res.status(500).send({
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

app.get('/', (req, res) => {
  res.send('Hello, World!');
});
