# Firestore Schema

## Principle

- Google Calendar remains the source of truth for schedule CRUD.
- Firestore stores sales-operation data that Google Calendar does not own.
- Firestore does not mirror full calendar events unless operational metadata is required.

## Collections

### `users/{userId}`

```json
{
  "email": "seller@company.com",
  "displayName": "Alex Kim",
  "oktaSubject": "okta-user-subject",
  "googleLinked": true,
  "lastLoginAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### `meeting_records/{recordId}`

Primary collection for step 1 of the Firebase migration.

```json
{
  "userId": "uid",
  "googleEventId": "google-calendar-event-id",
  "calendarId": "primary",
  "title": "Quarterly renewal",
  "companyName": "ACME Corp",
  "contactName": "Kim Tanaka",
  "scheduledStartAt": "timestamp",
  "scheduledEndAt": "timestamp",
  "locationName": "Tokyo HQ",
  "summary": "meeting summary",
  "notes": "raw note body",
  "nextAction": "send pricing sheet",
  "nextActionDueAt": "timestamp",
  "status": "draft",
  "sync": {
    "sheets": {
      "status": "pending",
      "lastAttemptAt": "timestamp",
      "lastSyncedAt": "timestamp",
      "errorCode": "optional"
    }
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Recommended status values:
- `draft`
- `completed`
- `sync_pending`
- `sync_failed`

### `meeting_status/{statusId}`

Planned after `meeting_records`. This collection tracks app-owned state per
Google Calendar event without copying the full event payload.

```json
{
  "userId": "uid",
  "googleEventId": "google-calendar-event-id",
  "calendarId": "primary",
  "scheduledStartAt": "timestamp",
  "scheduledEndAt": "timestamp",
  "locationName": "Tokyo HQ",
  "recordStatus": "pending",
  "reminderStatus": {
    "beforeMeeting": "scheduled",
    "afterMeeting": "idle",
    "leaveLocation": "idle"
  },
  "followUpStatus": "idle",
  "lastNotificationAt": "timestamp",
  "lastSyncedAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Recommended `recordStatus` values:
- `idle`
- `pending`
- `completed`

Planned future expansion after `meeting_status` is stable:
- `clients`
- `activity_logs`
- `sync_states`

### `clients/{clientId}`

```json
{
  "userId": "uid",
  "companyName": "ACME Corp",
  "contactName": "Kim Tanaka",
  "phoneNumber": "optional",
  "email": "optional",
  "notes": "optional",
  "linkedGoogleEventIds": ["google-calendar-event-id"],
  "lastMeetingAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### `business_cards/{businessCardId}`

```json
{
  "userId": "uid",
  "sourceType": "manual_ocr_draft",
  "imagePath": null,
  "rawText": "OCR raw text",
  "companyName": "ACME Corp",
  "contactName": "Kim Tanaka",
  "phoneNumber": "optional",
  "email": "optional",
  "notes": "optional",
  "ocrStatus": "confirmed",
  "linkedClientId": "client-id",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Index Notes

- `meeting_records`
  - `userId ASC, scheduledStartAt DESC`
  - `userId ASC, googleEventId ASC`
  - `userId ASC, status ASC, updatedAt DESC`
- `meeting_status`
  - `userId ASC, googleEventId ASC`
  - `userId ASC, recordStatus ASC, scheduledStartAt DESC`
