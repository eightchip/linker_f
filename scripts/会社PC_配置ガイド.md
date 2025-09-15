# 会社PC用 PowerShellスクリプト配置ガイド

## 配置場所
**推奨ディレクトリ: `C:\Apps\`**

## 配置すべきファイル一覧

### 1. メール機能関連
| ファイル名 | 用途 | ソースコード内の参照 |
|-----------|------|-------------------|
| `compose_mail.ps1` | メール作成 | `mail_service.dart` 130行目 |
| `find_sent.ps1` | 送信済みメール検索 | `mail_service.dart` 343行目 |

### 2. Outlook連携関連
| ファイル名 | 用途 | ソースコード内の参照 |
|-----------|------|-------------------|
| `find_task_assignments_company_safe.ps1` | タスク割り当てメール検索（推奨） | `outlook_service.dart` 9行目（要変更） |
| `check_company_environment.ps1` | 環境確認 | 手動実行用 |

## 配置手順

### 1. ディレクトリ作成
```powershell
# 管理者権限で実行
New-Item -ItemType Directory -Path "C:\Apps" -Force
```

### 2. ファイル配置
以下のファイルを `C:\Apps\` にコピー：

#### 既存ファイル（画像で確認済み）
- `compose_mail.ps1` ✅
- `find_sent.ps1` ✅

#### 新規配置が必要
- `find_task_assignments_company_safe.ps1` ⚠️
- `check_company_environment.ps1` ⚠️

### 3. 権限設定
```powershell
# ユーザー権限で実行可能に設定
icacls "C:\Apps\*.ps1" /grant "Users:(RX)"
```

## 安全性確認

### 1. 環境確認スクリプト実行
```powershell
cd C:\Apps
.\check_company_environment.ps1
```

### 2. 実行ポリシー確認
```powershell
Get-ExecutionPolicy
# 必要に応じて変更
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## アプリケーション側の修正が必要

### 現在の問題
- `outlook_service.dart` が `scripts/find_task_assignments_safe.ps1` を参照
- 会社PCでは `C:\Apps\find_task_assignments_company_safe.ps1` を使用すべき

### 修正内容
1. `outlook_service.dart` のパスを `C:\Apps\find_task_assignments_company_safe.ps1` に変更
2. または、環境に応じてパスを動的に切り替える

## テスト手順

### 1. 基本動作確認
```powershell
# 環境確認
.\check_company_environment.ps1

# Outlook接続テスト
.\find_task_assignments_company_safe.ps1 -TestConnection
```

### 2. アプリケーション内テスト
1. 設定画面 → Outlook連携
2. 「接続テスト」ボタン
3. 「メール検索テスト」ボタン
4. 「タスク自動生成」ボタン

## トラブルシューティング

### よくある問題
1. **実行ポリシーエラー**: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
2. **Outlook未起動**: Outlookを起動してからテスト
3. **権限不足**: ユーザー権限で実行可能か確認

### ログ確認
- アプリケーションのデバッグ出力を確認
- PowerShellスクリプトのエラーメッセージを確認
