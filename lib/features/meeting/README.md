# meeting

面談記録のライフサイクル管理。

- 面談メモ
- 次回アクション
- 結果管理
- AI 要約
- 顧客 / Spreadsheet 連携
## Meeting

- Source of truth for meeting records is Firestore.
- Google Calendar remains the source of truth for schedule CRUD.

### Current direction

- `meeting_records` is the first Firebase-backed domain.
- `meeting_status` expands next for reminders, record-pending state, and follow-up state.
- `clients`, `activity_logs`, and `sync_states` expand after that layer is stable.
