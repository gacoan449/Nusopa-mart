# Nusopa.Mart Go-Live Security

1. Create the administrator in Firebase Authentication using the administrator email/password chosen by the owner.
2. After the Firebase Auth user exists, create users/UID with role ADMIN.
3. Do not put an administrator password in Flutter, GitHub, Firestore documents, or APK assets.
4. Create seller profiles only through an authorized admin/trusted backend by setting users/UID role to SELLER and stores/UID.
5. Deploy the checked-in Firestore and Storage rules before production: firebase deploy --only firestore:rules,storage
6. Payment verification, final settlement, wallet credit, and withdrawal approval remain admin/trusted operations. The client must never be authoritative for money movement.

The app contains no embedded production password. This prevents an APK decompile or repository leak from exposing the administrator account.
