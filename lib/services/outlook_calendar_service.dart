import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_item.dart';
import '../utils/error_handler.dart';

/// Outlook Calendar連携サービス
/// Outlook COMオブジェクトを使用してカレンダーから予定を取得
class OutlookCalendarService {
  static final OutlookCalendarService _instance = OutlookCalendarService._internal();
  factory OutlookCalendarService() => _instance;
  OutlookCalendarService._internal();

  final _uuid = const Uuid();

  /// Outlookが利用可能かチェック
  Future<bool> isOutlookAvailable() async {
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        r'try { $ol = New-Object -ComObject Outlook.Application; $ol.Quit(); Write-Output "true" } catch { Write-Output "false" }',
      ]);

      return result.stdout.toString().trim() == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('Outlook可用性チェックエラー: $e');
      }
      return false;
    }
  }

  /// Outlookカレンダーから予定を取得
  /// [startDate] 開始日（省略時は今日から）
  /// [endDate] 終了日（省略時は30日後）
  Future<List<Map<String, dynamic>>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 30));

      final script = '''
function Sanitize([string]\$value) {
    if ([string]::IsNullOrEmpty(\$value)) { return "" }
    return (\$value -replace "[\\r\\n\\u0000]", " ").Trim()
}

\$startDate = [DateTime]::Parse("${start.toIso8601String()}")
\$endDate = [DateTime]::Parse("${end.toIso8601String()}")

\$outlook = \$null
\$namespace = \$null
\$calendar = \$null
\$items = \$null
\$rawEvents = @()

try {
    # Outlook COMオブジェクトの作成
    \$outlook = New-Object -ComObject Outlook.Application
    if (\$null -eq \$outlook) {
        Write-Error "Outlook COMオブジェクトの作成に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    \$namespace = \$outlook.GetNamespace("MAPI")
    if (\$null -eq \$namespace) {
        Write-Error "MAPI名前空間の取得に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    \$calendar = \$namespace.GetDefaultFolder(9)
    if (\$null -eq \$calendar) {
        Write-Error "カレンダーフォルダの取得に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    \$items = \$calendar.Items
    if (\$null -eq \$items) {
        Write-Error "カレンダーアイテムの取得に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    \$items.IncludeRecurrences = \$true
    
    # アイテムを安全に列挙
    \$itemCount = \$items.Count
    for (\$i = 1; \$i -le \$itemCount; \$i++) {
        \$item = \$null
        try {
            \$item = \$items.Item(\$i)
            if (\$null -eq \$item) { continue }
            
            # 型チェック
            if (-not (\$item -is [Microsoft.Office.Interop.Outlook.AppointmentItem])) { 
                if (\$item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null }
                continue 
            }
            
            # 日付範囲チェック
            if (\$null -eq \$item.Start) { 
                if (\$item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null }
                continue 
            }
            
            try {
                \$itemStart = [DateTime]\$item.Start
                if (\$itemStart -lt \$startDate -or \$itemStart -gt \$endDate) { 
                    if (\$item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null }
                    continue 
                }
            } catch {
                if (\$item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null }
                continue
            }
            
            # イベントデータを安全に取得
            \$event = @{
                Subject = ""
                Start = ""
                End = ""
                Location = ""
                Body = ""
                EntryID = ""
                LastModificationTime = ""
                Organizer = ""
                IsMeeting = \$false
                IsRecurring = \$false
                IsOnlineMeeting = \$false
            }
            
            try {
                if (\$null -ne \$item.Subject) { \$event.Subject = Sanitize(\$item.Subject) }
                if (\$null -ne \$item.Start) { \$event.Start = \$item.Start.ToString("o") }
                if (\$null -ne \$item.End) { \$event.End = \$item.End.ToString("o") }
                if (\$null -ne \$item.Location) { \$event.Location = Sanitize(\$item.Location) }
                if (\$null -ne \$item.Body) { \$event.Body = Sanitize(\$item.Body) }
                if (\$null -ne \$item.EntryID) { \$event.EntryID = \$item.EntryID }
                if (\$null -ne \$item.LastModificationTime) { \$event.LastModificationTime = \$item.LastModificationTime.ToString("o") }
                if (\$null -ne \$item.Organizer) { \$event.Organizer = Sanitize(\$item.Organizer) }
                if (\$null -ne \$item.IsMeeting) { \$event.IsMeeting = [bool]\$item.IsMeeting }
                if (\$null -ne \$item.IsRecurring) { \$event.IsRecurring = [bool]\$item.IsRecurring }
                if (\$null -ne \$item.IsOnlineMeeting) { \$event.IsOnlineMeeting = [bool]\$item.IsOnlineMeeting }
                
                \$rawEvents += \$event
            } catch {
                # 個別アイテムの処理エラーは無視して続行
            } finally {
                if (\$item) { 
                    try {
                        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null
                    } catch {
                        # 解放エラーは無視
                    }
                    \$item = \$null
                }
            }
        } catch {
            # アイテム取得エラーは無視して続行
            if (\$item) { 
                try {
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null
                } catch {
                    # 解放エラーは無視
                }
                \$item = \$null
            }
        }
    }

    # ソートとJSON変換
    \$events = \$rawEvents | Sort-Object { 
        if ([string]::IsNullOrEmpty(\$_.Start)) { 
            [DateTime]::MinValue 
        } else { 
            try {
                [DateTime]::Parse(\$_.Start) 
            } catch {
                [DateTime]::MinValue
            }
        } 
    }

    \$json = \$events | ConvertTo-Json -Depth 10 -Compress
    Write-Output \$json
} catch {
    Write-Error "予定取得エラー: \$(\$_.Exception.Message)"
    @() | ConvertTo-Json
} finally {
    # COMオブジェクトの安全な解放
    if (\$items) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$items) | Out-Null
        } catch { }
        \$items = \$null
    }
    if (\$calendar) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$calendar) | Out-Null
        } catch { }
        \$calendar = \$null
    }
    if (\$namespace) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$namespace) | Out-Null
        } catch { }
        \$namespace = \$null
    }
    if (\$outlook) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$outlook) | Out-Null
        } catch { }
        \$outlook = \$null
    }
    
    # ガベージコレクション
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
}
''';

      final output = await _runPowerShellScript(script);
      return _parseJsonList(output);
    } catch (e) {
      ErrorHandler.logError('Outlook Calendar 予定取得', e);
      rethrow;
    }
  }

  /// Outlook予定をScheduleItemに変換
  /// [taskId] 関連付けるタスクID
  /// [outlookEvent] Outlook予定データ
  ScheduleItem convertEventToScheduleItem({
    required String taskId,
    required Map<String, dynamic> outlookEvent,
  }) {
    final subject = outlookEvent['Subject'] as String? ?? '';
    final startStr = outlookEvent['Start'] as String? ?? '';
    final endStr = outlookEvent['End'] as String? ?? '';
    final location = outlookEvent['Location'] as String? ?? '';
    final body = outlookEvent['Body'] as String? ?? '';
    final entryId = outlookEvent['EntryID'] as String? ?? '';
    final organizer = outlookEvent['Organizer'] as String? ?? '';
    final isMeeting = outlookEvent['IsMeeting'] as bool? ?? false;
    final isRecurring = outlookEvent['IsRecurring'] as bool? ?? false;
    final isOnlineMeeting = outlookEvent['IsOnlineMeeting'] as bool? ?? false;
    final calendarOwner = outlookEvent['CalendarOwner'] as String? ?? '';

    DateTime startDateTime;
    try {
      startDateTime = DateTime.parse(startStr);
    } catch (e) {
      throw Exception('開始日時のパースエラー: $startStr');
    }

    DateTime? endDateTime;
    if (endStr.isNotEmpty) {
      try {
        endDateTime = DateTime.parse(endStr);
      } catch (e) {
        if (kDebugMode) {
          print('終了日時のパースエラー（スキップ）: $endStr');
        }
      }
    }

    final notesFragments = <String>[];
    if (body.isNotEmpty) {
      notesFragments.add(body);
    }
    final metadataParts = <String>[];
    if (organizer.isNotEmpty) {
      metadataParts.add('Organizer: $organizer');
    }
    if (calendarOwner.isNotEmpty) {
      metadataParts.add('Calendar: $calendarOwner');
    }
    if (isMeeting) {
      metadataParts.add('Meeting');
    }
    if (isRecurring) {
      metadataParts.add('Recurring');
    }
    if (isOnlineMeeting) {
      metadataParts.add('Online Meeting');
    }
    if (metadataParts.isNotEmpty) {
      notesFragments.add(metadataParts.join(' / '));
    }

    final id = entryId.isNotEmpty ? 'outlook_${entryId.hashCode}' : _uuid.v4();

    return ScheduleItem(
      id: id,
      taskId: taskId,
      title: subject,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location.isNotEmpty ? location : null,
      notes: notesFragments.isNotEmpty ? notesFragments.join('\n\n') : null,
      createdAt: DateTime.now(),
      outlookEntryId: entryId.isNotEmpty ? entryId : null,
      calendarOwner: calendarOwner.isNotEmpty ? calendarOwner : null,
    );
  }

  /// Outlook予定リストをScheduleItemリストに変換
  List<ScheduleItem> convertEventsToScheduleItems({
    required String taskId,
    required List<Map<String, dynamic>> outlookEvents,
  }) {
    return outlookEvents
        .map((event) => convertEventToScheduleItem(
              taskId: taskId,
              outlookEvent: event,
            ))
        .toList();
  }

  Future<String> _runPowerShellScript(String script) async {
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ], runInShell: false);

      // エラー出力を確認
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty && !stderr.contains('ConvertTo-Json')) {
        if (kDebugMode) {
          print('PowerShell警告: $stderr');
        }
      }

      // 標準出力を確認
      final stdout = result.stdout.toString().trim();
      if (stdout.isEmpty && result.exitCode != 0) {
        throw Exception('PowerShellスクリプト実行エラー: $stderr');
      }

      return stdout;
    } catch (e) {
      if (kDebugMode) {
        print('PowerShell実行エラー: $e');
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseJsonList(String rawOutput) {
    final output = rawOutput.trim();
    if (output.isEmpty) {
      return [];
    }

    final sanitized = output
        .replaceAll('\uFEFF', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F]'), ' ')
        .trim();

    if (sanitized.isEmpty) {
      return [];
    }

    final decoded = json.decode(sanitized);
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (decoded is Map<String, dynamic>) {
      return [Map<String, dynamic>.from(decoded)];
    } else {
      throw Exception('予期しないJSON形式です');
    }
  }

  String _escapeForPowerShell(String value) {
    return value.replaceAll("'", "''");
  }
}

