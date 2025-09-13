import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async';
import '../models/group.dart';
import '../models/link_item.dart';
import '../models/task_item.dart';
import '../viewmodels/layout_settings_provider.dart';
import '../viewmodels/task_viewmodel.dart';
import 'home_screen.dart';
import 'task_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ハイライト用のウィジェット
class HighlightedText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;

  const HighlightedText({
    Key? key,
    required this.text,
    this.highlight,
    this.style,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (highlight == null || highlight!.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    // 複数キーワードに対応
    final keywords = highlight!.toLowerCase().split(' ').where((k) => k.isNotEmpty).toList();
    if (keywords.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final textLower = text.toLowerCase();
    final matches = <_TextMatch>[];

    // 各キーワードのマッチを検索
    for (final keyword in keywords) {
      int start = 0;
      while (start < textLower.length) {
        final index = textLower.indexOf(keyword, start);
        if (index == -1) break;
        matches.add(_TextMatch(index, index + keyword.length));
        start = index + 1;
      }
    }

    // マッチを開始位置でソート
    matches.sort((a, b) => a.start.compareTo(b.start));

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in matches) {
      if (currentIndex < match.start) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style?.copyWith(
          backgroundColor: Colors.red.withValues(alpha: 0.75),
          fontWeight: FontWeight.bold,
          color: style?.color ?? Colors.black, // 元の文字色を保持
        ),
      ));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(
        style: style, // デフォルトスタイルを設定
        children: spans,
      ),
      overflow: overflow ?? TextOverflow.clip,
      maxLines: maxLines,
    );
  }
}

class _TextMatch {
  final int start;
  final int end;
  _TextMatch(this.start, this.end);
}

