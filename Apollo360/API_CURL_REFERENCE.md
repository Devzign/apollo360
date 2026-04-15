# Apollo360 API Curl Reference

This file collects the Apollo and Validic requests visible in the Xcode logs from April 7, 2026, along with the responses that appeared in those logs.

## Apollo APIs

### 2. Register Member Lookup

```bash
curl --request GET \
  --url 'https://a360h.com/apollo-api/register-member/YXRlc3QxNg==/YXBvbGxvdHJhbnNhY3Rpb25rZXk=' \
  --header 'Accept: application/json, text/plain, */*' \
  --header 'Content-Type: application/json' \
  --header 'Cache-Control: no-cache' \
  --header 'Pragma: no-cache' \
  --header 'Expires: 0'
```

Response:

```json
{
  "return_code": "400",
  "message": "Please enter the password you created when registering for a360h.",
  "patient_id": "36666",
  "patient_key": "VRPKJD"
}
```

### 3. Register RPM User

```bash
curl --request GET \
  --url 'https://doctor.ioapollo.com/api/handshaking/register-rpm-user/09C9EB2F-74CA-4C4E-B77F-B47C56D4994B/MzY2NjY=/VlJQS0pE/HealthKit/iPhone14,5?brand=Apple&model=iPhone%2013&osVersion=26.4&osName=iOS' \
  --header 'Accept: application/json, text/plain, */*' \
  --header 'Content-Type: application/json' \
  --header 'Cache-Control: no-cache' \
  --header 'Pragma: no-cache' \
  --header 'Expires: 0'
```

Response:

```json
{
  "success": true,
  "message": "Patient and Apollo Key Combination Found",
  "token": "1a716031fd5010162060fb401dfd74d2"
}
```

### 4. Content Menu JSON

```bash
curl --request GET \
  --url 'https://contentapollo.com/assets/images/menu/io_menu.json' \
  --header 'Accept: application/json, text/plain, */*' \
  --header 'Content-Type: application/json' \
  --header 'Cache-Control: no-cache' \
  --header 'Pragma: no-cache' \
  --header 'Expires: 0'
```

Response seen in logs:

```text
timeout of 10000ms exceeded
```

## Validic User APIs

### 5. Create Validic User

```bash
curl --request POST \
  --url 'https://api.v2.validic.com/organizations/6232413757463e0001806968/users?token=6d2fc49838c2bdc5f63f4a6a4c8cd5be' \
  --header 'Accept: application/json, text/plain, */*' \
  --header 'Content-Type: application/json' \
  --header 'Cache-Control: no-cache' \
  --header 'Pragma: no-cache' \
  --header 'Expires: 0' \
  --data '{
    "uid": "1a716031fd5010162060fb401dfd74d2"
  }'
```

Response:

```json
{
  "errors": {
    "uid": [
      "already exists"
    ]
  }
}
```

### 6. Get Existing Validic User

```bash
curl --request GET \
  --url 'https://api.v2.validic.com/organizations/6232413757463e0001806968/users/1a716031fd5010162060fb401dfd74d2?token=6d2fc49838c2bdc5f63f4a6a4c8cd5be' \
  --header 'Accept: application/json, text/plain, */*' \
  --header 'Content-Type: application/json' \
  --header 'Cache-Control: no-cache' \
  --header 'Pragma: no-cache' \
  --header 'Expires: 0'
```

Response:

```json
{
  "id": "68da3db4afd52600112d8a12",
  "uid": "1a716031fd5010162060fb401dfd74d2",
  "marketplace": {
    "token": "20d668287cf9302fc29aa3b3e67b952f27a18a100ec20eef9efc52b0ffd4492a",
    "url": "https://syncmydevice.com?token=20d668287cf9302fc29aa3b3e67b952f27a18a100ec20eef9efc52b0ffd4492a"
  },
  "mobile": {
    "token": "563e2af0e9c54fcd801a58d482c6ac0a"
  },
  "location": {
    "timezone": null,
    "country_code": null
  },
  "sources": [
    {
      "type": "apple_health",
      "connected_at": null,
      "last_processed_at": "2026-04-07T16:59:08Z"
    }
  ],
  "status": "active",
  "created_at": "2025-09-29T08:05:08Z",
  "updated_at": "2025-09-29T08:05:08Z"
}
```

## Validic Mobile Inform APIs

### 7. Create Measurement Record

