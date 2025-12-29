# Ecommerce Flutter App

A comprehensive ecommerce mobile application built with Flutter and Firebase, featuring a complete shopping experience with admin panel, user authentication, cart management, and order processing.

## 📱 Features

### User Features
- **Home Screen**: Special offers, categories, recommended products
- **Product Catalog**: Browse all products with search, filter, and sort functionality
- **Product Details**: Multiple images, discount badges, add to cart, wishlist
- **Shopping Cart**: Real-time quantity management with +/- controls
- **Wishlist**: Save favorite products
- **Order Management**: Place orders, track status, cancel orders
- **Payment Methods**: Multiple payment options including COD and saved cards
- **Address Management**: Add, edit, and manage shipping addresses
- **User Profile**: Personal information, security settings, order history

### Admin Features
- **Dashboard**: Real-time statistics (categories, products, orders)
- **Product Management**: Add, edit, delete products with multiple images
- **Category Management**: Create and manage product categories
- **Order Management**: View, accept, cancel, and complete orders
- **Special Offers**: Create promotional banners with discounts
- **Promo Codes**: Generate and manage discount codes
- **Delivery Price Management**: Configure delivery fees

## 🏗️ Project Structure

```
lib/
├── admin/                    # Admin panel screens and services
│   ├── admin_home_screen.dart
│   ├── admin_products_screen.dart
│   ├── admin_orders_screen.dart
│   ├── admin_categories_screen.dart
│   ├── admin_special_offers_screen.dart
│   ├── admin_promo_codes_screen.dart
│   └── *_service.dart        # Firestore service classes
│
├── screens/                  # User-facing screens
│   ├── auth/                 # Authentication screens
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── forgot_password_screen.dart
│   │
│   ├── main/                 # Main app screens
│   │   ├── main_navigation_screen.dart
│   │   ├── home_screen.dart
│   │   ├── store_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── wishlist_screen.dart
│   │   ├── product_details_screen.dart
│   │   ├── all_products_screen.dart
│   │   ├── category_products_screen.dart
│   │   ├── order_details_screen.dart
│   │   └── order_success_screen.dart
│   │
│   └── profile/              # Profile and settings
│       ├── profile_screen.dart
│       ├── payment_methods_screen.dart
│       ├── address_management_screen.dart
│       ├── orders_screen.dart
│       └── personal_info_screen.dart
│
├── models/                   # Data models
│   ├── product_model.dart
│   ├── category_model.dart
│   ├── order_model.dart
│   ├── address_model.dart
│   ├── payment_method_model.dart
│   ├── promo_code_model.dart
│   └── special_offer_model.dart
│
├── services/                 # Business logic and data services
│   ├── cart_service.dart     # SQLite cart management
│   ├── order_service.dart    # Firestore order operations
│   ├── wishlist_service.dart # Firestore wishlist operations
│   ├── address_service.dart  # SQLite address management
│   └── payment_method_service.dart
│
├── widgets/                  # Reusable widgets
│   ├── bottom_navigation_bar.dart
│   ├── product_card.dart
│   └── category_item.dart
│
├── constants/                # App constants
│   └── app_colors.dart
│
└── main.dart                 # App entry point
```

## 🔧 Technologies & Dependencies

### Core
- **Flutter SDK**: ^3.8.1
- **Dart**: Latest stable version

### Firebase
- `firebase_core: ^3.6.0` - Firebase initialization
- `firebase_auth: ^5.3.1` - User authentication
- `cloud_firestore: ^5.4.4` - NoSQL database
- `firebase_storage: ^12.3.4` - File storage

### Local Storage
- `sqflite: ^2.3.3+2` - SQLite database for cart and addresses
- `path: ^1.9.0` - Path manipulation
- `path_provider: ^2.1.1` - File system paths

### UI & Design
- `google_fonts: ^6.2.1` - Google Fonts integration
- `flutter_iconpicker: ^4.0.3` - Icon selection
- `image_picker: ^1.1.2` - Image selection from gallery

### Location Services
- `geolocator: ^14.0.2` - GPS location
- `geocoding: ^4.0.0` - Address geocoding
- `intl_phone_field: ^3.2.0` - Phone number input