// アイコン構築用のミックスイン
mixin IconBuilderMixin {
  // カラフルアイコンウィジェットを構築
  Widget buildIconWidget(IconData iconData, Color color, {double size = 20}) {
    // Font Awesomeアイコンの場合はブランドカラーを適用
    if (iconData.fontFamily == 'FontAwesomeSolid' || 
        iconData.fontFamily == 'FontAwesomeRegular' || 
        iconData.fontFamily == 'FontAwesomeBrands') {
      return buildBrandIcon(iconData, size: size);
    }
    // Material Iconsの場合は指定された色を使用
    return Icon(iconData, color: color, size: size);
  }

  // codePointからIconDataを復元するメソッド
  IconData? restoreIconData(int? codePoint) {
    if (codePoint == null) return null;
    
    // Font AwesomeアイコンのcodePointをチェック
    if (codePoint == FontAwesomeIcons.google.codePoint) return FontAwesomeIcons.google;
    if (codePoint == FontAwesomeIcons.github.codePoint) return FontAwesomeIcons.github;
    if (codePoint == FontAwesomeIcons.youtube.codePoint) return FontAwesomeIcons.youtube;
    if (codePoint == FontAwesomeIcons.twitter.codePoint) return FontAwesomeIcons.twitter;
    if (codePoint == FontAwesomeIcons.facebook.codePoint) return FontAwesomeIcons.facebook;
    if (codePoint == FontAwesomeIcons.instagram.codePoint) return FontAwesomeIcons.instagram;
    if (codePoint == FontAwesomeIcons.linkedin.codePoint) return FontAwesomeIcons.linkedin;
    if (codePoint == FontAwesomeIcons.discord.codePoint) return FontAwesomeIcons.discord;
    if (codePoint == FontAwesomeIcons.slack.codePoint) return FontAwesomeIcons.slack;
    if (codePoint == FontAwesomeIcons.spotify.codePoint) return FontAwesomeIcons.spotify;
    if (codePoint == FontAwesomeIcons.amazon.codePoint) return FontAwesomeIcons.amazon;
    if (codePoint == FontAwesomeIcons.apple.codePoint) return FontAwesomeIcons.apple;
    if (codePoint == FontAwesomeIcons.microsoft.codePoint) return FontAwesomeIcons.microsoft;
    if (codePoint == FontAwesomeIcons.chrome.codePoint) return FontAwesomeIcons.chrome;
    if (codePoint == FontAwesomeIcons.firefox.codePoint) return FontAwesomeIcons.firefox;
    if (codePoint == FontAwesomeIcons.safari.codePoint) return FontAwesomeIcons.safari;
    if (codePoint == FontAwesomeIcons.edge.codePoint) return FontAwesomeIcons.edge;
    if (codePoint == FontAwesomeIcons.opera.codePoint) return FontAwesomeIcons.opera;
    if (codePoint == FontAwesomeIcons.steam.codePoint) return FontAwesomeIcons.steam;
    if (codePoint == FontAwesomeIcons.reddit.codePoint) return FontAwesomeIcons.reddit;
    if (codePoint == FontAwesomeIcons.stackOverflow.codePoint) return FontAwesomeIcons.stackOverflow;
    if (codePoint == FontAwesomeIcons.gitlab.codePoint) return FontAwesomeIcons.gitlab;
    if (codePoint == FontAwesomeIcons.bitbucket.codePoint) return FontAwesomeIcons.bitbucket;
    if (codePoint == FontAwesomeIcons.docker.codePoint) return FontAwesomeIcons.docker;
    if (codePoint == FontAwesomeIcons.aws.codePoint) return FontAwesomeIcons.aws;
    if (codePoint == FontAwesomeIcons.wordpress.codePoint) return FontAwesomeIcons.wordpress;
    if (codePoint == FontAwesomeIcons.shopify.codePoint) return FontAwesomeIcons.shopify;
    if (codePoint == FontAwesomeIcons.stripe.codePoint) return FontAwesomeIcons.stripe;
    if (codePoint == FontAwesomeIcons.paypal.codePoint) return FontAwesomeIcons.paypal;
    if (codePoint == FontAwesomeIcons.bitcoin.codePoint) return FontAwesomeIcons.bitcoin;
    if (codePoint == FontAwesomeIcons.ethereum.codePoint) return FontAwesomeIcons.ethereum;
    if (codePoint == FontAwesomeIcons.telegram.codePoint) return FontAwesomeIcons.telegram;
    if (codePoint == FontAwesomeIcons.whatsapp.codePoint) return FontAwesomeIcons.whatsapp;
    if (codePoint == FontAwesomeIcons.skype.codePoint) return FontAwesomeIcons.skype;
    if (codePoint == FontAwesomeIcons.dropbox.codePoint) return FontAwesomeIcons.dropbox;
    if (codePoint == FontAwesomeIcons.box.codePoint) return FontAwesomeIcons.box;
    if (codePoint == FontAwesomeIcons.figma.codePoint) return FontAwesomeIcons.figma;
    if (codePoint == FontAwesomeIcons.blender.codePoint) return FontAwesomeIcons.blender;
    if (codePoint == FontAwesomeIcons.python.codePoint) return FontAwesomeIcons.python;
    if (codePoint == FontAwesomeIcons.react.codePoint) return FontAwesomeIcons.react;
    if (codePoint == FontAwesomeIcons.angular.codePoint) return FontAwesomeIcons.angular;
    if (codePoint == FontAwesomeIcons.flutter.codePoint) return FontAwesomeIcons.flutter;
    if (codePoint == FontAwesomeIcons.bootstrap.codePoint) return FontAwesomeIcons.bootstrap;
    if (codePoint == FontAwesomeIcons.node.codePoint) return FontAwesomeIcons.node;
    if (codePoint == FontAwesomeIcons.npm.codePoint) return FontAwesomeIcons.npm;
    if (codePoint == FontAwesomeIcons.yarn.codePoint) return FontAwesomeIcons.yarn;
    if (codePoint == FontAwesomeIcons.git.codePoint) return FontAwesomeIcons.git;
    if (codePoint == FontAwesomeIcons.linux.codePoint) return FontAwesomeIcons.linux;
    if (codePoint == FontAwesomeIcons.windows.codePoint) return FontAwesomeIcons.windows;
    if (codePoint == FontAwesomeIcons.android.codePoint) return FontAwesomeIcons.android;
    if (codePoint == FontAwesomeIcons.html5.codePoint) return FontAwesomeIcons.html5;
    if (codePoint == FontAwesomeIcons.css3.codePoint) return FontAwesomeIcons.css3;
    if (codePoint == FontAwesomeIcons.js.codePoint) return FontAwesomeIcons.js;
    if (codePoint == FontAwesomeIcons.php.codePoint) return FontAwesomeIcons.php;
    if (codePoint == FontAwesomeIcons.java.codePoint) return FontAwesomeIcons.java;
    if (codePoint == FontAwesomeIcons.c.codePoint) return FontAwesomeIcons.c;
    if (codePoint == FontAwesomeIcons.swift.codePoint) return FontAwesomeIcons.swift;
    if (codePoint == FontAwesomeIcons.r.codePoint) return FontAwesomeIcons.r;
    if (codePoint == FontAwesomeIcons.salesforce.codePoint) return FontAwesomeIcons.salesforce;
    if (codePoint == FontAwesomeIcons.hubspot.codePoint) return FontAwesomeIcons.hubspot;
    if (codePoint == FontAwesomeIcons.mailchimp.codePoint) return FontAwesomeIcons.mailchimp;
    if (codePoint == FontAwesomeIcons.trello.codePoint) return FontAwesomeIcons.trello;
    
    // Material IconsのcodePointをチェック
    if (codePoint == Icons.public.codePoint) return Icons.public;
    if (codePoint == Icons.folder.codePoint) return Icons.folder;
    if (codePoint == Icons.folder_open.codePoint) return Icons.folder_open;
    if (codePoint == Icons.folder_special.codePoint) return Icons.folder_special;
    if (codePoint == Icons.folder_shared.codePoint) return Icons.folder_shared;
    if (codePoint == Icons.folder_zip.codePoint) return Icons.folder_zip;
    if (codePoint == Icons.folder_copy.codePoint) return Icons.folder_copy;
    if (codePoint == Icons.folder_delete.codePoint) return Icons.folder_delete;
    if (codePoint == Icons.folder_off.codePoint) return Icons.folder_off;
    if (codePoint == Icons.folder_outlined.codePoint) return Icons.folder_outlined;
    if (codePoint == Icons.folder_open_outlined.codePoint) return Icons.folder_open_outlined;
    if (codePoint == Icons.folder_special_outlined.codePoint) return Icons.folder_special_outlined;
    if (codePoint == Icons.folder_shared_outlined.codePoint) return Icons.folder_shared_outlined;
    if (codePoint == Icons.folder_zip_outlined.codePoint) return Icons.folder_zip_outlined;
    if (codePoint == Icons.folder_copy_outlined.codePoint) return Icons.folder_copy_outlined;
    if (codePoint == Icons.folder_delete_outlined.codePoint) return Icons.folder_delete_outlined;
    if (codePoint == Icons.folder_off_outlined.codePoint) return Icons.folder_off_outlined;
    if (codePoint == Icons.drive_folder_upload.codePoint) return Icons.drive_folder_upload;
    if (codePoint == Icons.drive_folder_upload_outlined.codePoint) return Icons.drive_folder_upload_outlined;
    if (codePoint == Icons.drive_file_move.codePoint) return Icons.drive_file_move;
    if (codePoint == Icons.drive_file_move_outlined.codePoint) return Icons.drive_file_move_outlined;
    if (codePoint == Icons.drive_file_rename_outline.codePoint) return Icons.drive_file_rename_outline;
    if (codePoint == Icons.drive_file_rename_outline_outlined.codePoint) return Icons.drive_file_rename_outline_outlined;
    if (codePoint == Icons.book.codePoint) return Icons.book;
    if (codePoint == Icons.book_outlined.codePoint) return Icons.book_outlined;
    if (codePoint == Icons.bookmark.codePoint) return Icons.bookmark;
    if (codePoint == Icons.bookmark_outlined.codePoint) return Icons.bookmark_outlined;
    if (codePoint == Icons.favorite.codePoint) return Icons.favorite;
    if (codePoint == Icons.favorite_outlined.codePoint) return Icons.favorite_outlined;
    if (codePoint == Icons.star.codePoint) return Icons.star;
    if (codePoint == Icons.star_outlined.codePoint) return Icons.star_outlined;
    if (codePoint == Icons.home.codePoint) return Icons.home;
    if (codePoint == Icons.home_outlined.codePoint) return Icons.home_outlined;
    if (codePoint == Icons.work.codePoint) return Icons.work;
    if (codePoint == Icons.work_outlined.codePoint) return Icons.work_outlined;
    if (codePoint == Icons.school.codePoint) return Icons.school;
    if (codePoint == Icons.school_outlined.codePoint) return Icons.school_outlined;
    if (codePoint == Icons.business.codePoint) return Icons.business;
    if (codePoint == Icons.business_outlined.codePoint) return Icons.business_outlined;
    if (codePoint == Icons.store.codePoint) return Icons.store;
    if (codePoint == Icons.store_outlined.codePoint) return Icons.store_outlined;
    if (codePoint == Icons.shopping_cart.codePoint) return Icons.shopping_cart;
    if (codePoint == Icons.shopping_cart_outlined.codePoint) return Icons.shopping_cart_outlined;
    if (codePoint == Icons.music_note.codePoint) return Icons.music_note;
    if (codePoint == Icons.music_note_outlined.codePoint) return Icons.music_note_outlined;
    if (codePoint == Icons.photo.codePoint) return Icons.photo;
    if (codePoint == Icons.photo_outlined.codePoint) return Icons.photo_outlined;
    if (codePoint == Icons.video_library.codePoint) return Icons.video_library;
    if (codePoint == Icons.video_library_outlined.codePoint) return Icons.video_library_outlined;
    if (codePoint == Icons.download.codePoint) return Icons.download;
    if (codePoint == Icons.download_outlined.codePoint) return Icons.download_outlined;
    if (codePoint == Icons.upload.codePoint) return Icons.upload;
    if (codePoint == Icons.upload_outlined.codePoint) return Icons.upload_outlined;
    
    // その他のMaterial Icons（ビジネス向け）
    if (codePoint == Icons.account_balance.codePoint) return Icons.account_balance;
    if (codePoint == Icons.account_balance_outlined.codePoint) return Icons.account_balance_outlined;
    if (codePoint == Icons.analytics.codePoint) return Icons.analytics;
    if (codePoint == Icons.analytics_outlined.codePoint) return Icons.analytics_outlined;
    if (codePoint == Icons.assessment.codePoint) return Icons.assessment;
    if (codePoint == Icons.assessment_outlined.codePoint) return Icons.assessment_outlined;
    if (codePoint == Icons.bar_chart.codePoint) return Icons.bar_chart;
    if (codePoint == Icons.bar_chart_outlined.codePoint) return Icons.bar_chart_outlined;
    if (codePoint == Icons.pie_chart.codePoint) return Icons.pie_chart;
    if (codePoint == Icons.trending_up.codePoint) return Icons.trending_up;
    if (codePoint == Icons.trending_up_outlined.codePoint) return Icons.trending_up_outlined;
    if (codePoint == Icons.trending_down.codePoint) return Icons.trending_down;
    if (codePoint == Icons.trending_down_outlined.codePoint) return Icons.trending_down_outlined;
    if (codePoint == Icons.show_chart.codePoint) return Icons.show_chart;
    if (codePoint == Icons.show_chart_outlined.codePoint) return Icons.show_chart_outlined;
    if (codePoint == Icons.insert_chart.codePoint) return Icons.insert_chart;
    if (codePoint == Icons.insert_chart_outlined.codePoint) return Icons.insert_chart_outlined;
    if (codePoint == Icons.query_stats.codePoint) return Icons.query_stats;
    if (codePoint == Icons.query_stats_outlined.codePoint) return Icons.query_stats_outlined;
    if (codePoint == Icons.insights.codePoint) return Icons.insights;
    if (codePoint == Icons.insights_outlined.codePoint) return Icons.insights_outlined;
    if (codePoint == Icons.psychology.codePoint) return Icons.psychology;
    if (codePoint == Icons.psychology_outlined.codePoint) return Icons.psychology_outlined;
    if (codePoint == Icons.engineering.codePoint) return Icons.engineering;
    if (codePoint == Icons.engineering_outlined.codePoint) return Icons.engineering_outlined;
    if (codePoint == Icons.architecture.codePoint) return Icons.architecture;
    if (codePoint == Icons.architecture_outlined.codePoint) return Icons.architecture_outlined;
    if (codePoint == Icons.construction.codePoint) return Icons.construction;
    if (codePoint == Icons.construction_outlined.codePoint) return Icons.construction_outlined;
    if (codePoint == Icons.precision_manufacturing.codePoint) return Icons.precision_manufacturing;
    if (codePoint == Icons.precision_manufacturing_outlined.codePoint) return Icons.precision_manufacturing_outlined;
    if (codePoint == Icons.security.codePoint) return Icons.security;
    if (codePoint == Icons.security_outlined.codePoint) return Icons.security_outlined;
    if (codePoint == Icons.verified_user.codePoint) return Icons.verified_user;
    if (codePoint == Icons.verified_user_outlined.codePoint) return Icons.verified_user_outlined;
    if (codePoint == Icons.admin_panel_settings.codePoint) return Icons.admin_panel_settings;
    if (codePoint == Icons.admin_panel_settings_outlined.codePoint) return Icons.admin_panel_settings_outlined;
    if (codePoint == Icons.vpn_key.codePoint) return Icons.vpn_key;
    if (codePoint == Icons.vpn_key_outlined.codePoint) return Icons.vpn_key_outlined;
    if (codePoint == Icons.lock.codePoint) return Icons.lock;
    if (codePoint == Icons.lock_outlined.codePoint) return Icons.lock_outlined;
    if (codePoint == Icons.lock_open.codePoint) return Icons.lock_open;
    if (codePoint == Icons.lock_open_outlined.codePoint) return Icons.lock_open_outlined;
    if (codePoint == Icons.local_shipping.codePoint) return Icons.local_shipping;
    if (codePoint == Icons.local_shipping_outlined.codePoint) return Icons.local_shipping_outlined;
    if (codePoint == Icons.delivery_dining.codePoint) return Icons.delivery_dining;
    if (codePoint == Icons.delivery_dining_outlined.codePoint) return Icons.delivery_dining_outlined;
    if (codePoint == Icons.flight.codePoint) return Icons.flight;
    if (codePoint == Icons.flight_outlined.codePoint) return Icons.flight_outlined;
    if (codePoint == Icons.directions_car.codePoint) return Icons.directions_car;
    if (codePoint == Icons.directions_car_outlined.codePoint) return Icons.directions_car_outlined;
    if (codePoint == Icons.directions_bus.codePoint) return Icons.directions_bus;
    if (codePoint == Icons.directions_bus_outlined.codePoint) return Icons.directions_bus_outlined;
    if (codePoint == Icons.directions_train.codePoint) return Icons.directions_train;
    if (codePoint == Icons.directions_train_outlined.codePoint) return Icons.directions_train_outlined;
    if (codePoint == Icons.directions_boat.codePoint) return Icons.directions_boat;
    if (codePoint == Icons.directions_boat_outlined.codePoint) return Icons.directions_boat_outlined;
    if (codePoint == Icons.directions_walk.codePoint) return Icons.directions_walk;
    if (codePoint == Icons.directions_walk_outlined.codePoint) return Icons.directions_walk_outlined;
    if (codePoint == Icons.directions_bike.codePoint) return Icons.directions_bike;
    if (codePoint == Icons.directions_bike_outlined.codePoint) return Icons.directions_bike_outlined;
    if (codePoint == Icons.local_taxi.codePoint) return Icons.local_taxi;
    if (codePoint == Icons.local_taxi_outlined.codePoint) return Icons.local_taxi_outlined;
    if (codePoint == Icons.local_airport.codePoint) return Icons.local_airport;
    if (codePoint == Icons.local_airport_outlined.codePoint) return Icons.local_airport_outlined;
    if (codePoint == Icons.local_gas_station.codePoint) return Icons.local_gas_station;
    if (codePoint == Icons.local_gas_station_outlined.codePoint) return Icons.local_gas_station_outlined;
    if (codePoint == Icons.local_hotel.codePoint) return Icons.local_hotel;
    if (codePoint == Icons.local_hotel_outlined.codePoint) return Icons.local_hotel_outlined;
    if (codePoint == Icons.local_restaurant.codePoint) return Icons.local_restaurant;
    if (codePoint == Icons.local_restaurant_outlined.codePoint) return Icons.local_restaurant_outlined;
    if (codePoint == Icons.local_cafe.codePoint) return Icons.local_cafe;
    if (codePoint == Icons.local_cafe_outlined.codePoint) return Icons.local_cafe_outlined;
    if (codePoint == Icons.local_bar.codePoint) return Icons.local_bar;
    if (codePoint == Icons.local_bar_outlined.codePoint) return Icons.local_bar_outlined;
    if (codePoint == Icons.local_pizza.codePoint) return Icons.local_pizza;
    if (codePoint == Icons.local_pizza_outlined.codePoint) return Icons.local_pizza_outlined;
    if (codePoint == Icons.local_dining.codePoint) return Icons.local_dining;
    if (codePoint == Icons.local_dining_outlined.codePoint) return Icons.local_dining_outlined;
    if (codePoint == Icons.local_laundry_service.codePoint) return Icons.local_laundry_service;
    if (codePoint == Icons.local_laundry_service_outlined.codePoint) return Icons.local_laundry_service_outlined;
    if (codePoint == Icons.celebration.codePoint) return Icons.celebration;
    if (codePoint == Icons.celebration_outlined.codePoint) return Icons.celebration_outlined;
    if (codePoint == Icons.cake.codePoint) return Icons.cake;
    if (codePoint == Icons.cake_outlined.codePoint) return Icons.cake_outlined;
    if (codePoint == Icons.public.codePoint) return Icons.public;
    if (codePoint == Icons.public_outlined.codePoint) return Icons.public_outlined;
    
    return null;
  }

  // ブランドアイコンを構築（カラフル）
  Widget buildBrandIcon(IconData iconData, {double size = 20}) {
    Color brandColor = Colors.grey; // デフォルト色
    
    // ブランドカラーの定義
    if (iconData.codePoint == FontAwesomeIcons.google.codePoint) {
      brandColor = const Color(0xFF4285F4); // Google Blue
    } else if (iconData.codePoint == FontAwesomeIcons.github.codePoint) {
      brandColor = const Color(0xFF181717); // GitHub Black
    } else if (iconData.codePoint == FontAwesomeIcons.youtube.codePoint) {
      brandColor = const Color(0xFFFF0000); // YouTube Red
    } else if (iconData.codePoint == FontAwesomeIcons.twitter.codePoint) {
      brandColor = const Color(0xFF1DA1F2); // Twitter Blue
    } else if (iconData.codePoint == FontAwesomeIcons.facebook.codePoint) {
      brandColor = const Color(0xFF1877F2); // Facebook Blue
    } else if (iconData.codePoint == FontAwesomeIcons.instagram.codePoint) {
      brandColor = const Color(0xFFE4405F); // Instagram Pink
    } else if (iconData.codePoint == FontAwesomeIcons.linkedin.codePoint) {
      brandColor = const Color(0xFF0A66C2); // LinkedIn Blue
    } else if (iconData.codePoint == FontAwesomeIcons.discord.codePoint) {
      brandColor = const Color(0xFF5865F2); // Discord Blue
    } else if (iconData.codePoint == FontAwesomeIcons.slack.codePoint) {
      brandColor = const Color(0xFF4A154B); // Slack Purple
    } else if (iconData.codePoint == FontAwesomeIcons.spotify.codePoint) {
      brandColor = const Color(0xFF1DB954); // Spotify Green
    } else if (iconData.codePoint == FontAwesomeIcons.amazon.codePoint) {
      brandColor = const Color(0xFFFF9900); // Amazon Orange
    } else if (iconData.codePoint == FontAwesomeIcons.apple.codePoint) {
      brandColor = const Color(0xFF000000); // Apple Black
    } else if (iconData.codePoint == FontAwesomeIcons.microsoft.codePoint) {
      brandColor = const Color(0xFF00A4EF); // Microsoft Blue
    } else if (iconData.codePoint == FontAwesomeIcons.chrome.codePoint) {
      brandColor = const Color(0xFF4285F4); // Chrome Blue
    } else if (iconData.codePoint == FontAwesomeIcons.firefox.codePoint) {
      brandColor = const Color(0xFFFF7139); // Firefox Orange
    } else if (iconData.codePoint == FontAwesomeIcons.safari.codePoint) {
      brandColor = const Color(0xFF006CFF); // Safari Blue
    } else if (iconData.codePoint == FontAwesomeIcons.edge.codePoint) {
      brandColor = const Color(0xFF0078D4); // Edge Blue
    } else if (iconData.codePoint == FontAwesomeIcons.opera.codePoint) {
      brandColor = const Color(0xFFFF1B2D); // Opera Red
    } else if (iconData.codePoint == FontAwesomeIcons.steam.codePoint) {
      brandColor = const Color(0xFF00ADE6); // Steam Blue
    } else if (iconData.codePoint == FontAwesomeIcons.reddit.codePoint) {
      brandColor = const Color(0xFFFF4500); // Reddit Orange
    } else if (iconData.codePoint == FontAwesomeIcons.stackOverflow.codePoint) {
      brandColor = const Color(0xFFF58025); // Stack Overflow Orange
    } else if (iconData.codePoint == FontAwesomeIcons.gitlab.codePoint) {
      brandColor = const Color(0xFFFCA326); // GitLab Orange
    } else if (iconData.codePoint == FontAwesomeIcons.bitbucket.codePoint) {
      brandColor = const Color(0xFF0052CC); // Bitbucket Blue
    } else if (iconData.codePoint == FontAwesomeIcons.docker.codePoint) {
      brandColor = const Color(0xFF2496ED); // Docker Blue
    } else if (iconData.codePoint == FontAwesomeIcons.aws.codePoint) {
      brandColor = const Color(0xFFFF9900); // AWS Orange
    } else if (iconData.codePoint == FontAwesomeIcons.wordpress.codePoint) {
      brandColor = const Color(0xFF21759B); // WordPress Blue
    } else if (iconData.codePoint == FontAwesomeIcons.shopify.codePoint) {
      brandColor = const Color(0xFF7AB55C); // Shopify Green
    } else if (iconData.codePoint == FontAwesomeIcons.stripe.codePoint) {
      brandColor = const Color(0xFF6772E5); // Stripe Purple
    } else if (iconData.codePoint == FontAwesomeIcons.paypal.codePoint) {
      brandColor = const Color(0xFF003087); // PayPal Blue
    } else if (iconData.codePoint == FontAwesomeIcons.bitcoin.codePoint) {
      brandColor = const Color(0xFFF7931A); // Bitcoin Orange
    } else if (iconData.codePoint == FontAwesomeIcons.ethereum.codePoint) {
      brandColor = const Color(0xFF627EEA); // Ethereum Blue
    } else if (iconData.codePoint == FontAwesomeIcons.telegram.codePoint) {
      brandColor = const Color(0xFF0088CC); // Telegram Blue
    } else if (iconData.codePoint == FontAwesomeIcons.whatsapp.codePoint) {
      brandColor = const Color(0xFF25D366); // WhatsApp Green
    } else if (iconData.codePoint == FontAwesomeIcons.skype.codePoint) {
      brandColor = const Color(0xFF00AFF0); // Skype Blue
    } else if (iconData.codePoint == FontAwesomeIcons.dropbox.codePoint) {
      brandColor = const Color(0xFF0061FF); // Dropbox Blue
    } else if (iconData.codePoint == FontAwesomeIcons.box.codePoint) {
      brandColor = const Color(0xFF0061D5); // Box Blue
    } else if (iconData.codePoint == FontAwesomeIcons.figma.codePoint) {
      brandColor = const Color(0xFFF24E1E); // Figma Orange
    } else if (iconData.codePoint == FontAwesomeIcons.blender.codePoint) {
      brandColor = const Color(0xFFF5792A); // Blender Orange
    } else if (iconData.codePoint == FontAwesomeIcons.python.codePoint) {
      brandColor = const Color(0xFF3776AB); // Python Blue
    } else if (iconData.codePoint == FontAwesomeIcons.react.codePoint) {
      brandColor = const Color(0xFF61DAFB); // React Blue
    } else if (iconData.codePoint == FontAwesomeIcons.angular.codePoint) {
      brandColor = const Color(0xFFDD0031); // Angular Red
    } else if (iconData.codePoint == FontAwesomeIcons.flutter.codePoint) {
      brandColor = const Color(0xFF02569B); // Flutter Blue
    } else if (iconData.codePoint == FontAwesomeIcons.bootstrap.codePoint) {
      brandColor = const Color(0xFF7952B3); // Bootstrap Purple
    } else if (iconData.codePoint == FontAwesomeIcons.node.codePoint) {
      brandColor = const Color(0xFF339933); // Node.js Green
    } else if (iconData.codePoint == FontAwesomeIcons.npm.codePoint) {
      brandColor = const Color(0xFFCB3837); // npm Red
    } else if (iconData.codePoint == FontAwesomeIcons.yarn.codePoint) {
      brandColor = const Color(0xFF2C8EBB); // Yarn Blue
    } else if (iconData.codePoint == FontAwesomeIcons.git.codePoint) {
      brandColor = const Color(0xFFF05032); // Git Orange
    } else if (iconData.codePoint == FontAwesomeIcons.linux.codePoint) {
      brandColor = const Color(0xFFFCC624); // Linux Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.windows.codePoint) {
      brandColor = const Color(0xFF0078D4); // Windows Blue
    } else if (iconData.codePoint == FontAwesomeIcons.android.codePoint) {
      brandColor = const Color(0xFF3DDC84); // Android Green
    } else if (iconData.codePoint == FontAwesomeIcons.html5.codePoint) {
      brandColor = const Color(0xFFE34F26); // HTML5 Orange
    } else if (iconData.codePoint == FontAwesomeIcons.css3.codePoint) {
      brandColor = const Color(0xFF1572B6); // CSS3 Blue
    } else if (iconData.codePoint == FontAwesomeIcons.js.codePoint) {
      brandColor = const Color(0xFFF7DF1E); // JavaScript Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.php.codePoint) {
      brandColor = const Color(0xFF777BB4); // PHP Purple
    } else if (iconData.codePoint == FontAwesomeIcons.java.codePoint) {
      brandColor = const Color(0xFFED8B00); // Java Orange
    } else if (iconData.codePoint == FontAwesomeIcons.c.codePoint) {
      brandColor = const Color(0xFFA8B9CC); // C Gray
    } else if (iconData.codePoint == FontAwesomeIcons.swift.codePoint) {
      brandColor = const Color(0xFFFA7343); // Swift Orange
    } else if (iconData.codePoint == FontAwesomeIcons.r.codePoint) {
      brandColor = const Color(0xFF276DC3); // R Blue
    } else if (iconData.codePoint == FontAwesomeIcons.salesforce.codePoint) {
      brandColor = const Color(0xFF00A1E0); // Salesforce Blue
    } else if (iconData.codePoint == FontAwesomeIcons.hubspot.codePoint) {
      brandColor = const Color(0xFFFF7A59); // HubSpot Orange
    } else if (iconData.codePoint == FontAwesomeIcons.mailchimp.codePoint) {
      brandColor = const Color(0xFFFFE01B); // Mailchimp Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.trello.codePoint) {
      brandColor = const Color(0xFF0079BF); // Trello Blue
    }
    
    return Icon(iconData, color: brandColor, size: size);
  }
}

