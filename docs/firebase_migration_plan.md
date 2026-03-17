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

## Step 3.1

- Auto-create or connect `clients` when a meeting record is saved.
- Expose a `Clients` tab with list/detail UI.
- Use clients as the anchor for business card OCR and future call logs.

## Step 3.2

- Add `business_cards` to store OCR raw text and confirmed extraction results.
- Start with OCR review flow first, then replace raw-text input with camera/image OCR.
- Save confirmed business-card data into `clients`.
