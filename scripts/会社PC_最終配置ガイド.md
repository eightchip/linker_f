# 会社PC用 Outlook連携 最終配置ガイド

## 配置場所
**ディレクトリ: `C:\Apps\`**

## 配置すべきファイル一覧

### 必須ファイル（4個）

| ファイル名 | 用途 | アプリケーション内の参照 |
|-----------|------|----------------------|
| `company_outlook_test.ps1` | Outlook接続テスト | `outlook_service.dart` の接続テスト |
| `company_task_search.ps1` | タスク割り当てメール検索 | `outlook_service.dart` のメール検索 |
| `compose_mail.ps1` | メール作成 | `mail_service.dart` 130行目 |
| `find_sent.ps1` | 送信済みメール検索 | `mail_service.dart` 343行目 |

## 配置方法

### 方法1: 自動配置（推奨）
```batch
# プロジェクトのscriptsディレクトリで実行
scripts\会社PC_最終配置.bat
```

### 方法2: 手動配置
1. `C:\Apps` ディレクトリを作成
2. 以下のファイルをコピー：
   - `scripts/company_outlook_test.ps1` → `C:\Apps/company_outlook_test.ps1`
   - `scripts/company_task_search.ps1` → `C:\Apps/company_task_search.ps1`
   - `scripts/compose_mail.ps1` → `C:\Apps/compose_mail.ps1`
   - `scripts/find_sent.ps1` → `C:\Apps/find_sent.ps1`

## 前提条件

### 1. Outlook デスクトップアプリ
- Microsoft Outlook 2016/2019/2021/365 がインストール済み
- メールアカウントが設定済み
- Outlook が起動可能

### 2. PowerShell実行権限
```powershell
# 実行ポリシーを確認
Get-ExecutionPolicy

# 必要に応じて設定（ユーザー権限で実行可能）
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**注意**: 会社PCでは管理者権限は不要です。ユーザー権限のみで動作します。

## テスト手順

### 1. 環境確認
```powershell
cd C:\Apps
powershell -ExecutionPolicy Bypass -File company_outlook_test.ps1
```

### 2. アプリケーション内テスト
1. アプリケーション起動
2. 設定画面 → Outlook連携
3. 「接続テスト」ボタン
4. 「メール検索テスト」ボタン
5. 「タスク自動生成」ボタン

## 機能説明

### 1. company_outlook_test.ps1
- Outlook プロセス確認
- COM オブジェクトテスト
- メールアカウント確認
- 送信済みメール確認

### 2. company_task_search.ps1
- 過去7日間のメール検索
- キーワードマッチング（業務依頼、タスク依頼等）
- 機密情報の自動マスキング
- JSON形式での結果出力

### 3. compose_mail.ps1
- Outlook でメール作成画面を起動
- HTML形式のメール本文生成
- 送信先、件名、本文の設定

### 4. find_sent.ps1
- 送信済みメールの検索
- トークンによる検索機能

## セキュリティ対策

### 1. 機密情報マスキング
- クレジットカード番号: `****-****-****-****`
- 社会保障番号: `***-**-****`
- メールアドレス: `***@domain.com`

### 2. ユーザー権限での実行
- 管理者権限不要
- ユーザーレベルの権限で動作

### 3. COM オブジェクトの安全解放
- メモリリーク防止
- 適切なリソース管理

## トラブルシューティング

### よくある問題

#### 1. Outlook が起動していない
```
解決方法: Outlook を起動してからテストを実行
```

#### 2. COM オブジェクトエラー
```
解決方法: Outlook を起動してからテストを実行
```

#### 3. 実行ポリシーエラー
```
解決方法: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 4. 権限不足エラー
```
解決方法: ユーザー権限でPowerShellを実行（管理者権限は不要）
```

#### 5. メールアカウント未設定
```
解決方法: Outlook でメールアカウントを設定
```

## 会社環境での注意事項

### 1. セキュリティポリシー
- 会社のセキュリティポリシーに従う
- 機密情報の取り扱いに注意
- ユーザー権限のみで動作（管理者権限不要）

### 2. ネットワーク制限
- プロキシ設定の確認
- ファイアウォール設定の確認
- インターネットアクセスの確認

### 3. バックアップ
- 重要なメールのバックアップ
- 設定ファイルのバックアップ
- スクリプトファイルのバックアップ

## サポート

### ログ確認
- PowerShellスクリプトのエラーメッセージ
- アプリケーションのデバッグ出力
- Windows イベントログ

### 連絡先
- 会社のIT部門
- アプリケーション開発者
- Microsoft サポート（Outlook関連）
