# MERN Stack E-commerce App

## Overview

This is a MERN (MongoDB, Express.js, React.js, Node.js) stack-based e-commerce application.
The app provides a robust platform for users to browse products, add them to the cart, and securely checkout.
Administrators can manage products, orders, and users.
##Tech Stack

### Frontend

- React.js: For building the user interface.
- Redux: State management for consistent data flow.
- Axios: For API requests.
- React Router: Navigation and routing.
- Bootstrap UI: For modern UI components.

### Backend

- Node.js: Runtime environment for server-side JavaScript.
- Express.js: Framework for building the RESTful API.
- MongoDB: Database for storing product, user, and order data.
- Mongoose: For modeling MongoDB data.
- JWT (stored in cookies): For secure authentication.
- Bcrypt.js: For password hashing.

### Payment Integration:

- Paypal: App allows to pay via paypal or credit card

### Environment variables

.env and add the following

- NODE_ENV = development
- PORT = 8080
- MONGO_URI = your mongodb uri
- JWT_SECRET = 'abcd1234'
- PAYPAL_CLIENT_ID = your paypal client id
- PAGINATION_LIMIT = 8

Some update

### Install Dependencies (frontend & backend)

npm install
cd frontend
npm install

Run

### Run frontend (:3000) & backend (:8080)

npm run dev

### Run backend only

npm run server
