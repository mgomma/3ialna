# Parental-control API design

This API supports parent-managed domain policies, child exception requests, and privacy-minimized DNS decision logs. It assumes a parent account can own multiple family profiles and devices. All endpoints require TLS and an authenticated session. Parent endpoints require a parent role; child endpoints require a child device session scoped to one child profile.

## Core identifiers and conventions

| Field | Type | Description |
|---|---|---|
| `familyId` | UUID | Family or household scope |
| `profileId` | UUID | Child profile scope |
| `deviceId` | UUID | Registered Android device |
| `policyId` | UUID | Versioned policy snapshot |
| `requestId` | UUID | Child exception request |
| `decisionId` | UUID | Minimal DNS decision record |
| `domain` | string | Lowercase normalized registrable domain or hostname |
| `createdAt` / `updatedAt` | RFC 3339 timestamp | UTC timestamps |

The server must normalize domains before comparison, enforce maximum lengths, reject IP addresses in the domain-rule API unless explicitly supported, and never accept a client-provided `familyId` as an authorization substitute.

## Policy and domain rules

### `GET /v1/families/{familyId}/profiles/{profileId}/safe-content-policy`

Returns the effective policy for a child profile. The server should include a monotonically increasing `version` so devices can detect stale writes.

```json
{
  "policyId": "uuid",
  "profileId": "uuid",
  "version": 12,
  "enabled": true,
  "blockedCategories": ["adult", "gambling"],
  "allowSocialMedia": true,
  "blockedDomains": ["example.com"],
  "allowedDomains": ["school.example"],
  "updatedAt": "2026-08-16T15:00:00Z"
}
```

### `PUT /v1/families/{familyId}/profiles/{profileId}/safe-content-policy`

Replaces the policy using optimistic concurrency. The request includes `expectedVersion`; the server returns `409 POLICY_VERSION_CONFLICT` when another parent device has changed the policy.

```json
{
  "expectedVersion": 12,
  "enabled": true,
  "blockedCategories": ["adult", "gambling", "violence"],
  "allowSocialMedia": false,
  "blockedDomains": ["bad.example"],
  "allowedDomains": ["school.example"]
}
```

### `POST /v1/families/{familyId}/profiles/{profileId}/domain-rules`

Creates one explicit rule. The server returns `409 DOMAIN_RULE_EXISTS` when the normalized rule already exists.

```json
{
  "domain": "https://www.school.example/path",
  "action": "allow",
  "reason": "School learning portal",
  "source": "parent"
}
```

The response returns the normalized value and audit metadata:

```json
{
  "ruleId": "uuid",
  "domain": "school.example",
  "action": "allow",
  "source": "parent",
  "createdBy": "parent-user-uuid",
  "createdAt": "2026-08-16T15:05:00Z"
}
```

### `DELETE /v1/families/{familyId}/profiles/{profileId}/domain-rules/{ruleId}`

Deletes a parent-created custom rule. Category defaults and reviewed safety lists must not be deleted through this endpoint; they require a policy override instead.

## Child exception requests

### `POST /v1/profiles/{profileId}/exception-requests`

Creates a child request after the device has locally blocked a domain. The server must verify that the device belongs to the profile and that the child session cannot create a permanent allow rule.

```json
{
  "deviceId": "uuid",
  "domain": "learning.example",
  "reason": "I need this website for my homework.",
  "requestedDurationMinutes": 15,
  "matchedRule": {
    "type": "category",
    "category": "social"
  }
}
```

Response:

```json
{
  "requestId": "uuid",
  "status": "pending",
  "domain": "learning.example",
  "requestedDurationMinutes": 15,
  "createdAt": "2026-08-16T15:10:00Z",
  "expiresAt": null
}
```

### `GET /v1/families/{familyId}/exception-requests?status=pending&profileId={profileId}`

Lists requests for parent review. Results should be paginated with a maximum page size of 50 and sorted by newest first. The response includes the matched rule and the device label but not page content.

### `POST /v1/families/{familyId}/exception-requests/{requestId}/decision`

Records a parent decision. `allow_once` should create a short-lived device-scoped exception; `allow_temporary` should create an exception with a bounded expiration; `allow_always` should require a second confirmation because it changes the persistent policy; `keep_blocked` closes the request without creating an exception.

```json
{
  "decision": "allow_temporary",
  "durationMinutes": 15,
  "parentNote": "Approved for homework."
}
```

Response:

```json
{
  "requestId": "uuid",
  "status": "approved",
  "decision": "allow_temporary",
  "exceptionId": "uuid",
  "expiresAt": "2026-08-16T15:25:00Z",
  "decidedAt": "2026-08-16T15:11:00Z"
}
```

Valid decisions are `allow_once`, `allow_temporary`, `allow_always`, and `keep_blocked`. The service must reject decisions from a non-parent role and reject a second decision on a closed request with `409 REQUEST_ALREADY_DECIDED`.

## Recent DNS block logging

### `POST /v1/devices/{deviceId}/dns-decisions/batch`

Uploads a bounded batch of locally recorded decisions. Devices should queue records offline and use an idempotency key. The endpoint must accept only the minimum metadata needed for the parent dashboard.

```json
{
  "items": [
    {
      "decisionId": "uuid",
      "profileId": "uuid",
      "domain": "bet.example",
      "action": "blocked",
      "matchedRuleType": "category",
      "matchedCategory": "gambling",
      "occurredAt": "2026-08-16T15:12:00Z"
    }
  ]
}
```

Allowed `matchedRuleType` values are `category`, `custom_block`, `custom_allow`, and `system_default`. Store no URL path, query string, IP address, packet payload, page title, message, or application content.

### `GET /v1/families/{familyId}/dns-decisions?profileId={profileId}&from={timestamp}&to={timestamp}&action=blocked`

Returns paginated recent decisions for a parent dashboard. The default retention should be seven days, configurable by the family and bounded by a server maximum. The response should include `nextCursor` and only normalized domain, matched rule, device label, and timestamp.

```json
{
  "items": [
    {
      "decisionId": "uuid",
      "profileId": "uuid",
      "deviceLabel": "Tablet",
      "domain": "bet.example",
      "action": "blocked",
      "matchedRuleType": "category",
      "matchedCategory": "gambling",
      "occurredAt": "2026-08-16T15:12:00Z"
    }
  ],
  "nextCursor": null
}
```

### `DELETE /v1/families/{familyId}/dns-decisions`

Deletes the family’s stored DNS decision history. Devices should also clear queued unsent records for the affected family after receiving a successful response.

## Error envelope

All errors use a stable machine-readable code and localized message keys. The server should not send only English text because the Flutter client needs Arabic RTL rendering.

```json
{
  "error": {
    "code": "POLICY_VERSION_CONFLICT",
    "messageKey": "safeContent.policyVersionConflict",
    "details": {},
    "requestId": "uuid"
  }
}
```

Recommended error codes include `UNAUTHORIZED_PARENT`, `PROFILE_ACCESS_DENIED`, `POLICY_VERSION_CONFLICT`, `DOMAIN_INVALID`, `DOMAIN_RULE_EXISTS`, `REQUEST_ALREADY_DECIDED`, `VPN_DEVICE_NOT_REGISTERED`, `RATE_LIMITED`, and `SERVICE_UNAVAILABLE`.

## Privacy and security requirements

The server must enforce family/profile authorization on every request, encrypt data in transit and at rest, rate-limit child request creation, and audit parent decisions without storing child message content. A parent should be able to export and delete policy and decision data. A DNS decision record is a safety event, not a browsing-history substitute; the dashboard should communicate the retention period and provide a delete control.
