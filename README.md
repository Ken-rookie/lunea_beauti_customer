# Lunéa Beauti Customer App

A Flutter customer-side beauty shopping app designed for Android phones. The
interface uses soft blush, rose and beige colors and follows the supplied
Lunéa Beauti visual references.

## Run the app

```sh
flutter pub get
flutter run
```

The welcome screen leads to sign in or account creation. For this student
project, sign-in and account creation are local demo flows: any non-empty email
or phone number and a password of at least six characters can continue.

## Included screens

Welcome, login, sign up, home, shop/category filtering, product details, cart,
checkout, demo payment, order success, order list/details, favorites and profile.
Product data and cart/order state are stored locally in memory while the app is
running. Product photos load from remote image URLs and have local color/icon
fallbacks.

No Supabase or payment provider is connected. The payment screen is a UI
placeholder; online payment integration should be added later through a secure
backend, never with a provider secret in the Flutter app.
