# Apollo360 iOS

## Validic + HealthKit Setup

### Config keys
Add these keys in [Info.plist](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Info.plist):
- `PP_BASE_URL`
  Default in this repo: `https://doctor.ioapollo.com`
- `VALIDIC_URL_V2`
  Default Validic v2 base: `https://api.v2.validic.com`
- `ORGANISATION_ID`
  Your Validic organization id. This is required for:
  - `POST /organizations/{org_id}/users?token=...`
  - `GET /organizations/{org_id}/users/{uid}?token=...`
- `VALIDIC_TOKEN`
  Your Validic API token used for direct Validic provisioning in this flow

### HealthKit setup
[Apollo360.entitlements](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Apollo360.entitlements) already includes:
- `com.apple.developer.healthkit = true`
- `com.apple.developer.healthkit.background-delivery = true`

[Info.plist](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Info.plist) already includes:
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`

In Xcode, confirm:
1. Signing & Capabilities -> HealthKit is enabled.
2. Background delivery for HealthKit is enabled.
3. The target is linked with the Validic iOS SDK modules used in [ApolloSyncService.swift](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Features/DeviceSync/Services/ApolloSyncService.swift):
   - `ValidicCore`
   - `ValidicHealthKit`

### Native flow in this repo
The SwiftUI Device Sync implementation matches the React Native flow:
1. Read Apollo patient username from the current session.
2. Base64-encode it when needed.
3. Call Apollo username check:
   `GET /api/apollo-api/register-member/{encodedPatientUsername}/YXBvbGxvdHJhbnNhY3Rpb25rZXk=`
4. If `return_code == "400"`, base64-encode `patient_id` and `patient_key`.
5. Call Apollo RPM handshake:
   `GET /api/handshaking/register-rpm-user/{deviceId}/{patientId}/{patientKey}/HealthKit/{deviceName}`
6. Use handshake `token` as the Validic `uid`.
7. Try to create the Validic user first:
   `POST /organizations/{org_id}/users?token={VALIDIC_TOKEN}`
   Body: `{ "uid": "<handshakeToken>" }`
8. If create fails, fetch the existing Validic user:
   `GET /organizations/{org_id}/users/{uid}?token={VALIDIC_TOKEN}`
9. Start the Validic mobile session with:
   - `validicUser.id`
   - `validicUser.mobile.token`
   - `ORGANISATION_ID`
10. Observe HealthKit subscriptions, set required subscriptions, and fetch 30 days of history.
11. Refresh connected sources by calling the same Validic `GET /users/{uid}` endpoint later.

### Main files
- Service: [ApolloSyncService.swift](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Features/DeviceSync/Services/ApolloSyncService.swift)
- View model: [HealthSyncViewModel.swift](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Features/DeviceSync/ViewModels/HealthSyncViewModel.swift)
- SwiftUI screen: [DeviceSyncView.swift](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Features/DeviceSync/Views/DeviceSyncView.swift)
- UIKit sample bridge: [HealthSyncViewController.swift](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Features/DeviceSync/Views/HealthSyncViewController.swift)

### Manual verification
1. Log in so [SessionManager.swift](/Users/amitsinha/Devzign/iOS%20Native/Apollo360/Apollo360/Core/Session/SessionManager.swift) has a username.
2. Open Sync Devices.
3. Tap `Sync with Apple Health`.
4. Confirm HealthKit permission is granted.
5. Confirm the screen now shows:
   - Validic user id
   - Validic uid
   - timezone
   - status
   - connected sources
6. Tap `Manage your devices` to open `marketplace.url`.
7. Tap `Refresh device status` to refetch `sources` from Validic.
