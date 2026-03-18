# VitalTrack - Feature Implementation Guide

## Implemented Features

### 1. Email Verification Feature

#### Backend Implementation:

- **Email Service** (`backend/src/services/emailService.js`):
  - `sendOtpEmail()` - Sends 6-digit OTP to user email
  - `sendCaregiverLinkingEmail()` - Notifies patient when caregiver is linked
  - `sendMedicalAlertEmail()` - Sends alerts to caregivers
  - Uses SendGrid for email delivery (configure SENDGRID_API_KEY env var)

#### API Endpoints:

- **POST /api/v1/auth/send-otp** - Send OTP to email or phone
  - Request: `{ credential: "email@example.com", type: "email" }`
  - Response includes OTP in development mode
- **POST /api/v1/auth/verify-otp** - Verify OTP code
  - Request: `{ credential: "email@example.com", otp: "123456" }`
- **POST /api/v1/users/verify-email** - Request email verification
  - Sends OTP to user's email
- **POST /api/v1/users/confirm-email-verification** - Confirm email with OTP
  - Request: `{ otp: "123456" }`
  - Marks email as verified in database

#### Frontend Implementation:

- **Flutter UI** in `frontend/lib/screens/profile_hotspot.dart`:
  - Email field in profile
  - "Verify Email" button that:
    1. Updates profile with new email address
    2. Sends OTP to email
    3. Shows OTP verification screen
    4. Marks email as verified on success
  - Email verification status displayed (Verified/Not Verified)

#### How It Works:

1. User enters email in profile
2. Clicks "Verify Email" button
3. OTP is sent to email (6-digit code)
4. User enters code in verification dialog
5. On successful verification:
   - Email is marked as verified in database
   - User can login with email
   - Profile shows verified status

---

### 2. Email Login

#### Backend Implementation:

- **loginUser()** function in `authService.js`:
  - Detects if credential is email (contains @) or phone
  - For email: queries users collection by email field (case-insensitive)
  - For phone: queries users collection by phone field
  - Validates password against stored hash
  - Returns user profile and custom Firebase token

#### Frontend:

- **Existing login flow** supports both email and phone
- User can login with either email (if verified) or phone number

---

### 3. Caregiver Linking Code Feature

#### Backend Implementation:

- **generateLinkCode()** - Generates 6-character alphanumeric code
  - Code stored in Firestore with 7-day expiry
  - One-time use only
- **useLinkCode()** - Validates and uses code to link caregiver to patient
  - Checks code exists, not used, not expired
  - Gets patient and caregiver info
  - Creates relationship document
  - Updates patients and caregivers collections
  - Sends email notification to patient
  - Marks code as used

#### API Endpoints:

- **POST /api/v1/relationships/link-code** - Generate code (patient only)
  - Response: `{ code: "ABC123" }`
- **POST /api/v1/relationships/add-patient** - Use code (caregiver only)
  - Request: `{ code: "ABC123", disease?: "dengue" }`

#### Frontend Implementation:

- **Generate Code** (Patient):
  - Button in profile: "Generate 6 Digit Code"
  - Shows code in dialog with large font
  - Copy button to copy code to clipboard
  - Toast notification on copy
- **Enter Code** (Caregiver):
  - Button in profile: "Enter Patient Code"
  - Dialog with 6-digit code input field
  - Link button to establish relationship
  - Error handling for invalid/expired codes

#### How It Works:

1. **Patient**: Generates code, shares with caregiver (copy button provided)
2. **Caregiver**: Enters code through UI or manually
3. System validates and creates relationship
4. Patient receives email notification
5. Both users can now see each other's data

---

### 4. Data Sharing Between Patient and Caregiver

#### Implementation Details:

**Patient can:**

- View own medical records
- See list of linked caregivers
- Remove caregiver relationships

**Caregiver can:**

- View records of linked patients (via patientId parameter)
- Add medical records for their linked patients
- View hotspot data for linked patients
- See patient list

#### Access Control:

- **Authorization checks** in API endpoints:
  - Patients can only access their own data
  - Caregivers can only access linked patients' data
  - Medical records require either:
    - User is the patient, OR
    - User is a caregiver linked to the patient

#### Data Sharing Implementation:

```javascript
// In records API:
if (userProfile.role === "caregiver") {
  // Check if caregiver is linked to patient
  const isLinked = await relationshipService.isCaregiverLinkedToPatient(
    patientId,
    caregiverId,
  );
  if (!isLinked) throw AuthenticationError("Not authorized");
}
```

**Medical Records Shared:**