class GroupCard extends ConsumerStatefulWidget with IconBuilderMixin {
  final Group group;
  final VoidCallback onToggleCollapse;
  final VoidCallback onDeleteGroup;
  final VoidCallback onAddLink;
  final Function(String) onDeleteLink;
  final Function(LinkItem) onLaunchLink;
  final Future<void> Function(String label, String path, LinkType type)? onDropAddLink;
  final Future<void> Function(LinkItem updated) onEditLink;
  final Future<void> Function(List<LinkItem> newOrder) onReorderLinks;
  final void Function(Offset newPosition)? onMove;
  final bool isDragging;
  final void Function(String newTitle)? onEditGroupTitle;
  final void Function(Group) onFavoriteToggle;
  final void Function(Group, LinkItem) onLinkFavoriteToggle;
  final void Function(LinkItem link, String fromGroupId, String toGroupId)? onMoveLinkToGroup;
  final void Function(String, {IconData? icon, Color? color}) onShowMessage;
  final String? searchQuery;

  const GroupCard({
    Key? key,
    required this.group,
    required this.onToggleCollapse,
    required this.onDeleteGroup,
    required this.onAddLink,
    required this.onDeleteLink,
    required this.onLaunchLink,
    this.onDropAddLink,
    required this.onEditLink,
    required this.onReorderLinks,
    this.onMove,
    this.isDragging = false,
    this.onEditGroupTitle,
    required this.onFavoriteToggle,
    required this.onLinkFavoriteToggle,
    this.onMoveLinkToGroup,
    required this.onShowMessage,
    this.searchQuery,
  }) : super(key: key);

