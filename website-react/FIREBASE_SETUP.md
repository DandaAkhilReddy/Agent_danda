# Firebase Setup Instructions for AgentChains.ai

## 🔥 Firebase Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name it "AgentChains" (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create Project"

### Step 2: Enable Firestore Database

1. In your Firebase project, click "Firestore Database" in the left sidebar
2. Click "Create database"
3. **Choose**: Start in **production mode** (we'll add security rules later)
4. Select your preferred location (e.g., us-central)
5. Click "Enable"

### Step 3: Get Firebase Credentials

1. Go to Project Settings (gear icon in sidebar)
2. Scroll to "Your apps" section
3. Click the **</> (Web)** icon to add a web app
4. Register app with nickname "AgentChains Website"
5. **Copy** the firebaseConfig object values

### Step 4: Configure Environment Variables

1. Copy `.env.local.example` to `.env.local`:
   ```bash
   cp .env.local.example .env.local
   ```

2. Open `.env.local` and paste your Firebase credentials:
   ```
   NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSy...
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=agentchains.firebaseapp.com
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=agentchains
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=agentchains.appspot.com
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789012
   NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789012:web:abc123
   ```

3. Restart the dev server:
   ```bash
   npm run dev
   ```

### Step 5: Configure Firestore Security Rules

1. Go to Firestore Database > Rules
2. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow anyone to write to waitlist-submissions (for form)
    match /waitlist-submissions/{document} {
      allow create: if request.time < timestamp.date(2026, 1, 1); // Expires Jan 2026
      allow read: if false; // No public reads
    }

    // Only allow admin to read (you can add Firebase Auth later)
    match /{document=**} {
      allow read, write: if false; // Locked down for now
    }
  }
}
```

3. Click "Publish"

---

## 📊 Admin Dashboard Access

### Access the Dashboard:
1. Navigate to: **http://localhost:3000/admin**
2. **Password**: `AgentChains2025` (change this in `app/admin/page.tsx`)

### Features:
- ✅ View all waitlist submissions
- ✅ Real-time statistics (total, ChatGPT usage, avg time)
- ✅ **Export to Excel** (.xlsx file)
- ✅ Refresh data button
- ✅ Password protection

### Change Admin Password:
Edit `app/admin/page.tsx` line 24:
```typescript
const ADMIN_PASSWORD = 'YourSecurePassword123' // Change this!
```

---

## 🧪 Testing the Form

### Test Submission:
1. Go to **http://localhost:3000**
2. Scroll to "Join the Waitlist" section
3. Fill out the form with test data
4. Click "Join the Waitlist 🚀"
5. Check the console for: `Form submitted successfully to Firebase`

### Verify in Firebase:
1. Go to Firebase Console > Firestore Database
2. You should see collection: `waitlist-submissions`
3. Click to view the submitted document

### Export to Excel:
1. Go to **http://localhost:3000/admin**
2. Enter password: `AgentChains2025`
3. Click "Export to Excel 📊"
4. File downloads as: `AgentChains_Waitlist_YYYY-MM-DD.xlsx`

---

## 📁 Firebase Data Structure

Each submission is saved with this structure:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "usingChatGPT": "yes-all-the-time",
  "struggles": [
    "Taking too long to reply",
    "Want to sound more professional"
  ],
  "strugglesOther": "Sometimes forget to respond",
  "apps": [
    "WhatsApp",
    "iMessage",
    "LinkedIn"
  ],
  "appsOther": "",
  "ideas": "Would love to see custom tone training!",
  "timeSpent": "1-2hours",
  "submittedAt": "2025-01-15T12:34:56.789Z",
  "timestamp": Firebase ServerTimestamp
}
```

---

## 🔒 Security Best Practices

1. **Never commit `.env.local`** to Git (already in `.gitignore`)
2. **Change the admin password** in production
3. **Add Firebase Authentication** for better admin security
4. **Enable reCAPTCHA** to prevent spam submissions
5. **Set up rate limiting** in Firestore rules
6. **Monitor usage** in Firebase Console

---

## 🚀 Deployment Notes

When deploying to production (Vercel, Azure, etc.):

1. Add environment variables in your hosting platform
2. Update Firestore security rules for production
3. Consider adding Firebase Authentication
4. Set up monitoring and alerts

---

## ❓ Troubleshooting

### Error: "Missing or insufficient permissions"
- Check Firestore Security Rules
- Ensure you published the rules

### Error: "Firebase: Firebase App named '[DEFAULT]' already exists"
- This is normal, the code handles it
- No action needed

### Data not appearing in admin?
- Check Firebase Console > Firestore to verify data exists
- Try refreshing the admin page
- Check browser console for errors

### Excel export not working?
- Ensure you have submissions in the database
- Check browser console for errors
- Try refreshing and re-exporting

---

## 📞 Need Help?

Check out:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)