```bash
curl --request POST \
  --url 'https://mobile-inform.prod.validic.com/records/measurement?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-07T00:56:25Z",
    "log_id": "E5614A28-7C85-45ED-B425-1F5DE7325DAC",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 99
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-07T00:56:25Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-07T00:56:25Z",
  "id": "5044a5f35cc28c044569ebc99e6a93f7",
  "log_id": "E5614A28-7C85-45ED-B425-1F5DE7325DAC",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 99
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-07T00:56:25Z",
  "type": "measurement",
  "user": {
    "organization_id": 6232413757463e0001806968,
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 8. Update Measurement Record E079E298-AAD6-4CD5-A2E3-C8441D0B1576

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/E079E298-AAD6-4CD5-A2E3-C8441D0B1576?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T23:56:24Z",
    "log_id": "E079E298-AAD6-4CD5-A2E3-C8441D0B1576",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 98
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T23:56:24Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T23:56:24Z",
  "id": "ad6b18fca07d828aacad0e78a7df46c6",
  "log_id": "E079E298-AAD6-4CD5-A2E3-C8441D0B1576",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 98
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T23:56:24Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 9. Update Measurement Record C1CF0C39-4A1B-4645-B9C3-1E483BE8252C

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/C1CF0C39-4A1B-4645-B9C3-1E483BE8252C?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T23:26:23Z",
    "log_id": "C1CF0C39-4A1B-4645-B9C3-1E483BE8252C",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 98
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T23:26:23Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T23:26:23Z",
  "id": "0d78bcbf67efe5c028a4430702281840",
  "log_id": "C1CF0C39-4A1B-4645-B9C3-1E483BE8252C",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 98
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T23:26:23Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 10. Update Measurement Record DC5A4981-E0EE-42DF-8DC1-99EFAE72FF08

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/DC5A4981-E0EE-42DF-8DC1-99EFAE72FF08?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T22:55:28Z",
    "log_id": "DC5A4981-E0EE-42DF-8DC1-99EFAE72FF08",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 97
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T22:55:28Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T22:55:28Z",
  "id": "9fe7418f180181f9393790cfcc72b12d",
  "log_id": "DC5A4981-E0EE-42DF-8DC1-99EFAE72FF08",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 97
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T22:55:28Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 11. Update Measurement Record 0B1A0059-E58D-4A7F-A343-CAC7708AFC58

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/0B1A0059-E58D-4A7F-A343-CAC7708AFC58?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T22:25:27Z",
    "log_id": "0B1A0059-E58D-4A7F-A343-CAC7708AFC58",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 98
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T22:25:27Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T22:25:27Z",
  "id": "c7951a7284ad5d8fd2ebd9ee0fd879bf",
  "log_id": "0B1A0059-E58D-4A7F-A343-CAC7708AFC58",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 98
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T22:25:27Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 12. Update Measurement Record 7B4859E3-0C30-4D7A-880E-DE2915F9DF97

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/7B4859E3-0C30-4D7A-880E-DE2915F9DF97?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T21:55:26Z",
    "log_id": "7B4859E3-0C30-4D7A-880E-DE2915F9DF97",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 83
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T21:55:26Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T21:55:26Z",
  "id": "d0a1bccd1a425db8d6b37845740935be",
  "log_id": "7B4859E3-0C30-4D7A-880E-DE2915F9DF97",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 83
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T21:55:26Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 13. Update Measurement Record D4B8F046-2AF5-43F9-B250-5F24E1706636

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/D4B8F046-2AF5-43F9-B250-5F24E1706636?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T21:25:26Z",
    "log_id": "D4B8F046-2AF5-43F9-B250-5F24E1706636",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 93
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T21:25:26Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T21:25:26Z",
  "id": "2f08f87492d4821352e5f99517b92120",
  "log_id": "D4B8F046-2AF5-43F9-B250-5F24E1706636",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 93
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T21:25:26Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```

### 14. Update Measurement Record 97CA1659-3B10-432F-A59C-864CDC54F7FB

```bash
curl --request PUT \
  --url 'https://mobile-inform.prod.validic.com/records/measurement/97CA1659-3B10-432F-A59C-864CDC54F7FB?organization_id=6232413757463e0001806968&user_id=68da3db4afd52600112d8a12' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Validic-Version: 2015-10-01' \
  --header 'X-Validic-Mobile-Token: 563e2af0e9c54fcd801a58d482c6ac0a' \
  --data '{
    "end_time": "2026-04-06T20:54:00Z",
    "log_id": "97CA1659-3B10-432F-A59C-864CDC54F7FB",
    "metrics": [
      {
        "origin": "unknown",
        "type": "spo2",
        "unit": "percent",
        "value": 91
      }
    ],
    "offset_origin": "source",
    "source": {
      "device": {
        "diagnostics": [
          { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
          { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
          { "type": "operating_system", "unit": "n/a", "value": "iOS" },
          { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
          { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
        ],
        "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
        "manufacturer": "Apple Inc.",
        "model": "Watch6,15"
      },
      "type": "apple_health"
    },
    "start_time": "2026-04-06T20:54:00Z",
    "type": "measurement",
    "utc_offset": 19800
  }'
```

Response:

```json
{
  "end_time": "2026-04-06T20:54:00Z",
  "id": "af4e762725544ac7de56f63be3c8f05e",
  "log_id": "97CA1659-3B10-432F-A59C-864CDC54F7FB",
  "metrics": [
    {
      "origin": "unknown",
      "type": "spo2",
      "unit": "percent",
      "value": 91
    }
  ],
  "offset_origin": "source",
  "source": {
    "device": {
      "diagnostics": [
        { "type": "mobile_device_manufacturer", "unit": "n/a", "value": "Apple" },
        { "type": "mobile_device_model_number", "unit": "n/a", "value": "iPhone14,5" },
        { "type": "operating_system", "unit": "n/a", "value": "iOS" },
        { "type": "operating_system_version", "unit": "n/a", "value": "26.4" },
        { "type": "validic_library_version", "unit": "n/a", "value": "2.0.2(3895)" }
      ],
      "id": "com.apple.health.F0869A05-B9CE-4B0F-BF79-03CECD3238DE",
      "manufacturer": "Apple Inc.",
      "model": "Watch6,15"
    },
    "type": "apple_health"
  },
  "start_time": "2026-04-06T20:54:00Z",
  "type": "measurement",
  "user": {
    "organization_id": "6232413757463e0001806968",
    "uid": "1a716031fd5010162060fb401dfd74d2",
    "user_id": "68da3db4afd52600112d8a12"
  },
  "utc_offset": 19800
}
```
