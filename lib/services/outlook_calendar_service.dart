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

try {
    \$outlook = New-Object -ComObject Outlook.Application
    \$namespace = \$outlook.GetNamespace("MAPI")
    \$calendar = \$namespace.GetDefaultFolder(9)
    \$items = \$calendar.Items
    \$items.IncludeRecurrences = \$true

    \$rawEvents = @()

    foreach (\$item in \$items) {
        try {
            if (\$null -eq \$item) { continue }
            if (-not (\$item -is [Microsoft.Office.Interop.Outlook.AppointmentItem])) { continue }
            if (\$item.Start -lt \$startDate -or \$item.Start -gt \$endDate) { continue }

            \$rawEvents += @{
                Subject = Sanitize(\$item.Subject)
                Start = \$item.Start.ToString("o")
                End = if (\$item.End) { \$item.End.ToString("o") } else { "" }
                Location = Sanitize(\$item.Location)
                Body = Sanitize(\$item.Body)
                EntryID = if (\$item.EntryID) { \$item.EntryID } else { "" }
                LastModificationTime = if (\$item.LastModificationTime) { \$item.LastModificationTime.ToString("o") } else { "" }
                Organizer = Sanitize(\$item.Organizer)
                IsMeeting = if (\$item.IsMeeting -ne \$null) { [bool]\$item.IsMeeting } else { \$false }
                IsRecurring = if (\$item.IsRecurring -ne \$null) { [bool]\$item.IsRecurring } else { \$false }
                IsOnlineMeeting = if (\$item.IsOnlineMeeting -ne \$null) { [bool]\$item.IsOnlineMeeting } else { \$false }
            }
            \$events += \$event
        } catch {
            continue
        } finally {
            if (\$item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$item) | Out-Null }
        }
    }

    \$events = \$rawEvents | Sort-Object { if ([string]::IsNullOrEmpty(\$_.Start)) { [DateTime]::MinValue } else { [DateTime]::Parse(\$_.Start) } }

    \$json = \$events | ConvertTo-Json -Depth 10
    Write-Output \$json
} finally {
    if (\$items) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$items) | Out-Null }
    if (\$calendar) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$calendar) | Out-Null }
    if (\$namespace) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$namespace) | Out-Null }
    if (\$outlook) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$outlook) | Out-Null }
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

  /// 会議室カレンダーから予定を取得
  Future<List<Map<String, dynamic>>> getRoomCalendarEvents({
    required String roomAddress,
    required DateTime startDate,
    required DateTime endDate,
    String? subjectFilter,
  }) async {
    try {
      final escapedRoom = _escapeForPowerShell(roomAddress);
      final filter = subjectFilter != null && subjectFilter.trim().isNotEmpty
          ? _escapeForPowerShell(subjectFilter.trim())
          : '';

      final script = '''
function Sanitize([string]\$value) {
    if ([string]::IsNullOrEmpty(\$value)) { return "" }
    return (\$value -replace "[\\r\\n\\u0000]", " ").Trim()
}

\$startDate = [DateTime]::Parse("${startDate.toIso8601String()}")
\$endDate = [DateTime]::Parse("${endDate.toIso8601String()}")
\$roomAddress = '${escapedRoom}'
\$subjectPattern = '${filter}'

try {
    \$outlook = New-Object -ComObject Outlook.Application
    \$namespace = \$outlook.GetNamespace("MAPI")
    \$recipient = \$namespace.CreateRecipient(\$roomAddress)
    \$recipient.Resolve() | Out-Null
    if (-not \$recipient.Resolved) {
        throw "会議室が見つかりません: \$roomAddress"
    }

    # 権限チェック：会議室カレンダーへのアクセス権を確認
    try {
        \$calendar = \$namespace.GetSharedDefaultFolder(\$recipient, 9)
        if (\$null -eq \$calendar) {
            throw "会議室カレンダーへのアクセス権がありません: \$roomAddress"
        }
    } catch {
        throw "会議室カレンダーへのアクセス権がありません: \$roomAddress (エラー: \$_)"
    }

    \$items = \$calendar.Items
    if (\$null -eq \$items) {
        throw "会議室カレンダーのアイテムを取得できません: \$roomAddress"
    }
    \$items.IncludeRecurrences = \$true

    \$rawEvents = @()
    \$itemCount = 0
    \$errorCount = 0

    foreach (\$item in \$items) {
        \$itemCount++
        \$itemObject = \$null
        try {
            # Nullチェック
            if (\$null -eq \$item) { continue }
            
            # 型チェック：AppointmentItemかどうかを確認
            try {
                \$itemType = \$item.GetType()
                if (\$itemType -eq \$null) { continue }
            } catch {
                continue
            }
            
            # AppointmentItem型チェック
            if (-not (\$item -is [Microsoft.Office.Interop.Outlook.AppointmentItem])) { continue }
            
            \$itemObject = \$item
            
            # StartプロパティのNullチェック
            if (\$null -eq \$itemObject.Start) { continue }
            
            # 日付範囲チェック
            try {
                \$itemStart = \$itemObject.Start
                if (\$itemStart -lt \$startDate -or \$itemStart -gt \$endDate) { continue }
            } catch {
                continue
            }

            # Subjectの取得とNullチェック
            \$subject = ""
            try {
                if (\$null -ne \$itemObject.Subject) {
                    \$subject = Sanitize(\$itemObject.Subject)
                }
            } catch {
                \$subject = ""
            }

            # 件名フィルタチェック
            if (-not [string]::IsNullOrEmpty(\$subjectPattern)) {
                if ([string]::IsNullOrEmpty(\$subject) -or -not (\$subject -match \$subjectPattern)) {
                    continue
                }
            }

            # 各プロパティを安全に取得
            \$startStr = ""
            \$endStr = ""
            \$location = ""
            \$body = ""
            \$entryId = ""
            \$lastModTime = ""
            \$organizer = ""
            \$isMeeting = \$false
            \$isRecurring = \$false
            \$isOnlineMeeting = \$false

            try {
                if (\$null -ne \$itemObject.Start) {
                    \$startStr = \$itemObject.Start.ToString("o")
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.End) {
                    \$endStr = \$itemObject.End.ToString("o")
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.Location) {
                    \$location = Sanitize(\$itemObject.Location)
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.Body) {
                    \$body = Sanitize(\$itemObject.Body)
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.EntryID) {
                    \$entryId = \$itemObject.EntryID
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.LastModificationTime) {
                    \$lastModTime = \$itemObject.LastModificationTime.ToString("o")
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.Organizer) {
                    \$organizer = Sanitize(\$itemObject.Organizer)
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.IsMeeting) {
                    \$isMeeting = [bool]\$itemObject.IsMeeting
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.IsRecurring) {
                    \$isRecurring = [bool]\$itemObject.IsRecurring
                }
            } catch { }

            try {
                if (\$null -ne \$itemObject.IsOnlineMeeting) {
                    \$isOnlineMeeting = [bool]\$itemObject.IsOnlineMeeting
                }
            } catch { }

            \$rawEvents += @{
                Subject = \$subject
                Start = \$startStr
                End = \$endStr
                Location = \$location
                Body = \$body
                EntryID = \$entryId
                LastModificationTime = \$lastModTime
                Organizer = \$organizer
                IsMeeting = \$isMeeting
                IsRecurring = \$isRecurring
                IsOnlineMeeting = \$isOnlineMeeting
                CalendarOwner = \$roomAddress
            }
        } catch {
            \$errorCount++
            # エラーをスキップして続行
            continue
        } finally {
            # COMオブジェクトの解放
            if (\$null -ne \$itemObject) {
                try {
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$itemObject) | Out-Null
                } catch { }
            }
        }
    }

    \$events = \$rawEvents | Sort-Object { if ([string]::IsNullOrEmpty(\$_.Start)) { [DateTime]::MinValue } else { [DateTime]::Parse(\$_.Start) } }

    \$json = \$events | ConvertTo-Json -Depth 10
    Write-Output \$json
} finally {
    if (\$items) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$items) | Out-Null }
    if (\$calendar) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$calendar) | Out-Null }
    if (\$recipient) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$recipient) | Out-Null }
    if (\$namespace) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$namespace) | Out-Null }
    if (\$outlook) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$outlook) | Out-Null }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
}
''';

      final output = await _runPowerShellScript(script);
      final events = _parseJsonList(output);
      return events;
    } catch (e) {
      ErrorHandler.logError('会議室カレンダー取得', e);
      rethrow;
    }
  }

  /// 会議室候補を検索
  Future<List<Map<String, String>>> searchMeetingRooms({
    String keyword = '',
    int maxResults = 50,
  }) async {
    try {
      final escapedKeyword = _escapeForPowerShell(keyword);
      final script = '''
function Sanitize([string]\$value) {
    if ([string]::IsNullOrEmpty(\$value)) { return "" }
    return (\$value -replace "[\\r\\n\\u0000]", " ").Trim()
}

\$keyword = '${escapedKeyword}'
\$maxResults = ${maxResults}

try {
    \$outlook = New-Object -ComObject Outlook.Application
    \$namespace = \$outlook.GetNamespace("MAPI")
    \$results = @()

    \$addressLists = \$namespace.AddressLists
    \$seenAddresses = @{}
    foreach (\$addressList in \$addressLists) {
        try {
            if (\$null -eq \$addressList) { continue }
            if (\$addressList.AddressEntries -eq \$null) { continue }
            if (-not (\$addressList.Name -match "Room" -or \$addressList.AddressListType -eq 5)) { continue }

            \$entries = \$addressList.AddressEntries
            for (\$i = 1; \$i -le \$entries.Count; \$i++) {
                if (\$results.Count -ge \$maxResults) { break }
                \$entry = \$entries.Item(\$i)
                if (\$null -eq \$entry) { continue }

                \$displayName = Sanitize(\$entry.Name)
                \$address = ""

                try {
                    \$exchangeUser = \$entry.GetExchangeUser()
                    if (\$exchangeUser -ne \$null) {
                        \$address = Sanitize(\$exchangeUser.PrimarySmtpAddress)
                    }
                } catch {
                    if (\$entry.Address -ne \$null) {
                        \$address = Sanitize((\$entry.Address -replace "SMTP:", "" -replace "smtp:", ""))
                    }
                }

                if ([string]::IsNullOrEmpty(\$address)) { continue }
                
                # メールアドレスで重複チェック（大文字小文字を区別しない）
                \$addressLower = \$address.ToLower()
                if (\$seenAddresses.ContainsKey(\$addressLower)) { continue }
                \$seenAddresses[\$addressLower] = \$true

                if (-not [string]::IsNullOrEmpty(\$keyword)) {
                    if ((\$displayName -notmatch [Regex]::Escape(\$keyword)) -and (\$address -notmatch [Regex]::Escape(\$keyword))) {
                        continue
                    }
                }

                \$results += @{
                    Name = \$displayName
                    Address = \$address
                }
            }
        } catch {
            continue
        }

        if (\$results.Count -ge \$maxResults) { break }
    }

    \$json = \$results | Sort-Object Name | ConvertTo-Json -Depth 5
    Write-Output \$json
} finally {
    if (\$addressLists) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$addressLists) | Out-Null }
    if (\$namespace) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$namespace) | Out-Null }
    if (\$outlook) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$outlook) | Out-Null }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
}
''';

      final output = await _runPowerShellScript(script);
      final decoded = json.decode(output.trim().isEmpty ? '[]' : output);
      if (decoded is List) {
        return decoded
            .map((e) => {
                  'name': (e['Name'] ?? '').toString(),
                  'address': (e['Address'] ?? '').toString(),
                })
            .where((e) => e['address']!.isNotEmpty)
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        final name = decoded['Name']?.toString() ?? '';
        final address = decoded['Address']?.toString() ?? '';
        if (address.isNotEmpty) {
          return [
            {'name': name, 'address': address},
          ];
        }
      }
      return [];
    } catch (e) {
      ErrorHandler.logError('会議室候補検索', e);
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

    return result.stdout.toString();
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

