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

      // PowerShellスクリプトを実行（COMオブジェクトの適切な解放を追加）
      final script = '''
try {
    \$outlook = New-Object -ComObject Outlook.Application
    \$namespace = \$outlook.GetNamespace("MAPI")
    \$calendar = \$namespace.GetDefaultFolder(9)  # olFolderCalendar = 9

    \$items = \$calendar.Items
    \$items.Sort("[Start]", \$true)  # 開始日時で昇順ソート

    \$events = @()
    \$startDate = [DateTime]::Parse("${start.toIso8601String()}")
    \$endDate = [DateTime]::Parse("${end.toIso8601String()}")

    foreach (\$item in \$items) {
        try {
            if (\$item.Start -ge \$startDate -and \$item.Start -le \$endDate) {
                \$event = @{
                    Subject = if (\$item.Subject) { \$item.Subject } else { "" }
                    Start = \$item.Start.ToString("yyyy-MM-ddTHH:mm:ss")
                    End = if (\$item.End) { \$item.End.ToString("yyyy-MM-ddTHH:mm:ss") } else { "" }
                    Location = if (\$item.Location) { \$item.Location } else { "" }
                    Body = if (\$item.Body) { \$item.Body } else { "" }
                    EntryID = if (\$item.EntryID) { \$item.EntryID } else { "" }
                    LastModificationTime = if (\$item.LastModificationTime) { \$item.LastModificationTime.ToString("yyyy-MM-ddTHH:mm:ss") } else { "" }
                }
                \$events += \$event
            }
        } catch {
            # エラーが発生したアイテムはスキップ
            continue
        } finally {
            # 各アイテムのCOMオブジェクトを解放
            if (\$item) {
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null
            }
        }
    }

    # JSON形式で出力
    \$events | ConvertTo-Json -Depth 10

    # COMオブジェクトを適切に解放（順序重要）
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$items) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$calendar) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$namespace) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$outlook) | Out-Null
    
    # ガベージコレクションを強制実行
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
} catch {
    Write-Error \$_.Exception.Message
    throw
}
''';

      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);

      if (result.exitCode != 0) {
        throw Exception('PowerShellスクリプト実行エラー: ${result.stderr}');
      }

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        return [];
      }

      // JSONをパース
      final jsonData = json.decode(output) as List;
      return jsonData.map((e) => Map<String, dynamic>.from(e)).toList();
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

    // 日時をパース
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

    // EntryIDをベースに一意のIDを生成（OutlookのEntryIDを保持）
    final id = entryId.isNotEmpty ? 'outlook_${entryId.hashCode}' : _uuid.v4();

    return ScheduleItem(
      id: id,
      taskId: taskId,
      title: subject,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location.isNotEmpty ? location : null,
      notes: body.isNotEmpty ? body : null,
      createdAt: DateTime.now(),
      outlookEntryId: entryId.isNotEmpty ? entryId : null, // EntryIDを保存
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
}

