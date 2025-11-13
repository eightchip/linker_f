/// エクスポート設定
class ExportConfig {
  /// エクスポートするグループIDのセット（空の場合は全グループ）
  final Set<String> selectedGroupIds;
  
  /// エクスポートするリンクIDのセット（空の場合は全リンク）
  final Set<String> selectedLinkIds;
  
  /// エクスポートするタスクIDのセット（空の場合は全タスク）
  final Set<String> selectedTaskIds;
  
  /// タスクフィルター設定
  final TaskFilterConfig? taskFilter;
  
  /// エクスポートする設定項目
  final SettingsExportConfig? settingsConfig;
  
  /// メモを含めるか
  final bool includeMemos;
  
  /// テンプレート名（保存時）
  final String? templateName;

  ExportConfig({
    this.selectedGroupIds = const {},
    this.selectedLinkIds = const {},
    this.selectedTaskIds = const {},
    this.taskFilter,
    this.settingsConfig,
    this.includeMemos = true,
    this.templateName,
  });

  ExportConfig copyWith({
    Set<String>? selectedGroupIds,
    Set<String>? selectedLinkIds,
    Set<String>? selectedTaskIds,
    TaskFilterConfig? taskFilter,
    SettingsExportConfig? settingsConfig,
    bool? includeMemos,
    String? templateName,
  }) {
    return ExportConfig(
      selectedGroupIds: selectedGroupIds ?? this.selectedGroupIds,
      selectedLinkIds: selectedLinkIds ?? this.selectedLinkIds,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      taskFilter: taskFilter ?? this.taskFilter,
      settingsConfig: settingsConfig ?? this.settingsConfig,
      includeMemos: includeMemos ?? this.includeMemos,
      templateName: templateName ?? this.templateName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedGroupIds': selectedGroupIds.toList(),
      'selectedLinkIds': selectedLinkIds.toList(),
      'selectedTaskIds': selectedTaskIds.toList(),
      'taskFilter': taskFilter?.toJson(),
      'settingsConfig': settingsConfig?.toJson(),
      'includeMemos': includeMemos,
      'templateName': templateName,
    };
  }

