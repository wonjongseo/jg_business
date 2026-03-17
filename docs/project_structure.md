# プロジェクト構成

## アプリ

```text
lib/
  main.dart
  app/
    bootstrap/
    config/
    di/
    routes/
  features/
    auth/
    business_card/
    calendar/
    client/
    location_trigger/
    meeting/
    notification/
    settings/
    spreadsheet_sync/
    telephony/
  shared/
    constants/
    dto/
    enums/
    errors/
    extensions/
    services/
    theme/
    utils/
    widgets/
```

## Firebase

```text
firebase/
  functions/
    src/
      auth/
      clients/
      meetings/
      notifications/
      spreadsheets/
      telephony/
      common/
  firestore/
  storage/
```

## 役割

- `features/auth`: Firebase Auth、Google サインイン連携、Okta SSO。
- `features/calendar`: Google Calendar CRUD、同期、面談導線。
- `features/meeting`: 面談記録フォーム、要約、次回アクション。
- `features/client`: 顧客・会社・連絡先管理。
- `features/business_card`: 名刺 OCR と連絡先抽出。
- `features/notification`: ローカル通知スケジュールと権限処理。
- `features/location_trigger`: 到着・離脱トリガーと位置ルール。
- `features/spreadsheet_sync`: Google Sheets 連携状態管理。
- `features/telephony`: VoIP、通話履歴、録音、AI 要約。
- `firebase/functions`: クライアントに置けないサーバー側ロジック。

## デバイス対応

- 主対象は iPhone と iPad。
- Calendar、Meeting、Client、Dashboard はタブレットでも見やすいレイアウトを前提にする。
- iPad では split view や master-detail 構成を考慮する。