### Utilities
- `url_launcher: ^6.2.5` - Open URLs
- `share_plus: ^10.1.2` - Share functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ecommerce
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android app: Download `google-services.json` and place it in `android/app/`
   - Add iOS app: Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Set up Firebase Storage

4. **Run the app**
   ```bash
   flutter run
   ```

## 📂 Key Components

### Authentication Flow
- **Entry Point**: `lib/main.dart` - Initializes Firebase and checks auth state
- **Auth Wrapper**: Routes to `LoginScreen` or `MainNavigationScreen` based on auth state
- **Login/Signup**: Email/password authentication with Firebase Auth

### Main Navigation
- **MainNavigationScreen**: Bottom navigation with 5 tabs (Home, Wishlist, Store, Cart, Profile)
- Uses `IndexedStack` to maintain state across tab switches

### Data Models

#### ProductModel
- Supports multiple image URLs (`imageUrls` list)
- Backward compatible with single `imageUrl`
- Includes discount, pricing, stock, category information

#### OrderModel
- Tracks order status (pending, cancelled, complete)
- Stores payment method, shipping address, products
- Calculates totals with discounts and delivery fees

#### SpecialOfferModel
- Banner images with optional image URL
- Discount percentages, badge text, call-to-action buttons

### Services

#### CartService (SQLite)
- Local cart storage for offline support
- Real-time stream updates via `getCartStream()`
- Quantity management with optimistic updates

#### OrderService (Firestore)
- Order CRUD operations
- Status-based collections (pending, cancelled, complete)
- Admin order management

#### WishlistService (Firestore)
- User-specific wishlist management
- Real-time synchronization

### UI Features

#### Product Display
- **Grid/List View Toggle**: Available in Store, All Products, Category Products
- **Discount Badges**: Displayed on product images (top-left)
- **Quantity Controls**: `-` quantity `+` buttons when item is in cart
- **Search & Filter**: Real-time search with category, price, discount filters

#### Cart Management
- Real-time quantity updates
- Out-of-stock validation before checkout
- Promo code application
- Order summary with detailed breakdown

#### Special Offers
- Full-screen banners with gradient overlays
- Text positioned at top-left
- Arrow button at bottom-right
- Navigate to filtered product lists

## 🎨 Design System

### Colors
- **Primary**: `#20B2AA` (Teal)
- **Primary Light**: `#4FD0C7`
- **Primary Dark**: `#1A8E87`
- **Amber**: Used for buttons and highlights
- **Success**: Green (discounts, success messages)
- **Error**: Red (errors, warnings)

### Typography
- **Font Family**: Poppins (via Google Fonts)
- Consistent font weights and sizes across the app

## 🔐 Security

- Firebase Authentication for user management
- Firestore security rules (should be configured)
- SQLite for local sensitive data (cart, addresses)
- Secure payment method storage

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ⚠️ Web (partial support)
- ⚠️ Desktop (not tested)

## 🛠️ Development

### Code Organization
- **Screens**: Organized by feature (auth, main, profile, admin)
- **Services**: Business logic separated from UI
- **Models**: Data structures with `fromMap`/`toMap` serialization
- **Widgets**: Reusable UI components

### State Management
- `StatefulWidget` for local state
- `StreamBuilder` for real-time Firestore updates
- `ValueNotifier` for efficient UI updates
- SQLite streams for cart synchronization

### Best Practices
- Proper error handling with try-catch blocks
- `mounted` checks before `setState`
- Context safety checks for async operations
- Optimistic UI updates for better UX
- Backward compatibility for data models

## 📝 Notes

- Cart uses SQLite for offline support
- Addresses stored locally in SQLite
- Firestore used for products, orders, wishlist
- Image uploads to Firebase Storage
- Real-time updates via Firestore streams
- Admin panel accessible via admin login

## 🔄 Recent Updates

- Multiple image support for products
- Quantity controls in product listings
- Discount badges on product images
- Out-of-stock validation in checkout
- Enhanced special offers design
- Real-time cart synchronization
- Admin order management
- Promo code system
- Address management with location services

## 📄 License

This project is private and not intended for public distribution.

## 👥 Support

For issues or questions, please contact the development team.