  @override
  ConsumerState<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<GroupCard> {
  bool _isDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final isDropOrHover = _isDropTarget || widget.isDragging;
    final borderColor = widget.group.color != null ? Color(widget.group.color!) : Colors.blue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('DEBUG: GroupCard for "${widget.group.title}" id=${widget.group.id} color=${widget.group.color} borderColor=$borderColor');
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: double.infinity, // 親コンテナに合わせて幅を調整
      height: double.infinity, // 親コンテナに合わせて高さを調整
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isDropOrHover ? borderColor : borderColor.withValues(alpha: 0.7),
          width: isDropOrHover ? 8 : 4,
        ),
        borderRadius: BorderRadius.circular(20), // より丸みを帯びたデザイン
        boxShadow: [
          // メインシャドウ（より深い影）
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: isDropOrHover ? 0.4 : 0.3)
              : Colors.black.withValues(alpha: isDropOrHover ? 0.25 : 0.15),
            blurRadius: isDropOrHover ? 32 : 16,
            offset: const Offset(0, 8),
            spreadRadius: isDropOrHover ? 4 : 2,
          ),
          // アクセントシャドウ（ボーダーカラー連動）
          if (isDropOrHover)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          // ハイライトシャドウ（上部の光沢効果）
          BoxShadow(
            color: isDark 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: DropTarget(
        onDragEntered: (detail) => setState(() => _isDropTarget = true),
        onDragExited: (detail) => setState(() => _isDropTarget = false),
        onDragDone: (detail) {
          setState(() => _isDropTarget = false);
          _handleDrop(context, detail);
        },
        child: Card(
          elevation: isDropOrHover ? 32 : 12, // より高いエレベーション
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.transparent, width: 0),
          ),
          child: _GroupCardContent(
            group: widget.group,
            isDragging: widget.isDragging,
            onToggleCollapse: widget.onToggleCollapse,
            onDeleteGroup: widget.onDeleteGroup,
            onAddLink: widget.onAddLink,
            onDeleteLink: widget.onDeleteLink,
            onLaunchLink: widget.onLaunchLink,
            onDropAddLink: widget.onDropAddLink,
            onEditLink: widget.onEditLink,
            onReorderLinks: widget.onReorderLinks,
            onMove: widget.onMove,
            onEditGroupTitle: widget.onEditGroupTitle,
            onFavoriteToggle: widget.onFavoriteToggle,
            onLinkFavoriteToggle: widget.onLinkFavoriteToggle,
            onMoveLinkToGroup: widget.onMoveLinkToGroup,
            searchQuery: widget.searchQuery,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms);
  }

  void _handleDrop(BuildContext context, dynamic detail) async {
    bool added = false;
    List<String> failed = [];
    List<String> urls = [];
    int fileCount = 0;
    int folderCount = 0;
    int urlCount = 0;
    
    // ファイルとフォルダの処理
    if (detail.files != null && detail.files.isNotEmpty) {
      for (final file in detail.files) {
        final path = file.path;
        
        // URLの処理
        if (path.startsWith('http://') || path.startsWith('https://')) {
          urls.add(path);
        } else {
          // 通常のファイルとフォルダの処理
          final ext = p.extension(path).toLowerCase();
          LinkType type;
          
          if (await FileSystemEntity.isDirectory(path)) {
            type = LinkType.folder;
            try {
              final dir = Directory(path);
              if (await dir.exists()) {
                await dir.list().first;
                if (widget.onDropAddLink != null) {
                  await widget.onDropAddLink!(p.basename(path), path, type);
                  added = true;
                  folderCount++;
                }
              } else {
                failed.add(path);
              }
            } catch (_) {
              failed.add(path);
            }
          } else {
            type = LinkType.file;
            try {
              final fileObj = File(path);
              if (await fileObj.exists()) {
                await fileObj.open();
                if (widget.onDropAddLink != null) {
                  await widget.onDropAddLink!(p.basename(path), path, type);
                  added = true;
                  fileCount++;
                }
              } else {
                failed.add(path);
              }
            } catch (_) {
              failed.add(path);
            }
          }
        }
      }
    }
    
    // URLファイル（.url）からURLを抽出
    if (detail.files != null && detail.files.isNotEmpty) {
      for (final file in detail.files) {
        final path = file.path;
        if (path.toLowerCase().endsWith('.url')) {
          try {
            final fileObj = File(path);
            if (await fileObj.exists()) {
              final content = await fileObj.readAsString();
              final lines = content.split('\n');
              for (final line in lines) {
                final trimmedLine = line.trim();
                if (trimmedLine.startsWith('URL=')) {
                  final url = trimmedLine.substring(4).trim();
                  if (url.startsWith('http://') || url.startsWith('https://')) {
                    urls.add(url);
                  }
                }
              }
            }
          } catch (e) {
            failed.add(path);
          }
        }
      }
    }
    
    // HTMLファイルからURLを抽出（ブックマークエクスポートファイル）
    if (detail.files != null && detail.files.isNotEmpty) {
      for (final file in detail.files) {
        final path = file.path;
        if (path.toLowerCase().endsWith('.html')) {
          try {
            final fileObj = File(path);
            if (await fileObj.exists()) {
              final content = await fileObj.readAsString();
              // 簡単なHTML解析でURLを抽出
              final urlPattern = RegExp('href=["\'](https?://[^"\']+)["\']', caseSensitive: false);
              final matches = urlPattern.allMatches(content);
              for (final match in matches) {
                final url = match.group(1);
                if (url != null) {
                  urls.add(url);
                }
              }
            }
          } catch (e) {
            failed.add(path);
          }
        }
      }
    }
    
    // テキストデータからURLを抽出（ブラウザのアドレスバーからドラッグした場合）
    try {
      if (detail is Map) {
        final text = detail['text'] as String?;
        if (text != null && text.isNotEmpty) {
          final trimmedText = text.trim();
          if (trimmedText.startsWith('http://') || trimmedText.startsWith('https://')) {
            urls.add(trimmedText);
          }
        }
      }
    } catch (e) {
      print('テキストデータの処理エラー: $e');
    }
    
    // 重複を排除
    final uniqueUrls = urls.toSet().toList();
    
    // URLをグループに追加
    for (final url in uniqueUrls) {
      try {
        final uri = Uri.parse(url);
        final host = uri.host;
        final label = host.isNotEmpty ? host : 'URL';
        
        if (widget.onDropAddLink != null) {
          await widget.onDropAddLink!(label, url, LinkType.url);
          added = true;
          urlCount++;
        }
      } catch (e) {
        failed.add(url);
      }
    }
    
    // 結果を表示
    if (added) {
      List<String> messages = [];
      
      if (fileCount > 0) {
        if (fileCount == 1) {
          messages.add('ファイルを追加しました');
        } else {
          messages.add('$fileCount個のファイルを追加しました');
        }
      }
      
      if (folderCount > 0) {
        if (folderCount == 1) {
          messages.add('フォルダを追加しました');
        } else {
          messages.add('$folderCount個のフォルダを追加しました');
        }
      }
      
      if (urlCount > 0) {
        if (urlCount == 1) {
          messages.add('リンクを追加しました');
        } else {
          messages.add('$urlCount個のリンクを追加しました');
        }
      }
      
      final message = messages.join('、');
      widget.onShowMessage(
        message,
        icon: Icons.check_circle,
        color: Colors.green[700],
      );
    }
    
    if (failed.isNotEmpty) {
      widget.onShowMessage(
        '一部のファイル/フォルダはアクセスできなかったため登録されませんでした',
        icon: Icons.error,
        color: Colors.red[700],
      );
    }
  }
}

