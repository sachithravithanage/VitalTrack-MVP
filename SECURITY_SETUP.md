# Security Setup Required

The app now uses a safer auth flow, but these backend items are required to make it production-grade:

1. Deploy the Firestore rules in [firestore.rules](firestore.rules).
2. Enable Firebase Auth email verification for the project.
3. Add a trusted backend for role assignment. Use Firebase custom claims for `role` instead of trusting the `users/{uid}.role` field from the client.
4. Move caretaker linking and unlinking into Cloud Functions or another trusted backend so the client does not write both sides of the relationship directly.
5. If you want MFA beyond email verification, add Firebase MFA or a server-managed OTP flow. Do not keep client-generated codes in Firestore.
6. Enable Firebase App Check to reduce abuse from non-genuine clients.
7. Add account-deletion cleanup in a backend function so linked users, episodes, and logs are removed consistently.

Deployment order:

- Deploy Firestore rules first.
- Add custom claims and Cloud Functions next.
- Then test sign-up, email verification, login, and profile completion in Chrome.
