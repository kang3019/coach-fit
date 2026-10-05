import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_profile.dart';
import '../../services/app_settings_service.dart';
import '../../services/favorite_exercises_service.dart';
import '../../services/goal_service.dart';
import '../../services/profile_service.dart';
import '../../services/reminder_service.dart';
import '../../services/workout_journal_service.dart';
import '../about_screen.dart';
import '../achievements_screen.dart';
import '../favorites_screen.dart';
import '../profile_edit_screen.dart';
import '../widgets/menu_monthly_summary_card.dart';
import '../widgets/rest_timer.dart';

/// 5. 메뉴/마이 탭 (Menu & Settings Tab)
/// 추가된 12개 기능 (A~L) wire-up:
/// A) 무게 단위, B) 리마인더 시간, C) 테마 색상, D) 이번 달 요약
/// E) 업적/뱃지, F) 즐겨찾기, G) 운동 일지
/// H) 데이터 내보내기, I) 전체 초기화, J) 앱 정보, K) 글자 크기, L) 튜토리얼 재실행
class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final AppSettingsService _settings = AppSettingsService();
  final ReminderService _reminder = ReminderService();
  final FavoriteExercisesService _favorites = FavoriteExercisesService();
  final WorkoutJournalService _journal = WorkoutJournalService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onChange);
    _reminder.addListener(_onChange);
    _favorites.addListener(_onChange);
    _journal.addListener(_onChange);
    _reminder.load();
    _favorites.load();
    _journal.loadAll();
  }

  @override
  void dispose() {
    _settings.removeListener(_onChange);
    _reminder.removeListener(_onChange);
    _favorites.removeListener(_onChange);
    _journal.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  // ===== 바텀시트들 =====

  void _openTimer() => RestTimerSheet.show(context, initialSeconds: 90);

  void _openWeightUnitSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EnumPickerSheet<WeightUnit>(
        title: '무게 단위',
        values: WeightUnit.values,
        current: _settings.weightUnit,
        labelOf: (u) => '${u.symbol} (${u.label})',
        onSelect: _settings.setWeightUnit,
      ),
    );
  }

  Future<void> _openReminderPicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder.time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Theme.of(context).colorScheme.primary,
            surface: const Color(0xFF171B22),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) await _reminder.setTime(picked);
  }

  void _openThemeAccentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ThemeAccentSheet(
        current: _settings.themeAccent,
        onSelect: _settings.setThemeAccent,
      ),
    );
  }

  void _openTextScaleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EnumPickerSheet<TextScale>(
        title: '글자 크기',
        values: TextScale.values,
        current: _settings.textScale,
        labelOf: (s) => s.label,
        onSelect: _settings.setTextScale,
      ),
    );
  }

  void _openJournalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _JournalSheet(service: _journal),
    );
  }

  Future<void> _confirmWipeAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171B22),
        title: const Text('데이터 전체 초기화',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '모든 로컬 설정과 기록(즐겨찾기, 일지, 신체 측정 캐시, 커뮤니티 등)이 삭제됩니다. 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _settings.wipeAllLocalData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로컬 데이터가 초기화되었습니다.')),
      );
    }
  }

  Future<void> _showDataExportPreview() async {
    final favorites = _favorites.favorites.toList();
    final entries = await _journal.loadAll();
    if (!mounted) return;
    final jsonPreview = {
      'weightUnit': _settings.weightUnit.name,
      'themeAccent': _settings.themeAccent.name,
      'textScale': _settings.textScale.name,
      'reminderTime': _reminder.display,
      'favorites': favorites,
      'journalEntries': entries
          .map((e) => {
                'date':
                    '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                'rating': e.rating,
                'note': e.note,
              })
          .toList(),
    };
    final text = const JsonEncoder.withIndent('  ').convert(jsonPreview);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExportPreviewSheet(json: text),
    );
  }

  Future<void> _resetTutorial() async {
    await _settings.resetTutorial();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('튜토리얼이 다음 홈 방문 시 다시 표시됩니다.')),
    );
  }

  // ===== build =====

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final latestJournal = _journal.latestOf(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '메뉴 & 마이페이지',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 프로필 카드 + 스펙 그리드 (기존 유지)
          const _ProfileCard(),
          const SizedBox(height: 14),
          const _ProfileSpecGrid(),
          const SizedBox(height: 14),

          // D) 이번 달 요약 미니 카드
          const MenuMonthlySummaryCard(),
          const SizedBox(height: 20),

          // 🏆 성취/탐색 섹션
          _sectionLabel('🏆 성취 & 탐색'),
          Card(
            child: Column(
              children: [
                _navTile(
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFF59E0B),
                  title: '업적 & 뱃지',
                  subtitle: '13종 뱃지 수집 (스트릭/볼륨/PR)',
                  onTap: () => _push(const AchievementsScreen()),
                ),
                const _MenuDivider(),
                _navTile(
                  icon: Icons.star_outline_rounded,
                  color: accent,
                  title: '즐겨찾기 운동',
                  subtitle: '${_favorites.count}개 종목 저장됨',
                  onTap: () => _push(const FavoritesScreen()),
                ),
                const _MenuDivider(),
                _navTile(
                  icon: Icons.auto_stories_outlined,
                  color: const Color(0xFF60A5FA),
                  title: '오늘의 운동 일지',
                  subtitle: latestJournal == null
                      ? '컨디션 별점 + 메모 남기기'
                      : '${'⭐' * latestJournal.rating} · ${latestJournal.note.isEmpty ? '메모 없음' : latestJournal.note}',
                  onTap: _openJournalSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ⚙️ 운동 설정 섹션
          _sectionLabel('⚙️ 운동 설정'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined,
                      color: Colors.white70),
                  title: const Text('기본 세트 간 휴식 시간',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text('90초',
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700)),
                  onTap: _openTimer,
                ),
                const _MenuDivider(),
                ListTile(
                  leading: const Icon(Icons.fitness_center_rounded,
                      color: Colors.white70),
                  title: const Text('무게 단위',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text(
                    '${_settings.weightUnit.symbol} (${_settings.weightUnit.label})',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
                  ),
                  onTap: _openWeightUnitSheet,
                ),
                const _MenuDivider(),
                ListTile(
                  leading: Icon(
                    _reminder.enabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: Colors.white70,
                  ),
                  title: const Text('운동 리마인더 알림',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Row(
                    children: [
                      Switch(
                        value: _reminder.enabled,
                        onChanged: _reminder.setEnabled,
                        activeThumbColor: accent,
                      ),
                      Text(
                        _reminder.enabled ? '사용 중' : '꺼짐',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: Text(
                    _reminder.displayKorean,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
                  ),
                  onTap: _openReminderPicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 운동 목표
          _sectionLabel('🎯 운동 목표'),
          const _GoalSelector(),
          const SizedBox(height: 20),

          // 🎨 앱 외관 섹션
          _sectionLabel('🎨 앱 외관'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.palette_outlined, color: accent),
                  title: const Text('포인트 색상',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white24, width: 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _settings.themeAccent.label,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                  onTap: _openThemeAccentSheet,
                ),
                const _MenuDivider(),
                ListTile(
                  leading: const Icon(Icons.text_fields,
                      color: Colors.white70),
                  title: const Text('글자 크기',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text(
                    _settings.textScale.label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
                  ),
                  onTap: _openTextScaleSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 🛟 데이터 관리 섹션
          _sectionLabel('🛟 데이터 관리'),
          Card(
            child: Column(
              children: [
                _navTile(
                  icon: Icons.file_download_outlined,
                  color: const Color(0xFF60A5FA),
                  title: '데이터 내보내기',
                  subtitle: 'JSON 미리보기 → 복사해서 백업',
                  onTap: _showDataExportPreview,
                ),
                const _MenuDivider(),
                _navTile(
                  icon: Icons.replay_rounded,
                  color: const Color(0xFF60A5FA),
                  title: '튜토리얼 다시 보기',
                  subtitle: '다음 홈 방문 시 가이드 재표시',
                  onTap: _resetTutorial,
                ),
                const _MenuDivider(),
                _navTile(
                  icon: Icons.delete_sweep_outlined,
                  color: const Color(0xFFEF4444),
                  title: '데이터 전체 초기화',
                  subtitle: '로컬 캐시/설정 모두 삭제 (되돌릴 수 없음)',
                  onTap: _confirmWipeAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 📡 시스템 상태
          _sectionLabel('📡 시스템 및 서버 상태'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.dns_outlined,
                      color: Color(0xFF10B981)),
                  title: Text('백엔드 서버',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('FastAPI 단일 백엔드 (포트 8000)',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  trailing: Text('온라인 🟢',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const _MenuDivider(),
                const ListTile(
                  leading: Icon(Icons.storage_rounded,
                      color: Color(0xFF60A5FA)),
                  title: Text('데이터베이스',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('PostgreSQL / SQLite 영속성',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  trailing: Text('연결됨',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
                const _MenuDivider(),
                const ListTile(
                  leading: Icon(Icons.auto_awesome,
                      color: Color(0xFFF59E0B)),
                  title: Text('AI 코칭 엔진',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('OpenAI GPT-4o-mini & 스마트 룰베이스 하이브리드',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
                const _MenuDivider(),
                _navTile(
                  icon: Icons.info_outline,
                  color: Colors.white70,
                  title: '앱 정보',
                  subtitle: '개발팀 / 기술 스택 / 라이선스',
                  onTap: () => _push(const AboutScreen()),
                ),
                const _MenuDivider(),
                const ListTile(
                  leading:
                      Icon(Icons.verified_outlined, color: Colors.white70),
                  title: Text('앱 버전',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text('v2.0.0',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== helpers =====

  void _push(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _navTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style:
                const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.white24, size: 20),
        onTap: onTap,
      );
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Colors.white10);
}

// ===== 공용 Enum Picker Sheet =====

class _EnumPickerSheet<T extends Enum> extends StatelessWidget {
  final String title;
  final List<T> values;
  final T current;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;
  const _EnumPickerSheet({
    required this.title,
    required this.values,
    required this.current,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final v in values)
              ListTile(
                leading: Icon(
                  current == v
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: current == v ? accent : Colors.white38,
                ),
                title: Text(labelOf(v),
                    style: TextStyle(
                      color: current == v ? Colors.white : Colors.white70,
                      fontWeight: current == v
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
                onTap: () {
                  onSelect(v);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ===== 테마 색상 선택 시트 =====

class _ThemeAccentSheet extends StatelessWidget {
  final ThemeAccent current;
  final ValueChanged<ThemeAccent> onSelect;
  const _ThemeAccentSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '포인트 색상',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '앱 전체 포인트 색상이 즉시 반영됩니다.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final v in ThemeAccent.values)
                  InkWell(
                    onTap: () {
                      onSelect(v);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: current == v ? v.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: v.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: v.color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: current == v
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            v.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 운동 일지 바텀시트 =====

class _JournalSheet extends StatefulWidget {
  final WorkoutJournalService service;
  const _JournalSheet({required this.service});

  @override
  State<_JournalSheet> createState() => _JournalSheetState();
}

class _JournalSheetState extends State<_JournalSheet> {
  int _rating = 3;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final latest = widget.service.latestOf(today);
    if (latest != null) {
      _rating = latest.rating;
      _noteCtrl.text = latest.note;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.service.upsert(JournalEntry(
        date: DateTime.now(),
        rating: _rating,
        note: _noteCtrl.text.trim(),
      ));
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            '오늘의 운동 일지',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(DateTime.now()),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Text('컨디션',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 1; i <= 5; i++)
                InkWell(
                  onTap: () => setState(() => _rating = i),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      i <= _rating ? Icons.star_rounded : Icons.star_outline,
                      color: i <= _rating ? accent : Colors.white24,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText:
                  '오늘 운동 소감이나 메모 (예: 벤치 70kg 10회 처음 성공!)',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? '저장 중…' : '저장'),
          ),
        ],
      ),
    );
  }
}

// ===== 데이터 내보내기 미리보기 =====

class _ExportPreviewSheet extends StatelessWidget {
  final String json;
  const _ExportPreviewSheet({required this.json});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '데이터 백업 미리보기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '아래 JSON 을 복사해서 안전한 곳에 보관하세요.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1116),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '※ 전체 운동 기록은 서버 DB 에 안전하게 저장되어 있어요.\n여기 보이는 건 로컬 설정 + 즐겨찾기 + 일지입니다.',
              style: TextStyle(color: accent, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 운동 목표 (기존 유지) =====

class _GoalSelector extends StatefulWidget {
  const _GoalSelector();

  @override
  State<_GoalSelector> createState() => _GoalSelectorState();
}

class _GoalSelectorState extends State<_GoalSelector> {
  final GoalService _service = GoalService();
  WorkoutGoal? _selected;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final current = await _service.load();
    if (mounted) setState(() => _selected = current);
  }

  Future<void> _select(WorkoutGoal goal) async {
    setState(() => _selected = goal);
    await _service.save(goal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("목표를 '${goal.label}' (으)로 설정했어요"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      child: Column(
        children: WorkoutGoal.values.map((goal) {
          final isSelected = _selected == goal;
          final isLast = goal == WorkoutGoal.values.last;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  _iconFor(goal),
                  color: isSelected ? accent : Colors.white70,
                ),
                title: Text(
                  goal.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  goal.aiPromptPhrase,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? accent : Colors.white24,
                  size: 20,
                ),
                onTap: () => _select(goal),
              ),
              if (!isLast) const Divider(height: 1, color: Colors.white10),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(WorkoutGoal goal) {
    switch (goal) {
      case WorkoutGoal.hypertrophy:
        return Icons.fitness_center;
      case WorkoutGoal.fatLoss:
        return Icons.local_fire_department;
      case WorkoutGoal.strength:
        return Icons.bolt;
    }
  }
}

// ===== 프로필 카드 (기존 유지) =====

class _ProfileCard extends StatefulWidget {
  const _ProfileCard();

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  final ProfileService _service = ProfileService();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onProfileChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    _service.removeListener(_onProfileChanged);
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final p = await _service.load();
    if (mounted) setState(() => _profile = p);
  }

  void _onProfileChanged() => _loadInitial();

  Future<void> _openEdit() async {
    final current = _profile ?? await _service.load();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(initial: current),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = _profile ?? UserProfile.defaultProfile();
    return Card(
      child: InkWell(
        onTap: _openEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primary.withValues(alpha: 0.2),
                child: const Text('💪', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${profile.nickname} 회원님',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.experience.label.toUpperCase(),
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.gender.label} · ${profile.experience.description}',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '프로필 편집하려면 탭',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 신체 스펙 그리드 (기존 유지) =====

class _ProfileSpecGrid extends StatefulWidget {
  const _ProfileSpecGrid();

  @override
  State<_ProfileSpecGrid> createState() => _ProfileSpecGridState();
}

class _ProfileSpecGridState extends State<_ProfileSpecGrid> {
  final ProfileService _service = ProfileService();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _service.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _service.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final p = await _service.load();
    if (mounted) setState(() => _profile = p);
  }

  String _fmt(double? v, String unit) =>
      v == null ? '-' : (v % 1 == 0 ? '${v.toInt()} $unit' : '${v.toStringAsFixed(1)} $unit');

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? UserProfile.defaultProfile();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SpecColumn(label: '키', value: _fmt(profile.heightCm, 'cm')),
          _SpecColumn(label: '체중', value: _fmt(profile.weightKg, 'kg')),
          _SpecColumn(label: '목표', value: _fmt(profile.targetWeightKg, 'kg')),
          _SpecColumn(label: '경력', value: profile.experience.label),
        ],
      ),
    );
  }
}

class _SpecColumn extends StatelessWidget {
  final String label;
  final String value;
  const _SpecColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