class _HoverAnimatedCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final Color hoverBorderColor;
  final double borderWidth;
  const _HoverAnimatedCard({
    required this.child,
    required this.borderColor,
    required this.hoverBorderColor,
    required this.borderWidth,
  });
  @override
  State<_HoverAnimatedCard> createState() => _HoverAnimatedCardState();
}

class _HoverAnimatedCardState extends State<_HoverAnimatedCard> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        border: Border.all(
          color: _hovering ? widget.hoverBorderColor : widget.borderColor,
          width: widget.borderWidth,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hovering
            ? [BoxShadow(color: widget.hoverBorderColor.withValues(alpha: 0.3), blurRadius: 16, offset: Offset(0, 4))]
            : [],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: widget.child,
      ),
    );
  }
}

class _GroupCardContent extends ConsumerStatefulWidget {
  final Group group;
  final VoidCallback onToggleCollapse;
  final VoidCallback onDeleteGroup;
  final VoidCallback onAddLink;
  final Function(String) onDeleteLink;
  final Function(LinkItem) onLaunchLink;
  final Future<void> Function(String label, String path, LinkType type)? onDropAddLink;
  final Future<void> Function(LinkItem updated) onEditLink;
  final Future<void> Function(List<LinkItem> newOrder) onReorderLinks;
  final void Function(Offset newPosition)? onMove;
  final bool isDragging;
  final void Function(String newTitle)? onEditGroupTitle;
  final void Function(Group) onFavoriteToggle;
  final void Function(Group, LinkItem) onLinkFavoriteToggle;
  final void Function(LinkItem link, String fromGroupId, String toGroupId)? onMoveLinkToGroup;
  final String? searchQuery;

