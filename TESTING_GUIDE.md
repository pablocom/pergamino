# Pergamino Android App - Testing Guide

## Prerequisites

Before testing, ensure you have:

1. **Android Studio** (Hedgehog 2023.1.1 or later)
   - Download: https://developer.android.com/studio

2. **JDK 17**
   - Android Studio usually includes this, or install separately

3. **Android Emulator** or **Physical Device**
   - Emulator: API 26+ (Android 8.0+)
   - Device: Enable USB debugging in Developer Options

## Step 1: Open the Project

1. Launch Android Studio
2. Select **"Open"** from the welcome screen
3. Navigate to: `C:\src\pergamino\android`
4. Click **OK**

Android Studio will:
- Index the project
- Download dependencies (this may take a few minutes)
- Sync Gradle files

**Wait for "Gradle sync finished" in the status bar.**

## Step 2: Create an Android Emulator (if needed)

If you don't have a device/emulator:

1. In Android Studio, go to: **Tools → Device Manager**
2. Click **Create Device**
3. Select a phone (e.g., Pixel 6)
4. Click **Next**
5. Download a system image (API 34 recommended)
6. Click **Next** → **Finish**

## Step 3: Build the Project

Before running, let's build to catch any issues:

1. In Android Studio, go to: **Build → Make Project**
2. Wait for build to complete (check bottom status bar)
3. Fix any errors if they appear (should be none)

Or via command line:
```bash
cd C:\src\pergamino\android
gradlew.bat build
```

## Step 4: Run the App

1. In Android Studio toolbar, select your device/emulator
2. Click the green **Run** button (▶️) or press **Shift+F10**
3. Wait for the app to launch

**Expected:** You should see the "Enter your email" screen with:
- Title: "Enter your email"
- Subtitle explaining verification
- Email input field
- Continue button (disabled initially)

## Step 5: Test the Email Authentication Flow

### Test Case 1: Email Validation

Try entering these emails to test validation:

| Email Input | Expected Result |
|-------------|----------------|
| *(empty)* | Continue button disabled |
| `invalid` | Error: "Please enter a valid email address" |
| `test@` | Error: "Please enter a valid email address" |
| `@example.com` | Error: "Please enter a valid email address" |
| `test@example.com` | ✅ No error, Continue button enabled |

### Test Case 2: Submit Email

1. Enter a valid email: `test@example.com`
2. Tap **Continue**
3. Wait for loading spinner (1 second)

**Expected:** Navigation to "Check your email" screen showing:
- Email icon
- "Check your email" title
- Your email address: `test@example.com`
- Instructions about clicking the link
- "Resend email" button (disabled for 60 seconds)
- "Use a different email" button

## Step 6: Get Verification Token from Logcat

The fake backend logs verification tokens to Logcat. Let's retrieve it:

### In Android Studio:

1. Go to: **View → Tool Windows → Logcat** (or click **Logcat** tab at bottom)
2. In the filter box, type: `FakeAuthRemoteDataSource`
3. Look for output like this:

```
============================================================
Verification email sent to: test@example.com
Deep link for testing: pergamino://verify?token=abc-123-def-456
Test with: adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=abc-123-def-456"
============================================================
```

4. **Copy the token** (everything after `token=`)

## Step 7: Simulate Clicking the Email Link

Now we'll simulate clicking the verification link in the email.

### Method 1: Using Android Studio Terminal

1. In Android Studio, open the **Terminal** tab (bottom)
2. Run this command (replace `YOUR_TOKEN` with the actual token):

```bash
adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=YOUR_TOKEN"
```

Example:
```bash
adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=abc-123-def-456"
```

### Method 2: Using Command Prompt

1. Open Command Prompt
2. Make sure ADB is in your PATH, or navigate to:
   ```
   C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools\
   ```
3. Run the same command above

### Method 3: Using Device Browser (Physical Device Only)

1. On your physical Android device, open Chrome
2. Type in the address bar: `pergamino://verify?token=YOUR_TOKEN`
3. Press Enter

**Expected Result:**
- The app briefly shows "You're all set!" screen
- Then navigates to the success screen with:
  - Green checkmark icon
  - "You're all set!" message
  - "Your email has been verified successfully"
  - "Continue to Pergamino" button

## Step 8: Test Resend Functionality

1. Start the app fresh (close and reopen)
2. Enter email: `test@example.com`
3. Tap **Continue**
4. On the verification pending screen:
   - Wait 60 seconds (watch the countdown)
   - Once countdown reaches 0, tap **Resend email**
   - Check Logcat for a new token
   - Button should be disabled again for 60 seconds

