# Signing and notarizing Visage

This produces a Visage DMG that opens on any Mac without warnings and where Face Unlock can store the Mac password behind Touch ID — the same way the downloadable build of any Mac app outside the App Store is made.

You need:

- A Mac with **Xcode 26** or later.
- A **paid Apple Developer Program** membership, as the **Account Holder** (only the Account Holder can create a Developer ID certificate).

Nothing here needs anyone else's password. Everything stays on your Mac.

## 1. One-time setup

1. **Add your account to Xcode.** Xcode → Settings → Accounts → **+** → Apple ID, then sign in.
2. **Create the Developer ID certificate.** In the same window select your team → **Manage Certificates…** → **+** → **Developer ID Application** → Done.
3. **Find your Team ID.** It's the 10-character ID shown for your team in Accounts, or under Membership details on developer.apple.com/account.
4. **Create an app-specific password** at [account.apple.com](https://account.apple.com) → Sign-In and Security → App-Specific Passwords. Name it "Visage notarization".
5. **Save notarization credentials** in Terminal (it asks for the app-specific password; it's stored in your keychain):

   ```bash
   xcrun notarytool store-credentials visage-notary --apple-id YOUR_APPLE_ID_EMAIL --team-id YOUR_TEAM_ID
   ```

## 2. Build the DMG

Unzip the project, then in Terminal:

```bash
cd path/to/Visage
VISAGE_TEAM=YOUR_TEAM_ID VISAGE_NOTARY_PROFILE=visage-notary ./scripts/make-dmg.sh
```

It archives a universal app, exports it with Developer ID, packages the DMG, signs it, sends it to Apple's automatic notary service (usually a few minutes, no human review), and staples the ticket. The last lines should include `source=Notarized Developer ID`.

The finished file is `dist/Visage-1.1.dmg`. Send that back.

## If something fails

- **"… app identifier com.cdwburhan.visage is not available"** — the bundle ID is taken by another team. Rerun with a different one:
  `VISAGE_BUNDLE_ID=com.cdwburhan.visage.app VISAGE_TEAM=… VISAGE_NOTARY_PROFILE=visage-notary ./scripts/make-dmg.sh`
- **"No Developer ID Application certificate"** — repeat step 1.2 with the Account Holder's Apple ID.
- **"Your team has no devices…"** — open `Visage.xcodeproj` in Xcode once, choose the Visage target → Signing & Capabilities → pick your team, and click **Register Device** if shown. Then rerun the command.
- **Notarization not accepted** — the script prints Apple's log; send the full Terminal output.
- Build errors are logged in `build/xcodebuild.log`.