  const _GroupCardContent({
    required this.group,
    required this.onToggleCollapse,
    required this.onDeleteGroup,
    required this.onAddLink,
    required this.onDeleteLink,
    required this.onLaunchLink,
    this.onDropAddLink,
    required this.onEditLink,
    required this.onReorderLinks,
    this.onMove,
    this.isDragging = false,
    this.onEditGroupTitle,
    required this.onFavoriteToggle,
    required this.onLinkFavoriteToggle,
    this.onMoveLinkToGroup,
    this.searchQuery,
  });

  @override
  ConsumerState<_GroupCardContent> createState() => _GroupCardContentState();
}

class _GroupCardContentState extends ConsumerState<_GroupCardContent> with IconBuilderMixin {
  bool showOnlyFavorites = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final items = group.items;
    final scale = (MediaQuery.of(context).size.width / 1200.0).clamp(1.0, 1.15);
    final canAddLink = items.length < 10;
    final isGroupFavorite = group.isFavorite;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final groupBorderColor = group.color != null ? Color(group.color!) : Colors.blue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12 * scale), // よりコンパクトに
          decoration: BoxDecoration(
            color: isDark 
              ? Colors.grey.shade900.withValues(alpha: 0.3)
              : Colors.grey.shade50.withValues(alpha: 0.8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark 
                  ? Colors.grey.shade700.withValues(alpha: 0.5)
                  : Colors.grey.shade300.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
          ),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                                  // グループアイコン（視覚的な階層を明確化）
                  Container(
                    padding: EdgeInsets.all(6 * scale), // よりコンパクトに
                    decoration: BoxDecoration(
                      color: groupBorderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10), // よりコンパクトに
                      border: Border.all(
                        color: groupBorderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: groupBorderColor,
                      size: 18 * scale, // よりコンパクトに
                    ),
                  ),
                SizedBox(width: 12 * scale),
                // グループタイトル
                Expanded(
                  child: HighlightedText(
                    text: group.title ?? '名称未設定',
                    highlight: widget.searchQuery,
                    style: TextStyle(
                      fontSize: 14 * scale, // よりコンパクトに
                      fontWeight: FontWeight.w600, // より太いフォント
                      color: textColor,
                      letterSpacing: 0.3, // よりコンパクトに
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // アクションボタン群（アクセシビリティ改善）
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20 * scale), // アイコンサイズ拡大
                      tooltip: 'グループ名を編集',
                      onPressed: () => widget.onEditGroupTitle?.call(group.title),
                      iconSize: 22 * scale,
                      padding: EdgeInsets.all(6 * scale), // さらに詰めて
                      constraints: BoxConstraints(
                        minWidth: 36 * scale, // よりコンパクトに
                         minHeight: 36 * scale, // よりコンパクトに
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark 
                          ? Colors.grey.shade800.withValues(alpha: 0.5)
                          : Colors.grey.shade200.withValues(alpha: 0.5),
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20 * scale),
                      onPressed: widget.onDeleteGroup,
                      tooltip: 'グループを削除',
                      iconSize: 22 * scale,
                      padding: EdgeInsets.all(6 * scale), // さらに詰めて
                      constraints: BoxConstraints(
                        minWidth: 36 * scale,
                        minHeight: 36 * scale,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark 
                          ? Colors.grey.shade800.withValues(alpha: 0.5)
                          : Colors.grey.shade200.withValues(alpha: 0.5),
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (canAddLink) ...[
                      SizedBox(width: 6 * scale), // さらに詰めて
                      IconButton(
                        icon: Icon(Icons.add, size: 20 * scale),
                        onPressed: widget.onAddLink,
                        tooltip: 'リンクを追加',
                        iconSize: 22 * scale,
                        padding: EdgeInsets.all(6 * scale), // さらに詰めて
                        constraints: BoxConstraints(
                          minWidth: 36 * scale,
                          minHeight: 36 * scale,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: groupBorderColor.withValues(alpha: 0.1),
                          foregroundColor: groupBorderColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
          const Divider(height: 1),
          Expanded(
          child: items.isEmpty
              ? DragTarget<Map<String, dynamic>>(
                  onWillAccept: (data) {
                    if (data == null) return false;
                    final fromGroupId = data['fromGroupId'] as String?;
                    return fromGroupId != widget.group.id;
                  },
                  onAccept: (data) {
                    final link = data['link'] as LinkItem;
                    final fromGroupId = data['fromGroupId'] as String;
                    if (widget.onMoveLinkToGroup != null) {
                      widget.onMoveLinkToGroup!(link, fromGroupId, widget.group.id);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Center(
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: candidateData.isNotEmpty ? Colors.blueAccent : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: candidateData.isNotEmpty ? Colors.blue.withValues(alpha: 0.08) : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          candidateData.isNotEmpty ? 'ここにドロップして追加' : 'リンクなし\nここにドラッグで追加',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13 * scale),
          ),
                      ),
                    );
                  },
                )
              : _buildContent(context, scale, items),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, double scale, List<LinkItem> items) {
    // 検索クエリに基づいてリンクをフィルタリング
    List<LinkItem> filteredItems = items;
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final keywords = widget.searchQuery!.toLowerCase().split(' ').where((k) => k.isNotEmpty).toList();
      filteredItems = items.where((item) {
        // ラベルでの検索
        if (_matchesKeywords(item.label.toLowerCase(), keywords)) {
          return true;
        }
        // URLリンクの場合、ドメイン名でも検索
        if (item.type == LinkType.url) {
          final domain = _extractDomain(item.path);
          if (_matchesKeywords(domain.toLowerCase(), keywords)) {
            return true;
          }
        }
        // タグでの検索
        if (item.tags.any((tag) => _matchesKeywords(tag.toLowerCase(), keywords))) {
          return true;
        }
        return false;
      }).toList();
    }
    
    if (filteredItems.isEmpty) {
      return SizedBox(
        height: 119 * scale,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 55 * scale, color: Colors.grey),
              SizedBox(height: 11 * scale),
              Text(
                widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
                  ? '検索結果なし'
                  : 'No links yet',
                style: TextStyle(color: Colors.grey, fontSize: 19 * scale, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    
    // お気に入り→通常の順で並べる
    final filtered = showOnlyFavorites ? filteredItems.where((l) => l.isFavorite).toList() : filteredItems;
    final sortedItems = [
      ...filtered.where((l) => l.isFavorite),
      ...filtered.where((l) => !l.isFavorite),
    ];
    return DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) {
          if (data == null) return false;
          final fromGroupId = data['fromGroupId'] as String?;
          return fromGroupId != widget.group.id;
        },
        onAccept: (data) {
          final link = data['link'] as LinkItem;
          final fromGroupId = data['fromGroupId'] as String;
          if (widget.onMoveLinkToGroup != null) {
            widget.onMoveLinkToGroup!(link, fromGroupId, widget.group.id);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return ReorderableListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero, // パディングを削除してより多くのアイテムを表示
            buildDefaultDragHandles: true, // デフォルトの並び替えハンドルを表示
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) newIndex--;
              final newItems = List<LinkItem>.from(sortedItems);
              final item = newItems.removeAt(oldIndex);
              newItems.insert(newIndex, item);
              await widget.onReorderLinks(newItems);
            },
            children: [
              for (int i = 0; i < sortedItems.length; i++)
                _buildLinkItem(context, sortedItems[i], sortedItems, scale: scale, key: ValueKey(sortedItems[i].id)),
            ],
          );
        },
    );
  }

  Widget _buildLinkItem(BuildContext context, LinkItem item, List<LinkItem> items, {double scale = 1.0, Key? key}) {
    IconData iconData;
    Color iconColor;
    
    // フォルダの場合、個別リンクのカスタムアイコンを優先使用
    if (item.type == LinkType.folder) {
      if (item.iconData != null) {
        print('カスタムアイコン使用: iconData=${item.iconData}, iconColor=${item.iconColor}');
        print('地球アイコンのcodePoint: ${Icons.public.codePoint}');
        print('Icons.folder.codePoint: ${Icons.folder.codePoint}');
        print('Icons.folder_open.codePoint: ${Icons.folder_open.codePoint}');
        print('Icons.folder_special.codePoint: ${Icons.folder_special.codePoint}');
        print('Icons.folder_shared.codePoint: ${Icons.folder_shared.codePoint}');
        iconData = IconData(item.iconData!, fontFamily: 'MaterialIcons');
        iconColor = item.iconColor != null ? Color(item.iconColor!) : Colors.orange;
      } else {
        print('デフォルトアイコン使用: ${item.label}');
        iconData = Icons.folder;
        iconColor = Colors.orange;
      }
    } else {
      switch (item.type) {
        case LinkType.file:
          iconData = Icons.insert_drive_file;
          iconColor = Colors.blue;
          break;
        case LinkType.url:
          iconData = Icons.link;
          iconColor = Colors.green;
          break;
        case LinkType.folder:
          iconData = Icons.folder;
          iconColor = Colors.orange;
          break;
      }
    }
    
    final isLinkFavorite = item.isFavorite;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupBorderColor = widget.group.color != null ? Color(widget.group.color!) : Colors.blue;
    
    // より明確な背景色の階層
    final rowColor = isLinkFavorite
        ? (isDark ? Colors.amber.withValues(alpha: 0.25) : Colors.amber.withValues(alpha: 0.2))
        : (isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50.withValues(alpha: 0.5));
    
    bool _hovering = false;
  return KeyedSubtree(
    key: key,
    child: Draggable<Map<String, dynamic>>(
      data: {'link': item, 'fromGroupId': widget.group.id},
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          child: Row(
                         children: [
               item.type == LinkType.url
                   ? UrlPreviewWidget(url: item.path, isDark: isDark, searchQuery: widget.searchQuery)
                   : item.type == LinkType.file
                      ? FilePreviewWidget(path: item.path, isDark: isDark)
                      : Icon(iconData, color: iconColor, size: 25 * scale),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w500, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setState) => MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () => _launchLink(item),
            child: Consumer(
              builder: (context, ref, child) {
                final layoutSettings = ref.watch(layoutSettingsProvider);
                return Container(
                  margin: EdgeInsets.only(
                    left: layoutSettings.linkItemMargin * scale,
                    right: 2 * scale, // 右端を詰める
                    top: layoutSettings.linkItemMargin * 0.5 * scale,
                    bottom: layoutSettings.linkItemMargin * 0.5 * scale,
                  ),
                  padding: EdgeInsets.all(layoutSettings.linkItemPadding * scale),
                  decoration: BoxDecoration(
                    color: rowColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLinkFavorite 
                        ? Colors.amber.withValues(alpha: 0.3)
                        : (isDark ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade300.withValues(alpha: 0.5)),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                          ? Colors.black.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                                     child: Row(
                     children: [
                   // 1. アイコン（固定幅）
                   Container(
                     width: 32 * scale, // 固定幅
                     height: 32 * scale, // 固定高さ
                     padding: EdgeInsets.all(4 * scale),
                     decoration: BoxDecoration(
                       color: iconColor.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(
                         color: iconColor.withValues(alpha: 0.3),
                         width: 1,
                       ),
                     ),
                     child: item.type == LinkType.url
                       ? UrlPreviewWidget(url: item.path, isDark: isDark, searchQuery: widget.searchQuery, fallbackDomain: item.faviconFallbackDomain)
                       : item.type == LinkType.file
                         ? FilePreviewWidget(path: item.path, isDark: isDark)
                         : buildIconWidget(restoreIconData(item.iconData) ?? Icons.folder, Color(item.iconColor ?? 0xFF000000), size: layoutSettings.linkItemIconSize * scale),
                   ),
                   SizedBox(width: 6 * scale),
                   // 2. ラベルとタグ（可変幅、ボタン群の幅を引いた残り）
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Tooltip(
                           message: item.path,
                           child: HighlightedText(
                             text: item.label,
                             highlight: widget.searchQuery,
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(
                               fontSize: layoutSettings.linkItemFontSize * scale,
                               fontWeight: FontWeight.w500,
                               color: Theme.of(context).colorScheme.onSurface,
                               letterSpacing: 0.05,
                             ),
                           ),
                         ),
                         if (item.tags.isNotEmpty) ...[
                           const SizedBox(height: 2),
                           Wrap(
                             spacing: 4,
                             runSpacing: 2,
                             children: item.tags.map((tag) => Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50.withValues(alpha: 0.8),
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(
                                   color: isDark ? Colors.blue.shade700.withValues(alpha: 0.5) : Colors.blue.shade200.withValues(alpha: 0.8),
                                   width: 1,
                                 ),
                               ),
                               child: Text(
                                 tag,
                                 style: TextStyle(
                                   fontSize: (layoutSettings.linkItemFontSize - 2) * scale,
                                   color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             )).toList(),
                           ),
                         ],
                       ],
                     ),
                   ),
                   // 3. ボタン群（固定幅）
                   Container(
                     width: 160 * scale, // 4つのボタン用に調整
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                                                 // メモボタン（常時表示）
                         IconButton(
                            icon: Icon(
                              Icons.note_alt_outlined, 
                              color: item.memo?.isNotEmpty == true ? Colors.orange.shade600 : Colors.grey.shade600, 
                              size: layoutSettings.linkItemIconSize * 0.9 * scale
                            ),
                            tooltip: item.memo?.isNotEmpty == true ? item.memo! : 'メモ追加',
                            onPressed: () async {
                              final controller = TextEditingController(text: item.memo ?? '');
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('メモ編集'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: controller,
                                        maxLines: 5,
                                        decoration: const InputDecoration(
                                          hintText: 'メモを入力...',
                                          helperText: '空の場合はメモを削除します',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '現在のメモ: ${item.memo?.isNotEmpty == true ? item.memo : "なし"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('キャンセル'),
                                    ),
                                    if (item.memo?.isNotEmpty == true)
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, ''), // 空文字列でメモ削除
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('削除'),
                                      ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, controller.text.trim()),
                                      child: const Text('保存'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null) {
                                // 空文字列の場合はセンチネル値を使用（メモ削除）
                                final memoValue = result.trim().isEmpty ? LinkItem.nullSentinel : result.trim();
                                
                                final updated = item.copyWith(memo: memoValue);
                                await widget.onEditLink(updated);
                                // 親の状態を更新してUIを再描画
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            },
                            constraints: BoxConstraints(
                              minWidth: layoutSettings.buttonSize * scale,
                              minHeight: layoutSettings.buttonSize * scale,
                            ),
                            padding: EdgeInsets.all(4 * scale),
                            style: IconButton.styleFrom(
                              backgroundColor: item.memo?.isNotEmpty == true 
                                ? Colors.orange.shade50.withValues(alpha: 0.8)
                                : (isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade200.withValues(alpha: 0.5)),
                              foregroundColor: item.memo?.isNotEmpty == true ? Colors.orange.shade600 : Colors.grey.shade600,
                            ),
                          ),
                        SizedBox(width: 2 * scale),
                        
                        // タスク作成ボタン
                        IconButton(
                          icon: Icon(Icons.task_alt, size: 18 * scale),
                          onPressed: () => _createTaskFromLink(context, item),
                          tooltip: item.hasActiveTasks ? 'アクティブなタスクがあります' : 'このリンクからタスクを作成',
                          constraints: BoxConstraints(
                            minWidth: layoutSettings.buttonSize * scale,
                            minHeight: layoutSettings.buttonSize * scale,
                          ),
                          padding: EdgeInsets.all(4 * scale),
                          style: IconButton.styleFrom(
                            backgroundColor: item.hasActiveTasks 
                              ? Colors.orange.shade50.withValues(alpha: 0.8)
                              : (isDark 
                                ? Colors.grey.shade800.withValues(alpha: 0.5)
                                : Colors.grey.shade200.withValues(alpha: 0.5)),
                            foregroundColor: item.hasActiveTasks ? Colors.orange.shade600 : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        SizedBox(width: 2 * scale),
                        
                        // 編集ボタン（常時表示）
                        IconButton(
                          icon: Icon(Icons.edit, size: 18 * scale),
                          onPressed: () => _showEditLinkDialog(context, item),
                          tooltip: 'リンクを編集',
                          constraints: BoxConstraints(
                            minWidth: layoutSettings.buttonSize * scale,
                            minHeight: layoutSettings.buttonSize * scale,
                          ),
                          padding: EdgeInsets.all(4 * scale),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark 
                              ? Colors.grey.shade800.withValues(alpha: 0.5)
                              : Colors.grey.shade200.withValues(alpha: 0.5),
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(width: 2 * scale),
                        
                        // 削除ボタン（常時表示）
                        IconButton(
                          icon: Icon(Icons.delete, size: 18 * scale),
                          onPressed: () => widget.onDeleteLink(item.id),
                          tooltip: 'リンクを削除',
                          constraints: BoxConstraints(
                            minWidth: layoutSettings.buttonSize * scale,
                            minHeight: layoutSettings.buttonSize * scale,
                          ),
                          padding: EdgeInsets.all(4 * scale),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark 
                              ? Colors.grey.shade800.withValues(alpha: 0.5)
                              : Colors.grey.shade200.withValues(alpha: 0.5),
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                        ],
                      ),
                    ),
                    // 右端の余白を削除して右枠に寄せる
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
   ), 
  );
}

  void _showEditLinkDialog(BuildContext context, LinkItem item) {
    final labelController = TextEditingController(text: item.label);
    final pathController = TextEditingController(text: item.path);
    final tagsController = TextEditingController(text: item.tags.join(', '));
    final fallbackDomainController = TextEditingController(text: item.faviconFallbackDomain ?? '');
    LinkType selectedType = item.type;
    IconData selectedIcon;
    if (item.iconData != null) {
      print('アイコン復元: iconData=${item.iconData}');
      // restoreIconDataメソッドを使用して正しく復元
      final restoredIcon = restoreIconData(item.iconData);
      if (restoredIcon != null) {
        selectedIcon = restoredIcon;
        print('復元されたアイコン: codePoint=${selectedIcon.codePoint}, fontFamily=${selectedIcon.fontFamily}');
      } else {
        selectedIcon = Icons.folder;
        print('復元に失敗、デフォルトアイコンを使用');
      }
    } else {
      selectedIcon = Icons.folder;
    }
    Color selectedIconColor = item.iconColor != null ? Color(item.iconColor!) : Colors.orange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('リンクを編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'ラベル',
                  hintText: 'リンクラベルを入力...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: 'パス/URL',
                  hintText: 'ファイルパスまたはURLを入力...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'タグ',
                  hintText: 'カンマ区切りでタグを入力（例: 仕事, 重要, プロジェクト）',
                ),
              ),
              const SizedBox(height: 16),
              // フォールバックドメイン設定（URLタイプの場合のみ表示）
              if (selectedType == LinkType.url) ...[
                TextField(
                  controller: fallbackDomainController,
                  decoration: const InputDecoration(
                    labelText: 'Faviconフォールバックドメイン',
                    hintText: '例: https://www.resonabank.co.jp/',
                    helperText: 'favicon取得失敗時に使用するドメインを設定',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<LinkType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'タイプ',
                ),
                items: LinkType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              if (selectedType == LinkType.folder) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('アイコン: '),
                    Expanded(child: IconSelector(
                      selectedIcon: selectedIcon,
                      selectedIconColor: selectedIconColor,
                      onIconSelected: (iconData, iconColor) {
                        print('IconSelector callback: iconData.codePoint=${iconData.codePoint}, iconData.fontFamily=${iconData.fontFamily}');
                        print('Icons.public.codePoint=${Icons.public.codePoint}');
                        print('選択されたアイコンが地球アイコンかチェック: ${iconData.codePoint == Icons.public.codePoint}');
                        print('更新前のselectedIcon: codePoint=${selectedIcon.codePoint}');
                        setState(() {
                          selectedIcon = iconData;
                          selectedIconColor = iconColor;
                        });
                        print('更新後のselectedIcon: codePoint=${selectedIcon.codePoint}');
                      },
                    )),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isNotEmpty && pathController.text.isNotEmpty) {
                  print('保存処理開始: selectedIcon.codePoint=${selectedIcon.codePoint}');
                  print('保存処理開始: selectedIcon.fontFamily=${selectedIcon.fontFamily}');
                  print('保存処理開始: selectedIconColor.value=${selectedIconColor.value}');
                  // Font Awesomeアイコンの場合はfontFamily情報も含めて保存
                  int? iconDataToSave;
                  if (selectedType == LinkType.folder && selectedIcon.fontFamily != null) {
                    // Font Awesomeアイコンの場合は、codePointとfontFamilyを組み合わせて保存
                    if (selectedIcon.fontFamily == 'FontAwesomeSolid' || 
                        selectedIcon.fontFamily == 'FontAwesomeRegular' || 
                        selectedIcon.fontFamily == 'FontAwesomeBrands') {
                      // Font Awesomeアイコンの場合は、codePointをそのまま保存（fontFamilyは後で判定）
                      iconDataToSave = selectedIcon.codePoint;
                    } else {
                      // Material Iconsの場合は、codePointをそのまま保存
                      iconDataToSave = selectedIcon.codePoint;
                    }
                  } else if (selectedType == LinkType.folder) {
                    iconDataToSave = selectedIcon.codePoint;
                  }

                  final updated = LinkItem(
                    id: item.id,
                    label: labelController.text,
                    path: pathController.text,
                    type: selectedType,
                    createdAt: item.createdAt,
                    lastUsed: item.lastUsed,
                    isFavorite: item.isFavorite,
                    memo: item.memo,
                    iconData: iconDataToSave,
                    iconColor: selectedType == LinkType.folder ? selectedIconColor.value : null,
                    tags: tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
                    faviconFallbackDomain: selectedType == LinkType.url ? fallbackDomainController.text.trim().isEmpty ? null : fallbackDomainController.text.trim() : null,
                  );
                  
                  // タグ保存のデバッグログを追加
                  print('=== タグ保存デバッグ ===');
                  print('元のタグ: ${item.tags}');
                  print('タグコントローラーの値: "${tagsController.text}"');
                  print('パース後のタグ: ${tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()}');
                  print('更新後のタグ: ${updated.tags}');
                  
                  print('リンク更新: iconData=${updated.iconData}, iconColor=${updated.iconColor}');
                  print('選択されたアイコン: codePoint=${selectedIcon.codePoint}, fontFamily=${selectedIcon.fontFamily}');
                  print('Icons.public.codePoint=${Icons.public.codePoint}');
                  print('保存されるcodePointが地球アイコンと一致するか: ${updated.iconData == Icons.public.codePoint}');
                  await widget.onEditLink(updated);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDetails(BuildContext context, LinkItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Label: ${item.label}'),
            const SizedBox(height: 8),
            Text('Path: ${item.path}'),
            const SizedBox(height: 8),
            Text('Type: ${item.type.name.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Created: ${item.createdAt.toString()}'),
            if (item.lastUsed != null) ...[
              const SizedBox(height: 8),
              Text('Last Used: ${item.lastUsed.toString()}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchLink(LinkItem item) async {
    // LinkViewModelのlaunchLinkメソッドを呼び出して、lastUsedを更新する
    widget.onLaunchLink(item);
  }

  // メモプレビュー用のオーバーレイ
  OverlayEntry? _memoPreviewOverlay;
  Timer? _memoPreviewTimer;

  void _showMemoPreviewOverlay(String memo) {
    _removeMemoPreviewOverlay();
    
    // マウス位置を取得
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final overlay = Overlay.of(context);
    _memoPreviewOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 100, // 固定位置に配置
        right: 20,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 350,
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.note_alt_outlined, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'メモ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: _removeMemoPreviewOverlay,
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      memo,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_memoPreviewOverlay!);
  }

  void _handleMemoHoverEnter(String memo) {
    _memoPreviewTimer?.cancel();
    _memoPreviewTimer = Timer(const Duration(milliseconds: 300), () {
      _showMemoPreviewOverlay(memo);
    });
  }

  void _handleMemoHoverExit() {
    _memoPreviewTimer?.cancel();
    _memoPreviewTimer = Timer(const Duration(milliseconds: 200), () {
      _removeMemoPreviewOverlay();
    });
  }

  void _removeMemoPreviewOverlay() {
    _memoPreviewOverlay?.remove();
    _memoPreviewOverlay = null;
  }

  @override
  void dispose() {
    _memoPreviewTimer?.cancel();
    _removeMemoPreviewOverlay();
    super.dispose();
  }

  // リンクからタスクを作成するメソッド
  void _createTaskFromLink(BuildContext context, LinkItem link) {
    // 新しいTaskDialogを使用してタスクを作成
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        relatedLinkId: link.id,
      ),
    );
  }

  // 複数キーワードがすべて含まれているかチェックするヘルパーメソッド
  bool _matchesKeywords(String text, List<String> keywords) {
    if (keywords.isEmpty) return true;
    return keywords.every((keyword) => text.contains(keyword));
  }

  // URLからドメイン名を抽出するヘルパーメソッド
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      // URLの形式が不正な場合、元のパスを返す
      return url;
    }
  }
} 