## Step 9: Test "Change Email" Flow

1. On the verification pending screen
2. Tap **"Use a different email"**
3. **Expected:** Navigate back to email entry screen
4. Enter a different email and continue

## Step 10: Run Automated Tests

### Unit Tests (Recommended - Fast!)

In Android Studio:
1. Right-click on `feature-auth/src/test` in the Project panel
2. Select **"Run Tests in 'test'"**

Or via command line:
```bash
cd C:\src\pergamino\android
gradlew.bat test
```

**Expected:** All tests pass ✅
- EmailTest: 10/10 tests passing
- RequestEmailVerificationUseCaseTest: 5/5 tests passing
- EmailEntryViewModelTest: 12/12 tests passing

**Total: 27 passing tests**

### View Test Report

After running tests:
1. Navigate to: `feature-auth/build/reports/tests/testDebugUnitTest/index.html`
2. Open in a browser to see detailed test report

## Troubleshooting

### Problem: "Gradle sync failed"

**Solution:**
1. Go to: **File → Invalidate Caches → Invalidate and Restart**
2. Wait for Android Studio to restart
3. Try syncing again

### Problem: "SDK not found"

**Solution:**
1. Go to: **File → Project Structure → SDK Location**
2. Set Android SDK location (usually: `C:\Users\YourName\AppData\Local\Android\Sdk`)
3. Click **Apply** → **OK**

### Problem: "Cannot find ADB"

**Solution:**
Add ADB to your PATH:
1. Add to environment variables:
   ```
   C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools
   ```
2. Or use full path:
   ```bash
   C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=YOUR_TOKEN"
   ```

### Problem: "App crashes on launch"

**Solution:**
1. Check Logcat for error messages (filter by "Error" or "AndroidRuntime")
2. Look for stack traces
3. Common issues:
   - Missing dependencies → Clean and rebuild
   - Hilt not initialized → Check Application class has @HiltAndroidApp

### Problem: "Deep link doesn't work"

**Solution:**
1. Verify the app is running in the foreground
2. Check the token is correct (no extra spaces/quotes)
3. Ensure the command has proper quotes around the URL:
   ```bash
   adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=abc-123"
   ```

### Problem: "Tests fail to compile"

**Solution:**
1. Check that test dependencies are synced
2. Run: **File → Sync Project with Gradle Files**
3. Clean build: `gradlew.bat clean test`

## Advanced Testing

### Test with Proguard/R8 (Release Build)

1. Generate signed release APK:
   - **Build → Generate Signed Bundle / APK**
   - Follow the wizard
2. Install on device/emulator
3. Test authentication flow
4. Verify no crashes from code shrinking

### Test Rotation/Configuration Changes

1. Run the app
2. Enter email on entry screen
3. Rotate device (Ctrl+F11 in emulator)
4. **Expected:** Email text preserved
5. Submit email → rotate on pending screen
6. **Expected:** State preserved, countdown continues

### Test Background/Foreground

1. Submit email verification
2. Press Home button (minimize app)
3. Wait 10 seconds
4. Reopen app
5. **Expected:** Still on verification pending screen
6. Simulate deep link
7. **Expected:** Verification completes successfully

### Memory Leak Testing

Use Android Studio Profiler:
1. **View → Tool Windows → Profiler**
2. Run app and navigate through screens
3. Monitor memory usage
4. Look for steady increases (indicates leaks)

## Success Criteria

✅ **All tests pass** when you:

1. Build project without errors
2. Launch app successfully
3. Enter valid email and see proper validation
4. Submit email and navigate to pending screen
5. Find verification token in Logcat
6. Simulate deep link and complete authentication
7. Run 27 unit tests - all pass
8. Test resend functionality with countdown
9. Test "change email" navigation
10. Rotate device and verify state preservation

## Next Steps

After successful testing:

1. **Explore the code:**
   - Domain layer: `feature-auth/domain`
   - ViewModels: `feature-auth/presentation`
   - Tests: `feature-auth/src/test`

2. **Customize:**
   - Update colors in `core-ui/theme/Color.kt`
   - Modify copy in screen composables
   - Add your logo to `app/res/mipmap`

3. **Integrate real backend:**
   - Create `AuthRemoteDataSourceImpl` with Retrofit
   - Update `AuthModule` to bind real implementation
   - Add API base URL configuration

## Questions?

If you encounter issues:
1. Check Logcat for error messages
2. Review this guide's troubleshooting section
3. Verify prerequisites are installed correctly
4. Check that emulator/device is running Android 8.0+

Happy testing! 🚀