- Temperature
- Symptoms (body pain, vomiting, headache, rash)
- Fluid intake/output
- Urine color
- Disease type
- Notes
- Creation dates

**Hotspot Data Shared:**

- Hometown
- Workplace
- Places visited in last 3 days

---

## Environment Configuration

Required environment variables for email functionality:

```bash
# SendGrid
SENDGRID_API_KEY=your_sendgrid_api_key
NOTIFICATION_EMAIL_FROM=noreply@vitaltrack.com

# Firebase (already configured)
FIREBASE_PROJECT_ID=vitaltrack-vcode
NODE_ENV=development
```

---

## Testing the Features

### Email Verification Flow:

```
1. Create account (with email optional)
2. In profile, enter email address
3. Click "Verify Email" button
4. Check email for 6-digit OTP
5. Enter OTP in verification dialog
6. See "Email Verified" status
7. Try logging in with email address
```

### Caregiver Linking Flow:

```
PATIENT:
1. Go to Profile
2. Click "Generate 6 Digit Code"
3. Copy code using copy button

CAREGIVER:
1. Go to Profile
2. Click "Enter Patient Code"
3. Paste code (received from patient)
4. Click "Link"
5. Receive success notification

BOTH:
6. Patient sees caregiver in "Caregivers List"
7. Caregiver sees patient in "My Patients"
8. Caregiver can now see patient's medical records
```

### Data Sharing Flow:

```
PATIENT:
1. Add medical record
2. Invite caregiver using code

CAREGIVER:
1. Link patient using code
2. Go to Records
3. Select patient from dropdown
4. See patient's medical records
5. Can add/view/update records for this patient

PATIENT:
6. Can see caregiver's data contributions
```

---

## API Summary

### Authentication Endpoints

- `POST /api/v1/auth/send-otp` - Send OTP
- `POST /api/v1/auth/verify-otp` - Verify OTP
- `POST /api/v1/auth/signup` - Register
- `POST /api/v1/auth/login` - Login (email/phone)

### User Profile Endpoints

- `GET /api/v1/users/profile` - Get profile
- `PUT /api/v1/users/profile` - Update profile
- `POST /api/v1/users/verify-email` - Request email verification
- `POST /api/v1/users/confirm-email-verification` - Confirm email

### Relationship Endpoints

- `POST /api/v1/relationships/link-code` - Generate code
- `POST /api/v1/relationships/add-patient` - Use code
- `GET /api/v1/relationships/patients` - Get linked patients (caregiver)
- `GET /api/v1/relationships/caregivers` - Get linked caregivers (patient)
- `DELETE /api/v1/relationships/:userId` - Remove relationship

### Records Endpoints

- `POST /api/v1/records` - Create record
- `GET /api/v1/records` - List records (with patientId for caregivers)
- `GET /api/v1/records/:recordId` - Get specific record
- `PUT /api/v1/records/:recordId` - Update record
- `DELETE /api/v1/records/:recordId` - Delete record
- `GET /api/v1/records/stats/:patientId` - Get record statistics
- `GET /api/v1/records/export/pdf` - Export records as PDF

---

## Implementation Status

✅ Email verification OTP sending
✅ Email OTP code verification
✅ Email login support
✅ Profile email field
✅ Email verification status
✅ Caregiver linking code generation
✅ Copy code functionality
✅ Code entry dialog for caregivers
✅ Email notifications on caregiver link
✅ Data sharing between patient and caregiver
✅ Authorization checks for data access
✅ Localization strings for all features

---

## Files Modified/Created

### Backend:

- `backend/src/services/emailService.js` (NEW)
- `backend/src/api/auth.js` (MODIFIED - added email sending)
- `backend/src/api/users.js` (MODIFIED - added email sending)
- `backend/src/services/relationshipService.js` (MODIFIED - added email notification)
- `backend/src/services/authService.js` (already had email verification)

### Frontend:

- `frontend/lib/screens/profile_hotspot.dart` (MODIFIED - added UI for linking)
- `frontend/lib/app/localization.dart` (MODIFIED - added translation strings)

---

## Notes

1. **Email Sending**: Ensure SENDGRID_API_KEY is set. In development mode without the key, OTP is still returned in API responses.

2. **Code Format**: Linking codes are 6 alphanumeric characters, generated randomly.

3. **Code Expiry**: Linking codes expire after 7 days and can only be used once.

4. **Email Verification**: Must be completed to mark email as verified. Users can still use email for login even if not verified (only verified flag is different).

5. **Data Access**: All data access is controlled through relationship checks. Ensure proper authorization before returning any patient data.

6. **Notifications**: Email notifications are sent but don't block the main operation if they fail.