  factory ExportConfig.fromJson(Map<String, dynamic> json) {
    return ExportConfig(
      selectedGroupIds: (json['selectedGroupIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet() ?? {},
      selectedLinkIds: (json['selectedLinkIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet() ?? {},
      selectedTaskIds: (json['selectedTaskIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet() ?? {},
      taskFilter: json['taskFilter'] != null
          ? TaskFilterConfig.fromJson(json['taskFilter'])
          : null,
      settingsConfig: json['settingsConfig'] != null
          ? SettingsExportConfig.fromJson(json['settingsConfig'])
          : null,
      includeMemos: json['includeMemos'] ?? true,
      templateName: json['templateName'] as String?,
    );
  }
}

/// タスクフィルター設定
class TaskFilterConfig {
  /// タグでフィルター（空の場合は全タグ）
  final Set<String> tags;
  
  /// ステータスでフィルター（空の場合は全ステータス）
  final Set<String> statuses;
  
  /// 作成日の開始日
  final DateTime? createdAtStart;
  
  /// 作成日の終了日
  final DateTime? createdAtEnd;
  
  /// 期限日の開始日
  final DateTime? dueDateStart;
  
  /// 期限日の終了日
  final DateTime? dueDateEnd;
  
  /// 関連リンクIDでフィルター（空の場合は全タスク）
  final Set<String> relatedLinkIds;

  TaskFilterConfig({
    this.tags = const {},
    this.statuses = const {},
    this.createdAtStart,
    this.createdAtEnd,
    this.dueDateStart,
    this.dueDateEnd,
    this.relatedLinkIds = const {},
  });

  TaskFilterConfig copyWith({
    Set<String>? tags,
    Set<String>? statuses,
    DateTime? createdAtStart,
    DateTime? createdAtEnd,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
    Set<String>? relatedLinkIds,
  }) {
    return TaskFilterConfig(
      tags: tags ?? this.tags,
      statuses: statuses ?? this.statuses,
      createdAtStart: createdAtStart ?? this.createdAtStart,
      createdAtEnd: createdAtEnd ?? this.createdAtEnd,
      dueDateStart: dueDateStart ?? this.dueDateStart,
      dueDateEnd: dueDateEnd ?? this.dueDateEnd,
      relatedLinkIds: relatedLinkIds ?? this.relatedLinkIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags.toList(),
      'statuses': statuses.toList(),
      'createdAtStart': createdAtStart?.toIso8601String(),
      'createdAtEnd': createdAtEnd?.toIso8601String(),
      'dueDateStart': dueDateStart?.toIso8601String(),
      'dueDateEnd': dueDateEnd?.toIso8601String(),
      'relatedLinkIds': relatedLinkIds.toList(),
    };
  }

  factory TaskFilterConfig.fromJson(Map<String, dynamic> json) {
    return TaskFilterConfig(
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet() ?? {},
      statuses: (json['statuses'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet() ?? {},
      createdAtStart: json['createdAtStart'] != null
          ? DateTime.parse(json['createdAtStart'])
          : null,
      createdAtEnd: json['createdAtEnd'] != null
          ? DateTime.parse(json['createdAtEnd'])
          : null,
      dueDateStart: json['dueDateStart'] != null
          ? DateTime.parse(json['dueDateStart'])
          : null,
      dueDateEnd: json['dueDateEnd'] != null
          ? DateTime.parse(json['dueDateEnd'])
          : null,
      relatedLinkIds: (json['relatedLinkIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet() ?? {},
    );
  }
}

/// 設定エクスポート設定
class SettingsExportConfig {
  /// UI設定を含めるか
  final bool includeUISettings;
  
  /// 機能設定を含めるか
  final bool includeFeatureSettings;
  
  /// 連携設定を含めるか
  final bool includeIntegrationSettings;

  SettingsExportConfig({
    this.includeUISettings = false,
    this.includeFeatureSettings = false,
    this.includeIntegrationSettings = false,
  });

  SettingsExportConfig copyWith({
    bool? includeUISettings,
    bool? includeFeatureSettings,
    bool? includeIntegrationSettings,
  }) {
    return SettingsExportConfig(
      includeUISettings: includeUISettings ?? this.includeUISettings,
      includeFeatureSettings: includeFeatureSettings ?? this.includeFeatureSettings,
      includeIntegrationSettings: includeIntegrationSettings ?? this.includeIntegrationSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeUISettings': includeUISettings,
      'includeFeatureSettings': includeFeatureSettings,
      'includeIntegrationSettings': includeIntegrationSettings,
    };
  }

  factory SettingsExportConfig.fromJson(Map<String, dynamic> json) {
    return SettingsExportConfig(
      includeUISettings: json['includeUISettings'] ?? false,
      includeFeatureSettings: json['includeFeatureSettings'] ?? false,
      includeIntegrationSettings: json['includeIntegrationSettings'] ?? false,
    );
  }
}

/// インポート方法
enum ImportMode {
  add,      // 追加（既存データに追加）
  overwrite, // 上書き（既存データを置き換え）
  merge,    // マージ（重複をチェックして統合）
}

/// 重複処理方法
enum DuplicateHandling {
  skip,     // スキップ
  overwrite, // 上書き
  rename,   // 名前を変更して追加
}

/// インポート設定
class ImportConfig {
  /// インポート方法
  final ImportMode importMode;
  
  /// 重複処理方法
  final DuplicateHandling duplicateHandling;
  
  /// リンクをインポートするか
  final bool importLinks;
  
  /// タスクをインポートするか
  final bool importTasks;
  
  /// 設定をインポートするか
  final bool importSettings;
  
  /// グループをインポートするか
  final bool importGroups;

  ImportConfig({
    this.importMode = ImportMode.add,
    this.duplicateHandling = DuplicateHandling.skip,
    this.importLinks = true,
    this.importTasks = true,
    this.importSettings = false,
    this.importGroups = true,
  });

  ImportConfig copyWith({
    ImportMode? importMode,
    DuplicateHandling? duplicateHandling,
    bool? importLinks,
    bool? importTasks,
    bool? importSettings,
    bool? importGroups,
  }) {
    return ImportConfig(
      importMode: importMode ?? this.importMode,
      duplicateHandling: duplicateHandling ?? this.duplicateHandling,
      importLinks: importLinks ?? this.importLinks,
      importTasks: importTasks ?? this.importTasks,
      importSettings: importSettings ?? this.importSettings,
      importGroups: importGroups ?? this.importGroups,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importMode': importMode.toString().split('.').last,
      'duplicateHandling': duplicateHandling.toString().split('.').last,
      'importLinks': importLinks,
      'importTasks': importTasks,
      'importSettings': importSettings,
      'importGroups': importGroups,
    };
  }

  factory ImportConfig.fromJson(Map<String, dynamic> json) {
    return ImportConfig(
      importMode: ImportMode.values.firstWhere(
        (e) => e.toString().split('.').last == json['importMode'],
        orElse: () => ImportMode.add,
      ),
      duplicateHandling: DuplicateHandling.values.firstWhere(
        (e) => e.toString().split('.').last == json['duplicateHandling'],
        orElse: () => DuplicateHandling.skip,
      ),
      importLinks: json['importLinks'] ?? true,
      importTasks: json['importTasks'] ?? true,
      importSettings: json['importSettings'] ?? false,
      importGroups: json['importGroups'] ?? true,
    );
  }
}

