# Apollo360 iOS

## Validic + HealthKit Setup

### Info.plist keys
Add these keys in `Apollo360/Info.plist`:
- `VALIDIC_URL_V2` (default: `https://api.v2.validic.com`)
- `VALIDIC_ORG_ID` (preferred org id for mobile session)
- `VALIDIC_ORGANIZATION_ID` (fallback org id)
- `VALIDIC_TOKEN` (fallback direct Validic API token; backend-first flow is preferred)
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`

### Entitlements
`Apollo360/Apollo360.entitlements` includes:
- `com.apple.developer.healthkit = true`
- `com.apple.developer.healthkit.background-delivery = true`

### Runtime flow
1. After login, Dashboard launch triggers `ValidicBootstrapService`.
2. App calls backend endpoint `GET /api/v1/validic/user?uid=<rpmTokenOrPatientId>` with bearer auth.
3. If backend mapping is unavailable, app falls back to Validic v2 direct create/get using plist config.
4. Session starts with:
   - `userID = validicUser.id`
   - `organizationID = VALIDIC_ORG_ID` (or `VALIDIC_ORGANIZATION_ID`)
   - `accessToken = validicUser.mobile.token`
5. Device Sync screen:
   - `+ Device` and `Manage` open `validicUser.marketplace.url`
   - `Sync with Apple Health` sets subscriptions and fetches 30-day summary/workout history.

### Manual test checklist
- Login -> Dashboard loads -> Validic bootstrap starts (check logs).
- Open Sync Devices -> marketplace opens from `+ Device` or `Manage your devices`.
- Tap `Sync with Apple Health` -> HealthKit permission prompt appears and sync completes.
- Relaunch app -> cached Validic user is reused and session bootstrap runs again.

### Notes
- Keep sensitive token logic on backend. `VALIDIC_TOKEN` exists only as fallback.
- If `InformCore`/`InformHealthKit` SDKs are present, fill the SDK hook points in:
  - `Apollo360/Features/DeviceSync/Services/ValidicSessionManager.swift`
  - `Apollo360/Features/DeviceSync/Services/AppleHealthSyncManager.swift`
