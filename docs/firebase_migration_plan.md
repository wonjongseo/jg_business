# Firebase Migration Plan

## Goal

Keep Google Calendar as the schedule source of truth and move only app-owned
sales data into Firebase.

## Step 1

- Keep Google Calendar CRUD in Google Calendar.
- Store `meeting_records` in Firestore.
- Do not duplicate full schedule data in Firestore.

## Step 2

- Add `meeting_status` or `event_tracking` to manage:
  - reminder state
  - meeting-record pending state
  - follow-up action state
  - per-event sync metadata

## Step 3

- Expand Firestore to `clients`.
- Add unified activity timeline data.
- Add Functions-based Sheets sync.
- Add reminder orchestration and AI post-processing.
- Add SSO-aware user identity metadata.
