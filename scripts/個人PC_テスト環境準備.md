# 個人PC用 Outlook テスト環境準備ガイド

## 前提条件
- Microsoft Outlook デスクトップ版がインストールされている
- PowerShell実行権限がある

## 1. Outlook の確認

### Outlook がインストールされているか確認
```powershell
# Outlook のインストール確認
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Outlook*"}
```

### Outlook の起動確認
1. Outlook を起動
2. メールアカウントが設定されているか確認
3. 送信済みフォルダにメールがあるか確認

## 2. PowerShell実行ポリシーの設定

### 現在の実行ポリシー確認
```powershell
Get-ExecutionPolicy
```

### 実行ポリシーを設定（必要に応じて）
```powershell
# ユーザー権限でのみ実行ポリシーを変更
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 3. スクリプト配置

### 配置ディレクトリ作成
```powershell
# ユーザー権限で実行可能（管理者権限不要）
New-Item -ItemType Directory -Path "$env:APPDATA\Apps" -Force
```

### ファイル配置
以下のファイルを `%APPDATA%\Apps` に配置：
（例: `C:\Users\<user>\AppData\Roaming\Apps`）
- `find_task_assignments_company_safe.ps1`
- `check_company_environment.ps1`
- `compose_mail.ps1`（メール作成機能用）
- `find_sent.ps1`（送信済み検索用）

## 4. 環境テスト

### 環境確認スクリプト実行
```powershell
cd $env:APPDATA\Apps
.\check_company_environment.ps1
```

### Outlook接続テスト
```powershell
# 基本的なOutlook接続テスト
try {
    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $inbox = $namespace.GetDefaultFolder(6)
    Write-Host "Outlook接続成功"
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
} catch {
    Write-Host "Outlook接続失敗: $($_.Exception.Message)"
}
```

## 5. アプリケーションでのテスト

### テスト手順
1. アプリケーション起動
2. 設定画面 → Outlook連携
3. 「接続テスト」ボタン
4. 「メール検索テスト」ボタン
5. 「タスク自動生成」ボタン

## 6. トラブルシューティング

### よくある問題と解決方法

#### 問題1: COM オブジェクトエラー
```
解決方法: Outlook を起動してからテストを実行
```

#### 問題2: 実行ポリシーエラー
```
解決方法: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 問題3: 権限不足エラー
```
解決方法: 管理者権限でPowerShellを実行
```

#### 問題4: Outlook が見つからない
```
解決方法: Outlook が正しくインストールされているか確認
```

## 7. テスト用メール作成

### テスト用メールの送信
1. Outlook で自分宛にメール送信
2. 件名に「業務依頼」「タスク依頼」などのキーワードを含める
3. 本文にタスク内容を記載
4. 送信後、アプリケーションで検索テストを実行

### 推奨テストメール例
```
件名: 業務依頼テスト
本文: 
お疲れ様です。
以下の業務をお願いします。

1. 資料作成
2. 会議準備
3. 報告書作成

期限: 来週金曜日まで
優先度: 高

よろしくお願いします。
```

## 8. 注意事項

### セキュリティ
- 個人PCでも機密情報は含めない
- テスト用のダミーデータを使用

### パフォーマンス
- 大量のメールがある場合は検索時間が長くなる可能性
- 必要に応じて検索期間を限定

### 互換性
- Outlook のバージョンによって動作が異なる場合がある
- 最新版でのテストを推奨
