import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/five_minute.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../orders/order_create_screen.dart';
import '../orders/order_detail_screen.dart';
import '../theme/app_theme.dart';

const _monthNames = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

const _tray = Color(0xFFECF3EF);
const _clientAccent = Color(0xFFC2410C);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// First month of the visible two-month pair.
  late DateTime _anchor;
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEventItem>> _byDay = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DateTime get _monthA => _anchor;
  DateTime get _monthB => DateTime(_anchor.year, _anchor.month + 1);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final from = DateTime(_anchor.year, _anchor.month, 1);
      final to = DateTime(_anchor.year, _anchor.month + 2, 0, 23, 59, 59);
      final feed = await context.read<CalendarService>().feed(from: from, to: to);
      if (!mounted) return;
      setState(() {
        _byDay = feed.byDay();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.displayMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить календарь';
        _loading = false;
      });
    }
  }

  void _shiftMonths(int delta) {
    setState(() {
      _anchor = DateTime(_anchor.year, _anchor.month + delta);
    });
    _load();
  }

  List<CalendarEventItem> _eventsFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _byDay[key] ?? const [];
  }

  Future<void> _openAdd({DateTime? day}) async {
    final initial = day ?? _selectedDay ?? DateTime.now();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EventEditorSheet(
        initialDay: initial,
        onSave: (data) async {
          await context.read<CalendarService>().create(
                role: data.role,
                title: data.title,
                startsAt: data.startsAt,
                location: data.location,
                counterpartyName: data.counterpartyName,
                phone: data.phone,
                notes: data.notes,
              );
        },
      ),
    );
    if (saved == true && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие добавлено')),
      );
    }
  }

  Future<void> _openEdit(CalendarEventItem item) async {
    if (item.isManual && item.manualId != null) {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _EventEditorSheet(
          initialDay: item.startsAt,
          initial: item,
          onSave: (data) async {
            await context.read<CalendarService>().update(
                  item.manualId!,
                  role: data.role,
                  title: data.title,
                  startsAt: data.startsAt,
                  location: data.location,
                  counterpartyName: data.counterpartyName,
                  phone: data.phone,
                  notes: data.notes,
                );
          },
        ),
      );
      if (saved == true && mounted) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Событие обновлено')),
        );
      }
      return;
    }

    if (item.canReschedule && item.orderId != null) {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _OrderTimeSheet(
          initial: item,
          onSave: (startsAt) async {
            await context.read<CalendarService>().rescheduleOrder(
                  item.orderId!,
                  startsAt,
                );
          },
        ),
      );
      if (saved == true && mounted) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Время заказа обновлено')),
        );
      }
    }
  }

  Future<void> _delete(CalendarEventItem item) async {
    if (item.manualId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить событие?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<CalendarService>().delete(item.manualId!);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие удалено')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    }
  }

  Future<void> _openCreateOrder(DateTime day) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderCreateScreen(
          initialPreferredAt: DateTime(day.year, day.month, day.day, 10),
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay;
    final dayEvents = selected != null ? _eventsFor(selected) : const <CalendarEventItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM'),
        actions: [
          IconButton(
            tooltip: 'Назад',
            onPressed: () => _shiftMonths(-2),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Вперёд',
            onPressed: () => _shiftMonths(2),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(),
        icon: const Icon(Icons.add),
        label: const Text('Своя запись'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _load, child: const Text('Повторить')),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: _tray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _MonthGrid(
                      month: _monthA,
                      selectedDay: _selectedDay,
                      byDay: _byDay,
                      onSelect: (d) => setState(() => _selectedDay = d),
                    ),
                    const SizedBox(height: 14),
                    _MonthGrid(
                      month: _monthB,
                      selectedDay: _selectedDay,
                      byDay: _byDay,
                      onSelect: (d) => setState(() => _selectedDay = d),
                    ),
                    const SizedBox(height: 12),
                    const _Legend(),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (selected != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDayTitle(selected),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openCreateOrder(selected),
                    child: const Text('Создать заказ'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (dayEvents.isEmpty)
                Text(
                  'На этот день ничего нет. Добавьте заказ с другого сайта или откройте день с точкой.',
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                )
              else
                ...dayEvents.map(
                  (e) => _EventTile(
                    event: e,
                    onOpen: () async {
                      if (e.orderId != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderId: e.orderId!),
                          ),
                        );
                        await _load();
                      } else if (e.canEdit) {
                        await _openEdit(e);
                      }
                    },
                    onEdit: (e.canEdit || e.canReschedule) ? () => _openEdit(e) : null,
                    onDelete: e.canDelete ? () => _delete(e) : null,
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _openAdd(day: selected),
                icon: const Icon(Icons.add),
                label: const Text('Добавить на этот день'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDayTitle(DateTime d) {
    return '${d.day} ${_monthNames[d.month - 1].toLowerCase()} ${d.year}';
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.byDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final Map<DateTime, List<CalendarEventItem>> byDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final leading = firstWeekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = ((totalCells + 6) ~/ 7);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF6F7F6)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14143D33)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F142820),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brand,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _weekdays.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdays[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: i >= 5 ? _clientAccent : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            Row(
              children: List.generate(7, (c) {
                final index = r * 7 + c;
                final dayNum = index - leading + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }
                final day = DateTime(month.year, month.month, dayNum);
                final events = byDay[day] ?? const [];
                final isSelected = selectedDay != null &&
                    selectedDay!.year == day.year &&
                    selectedDay!.month == day.month &&
                    selectedDay!.day == day.day;
                final isToday = _isToday(day);
                final isWeekend = c >= 5;
                final hasProvider = events.any((e) => e.isProvider);
                final hasClient = events.any((e) => !e.isProvider);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _DayCell(
                      dayNum: dayNum,
                      isWeekend: isWeekend,
                      isBusy: events.isNotEmpty,
                      isSelected: isSelected,
                      isToday: isToday,
                      hasProvider: hasProvider,
                      hasClient: hasClient,
                      onTap: () => onSelect(day),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNum,
    required this.isWeekend,
    required this.isBusy,
    required this.isSelected,
    required this.isToday,
    required this.hasProvider,
    required this.hasClient,
    required this.onTap,
  });

  final int dayNum;
  final bool isWeekend;
  final bool isBusy;
  final bool isSelected;
  final bool isToday;
  final bool hasProvider;
  final bool hasClient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors;
    final List<BoxShadow> shadows;
    final Color textColor;
    final Color? ring;

    if (isSelected) {
      colors = const [Color(0xFF1A5C45), Color(0xFF0F3F30)];
      shadows = const [
        BoxShadow(
          color: Color(0x66001E12),
          blurRadius: 4,
          offset: Offset(0, 1),
          spreadRadius: -1,
        ),
      ];
      textColor = Colors.white;
      ring = null;
    } else if (isBusy) {
      colors = const [Color(0xFFD7EEE4), Color(0xFFC5E4D6)];
      shadows = const [
        BoxShadow(
          color: Color(0x33145C40),
          blurRadius: 3,
          offset: Offset(0, 1),
          spreadRadius: -1,
        ),
      ];
      textColor = const Color(0xFF145C40);
      ring = isToday ? AppTheme.brand : null;
    } else if (isWeekend) {
      colors = const [Color(0xFFFFFDFB), Color(0xFFF6E4DA)];
      shadows = const [
        BoxShadow(color: Colors.white70, blurRadius: 0, offset: Offset(-1, -1)),
        BoxShadow(
          color: Color(0x29142820),
          blurRadius: 4,
          offset: Offset(2, 3),
        ),
      ];
      textColor = const Color(0xFF9A3412);
      ring = isToday ? AppTheme.brand : null;
    } else {
      colors = const [Colors.white, Color(0xFFE7ECE9)];
      shadows = const [
        BoxShadow(color: Colors.white70, blurRadius: 0, offset: Offset(-1, -1)),
        BoxShadow(
          color: Color(0x29142820),
          blurRadius: 4,
          offset: Offset(2, 3),
        ),
      ];
      textColor = const Color(0xFF1F2937);
      ring = isToday ? AppTheme.brand : null;
    }

    final dotColor = isSelected ? Colors.white : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(7),
            border: ring != null ? Border.all(color: ring, width: 1.5) : null,
            boxShadow: shadows,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              if (isBusy) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasProvider)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dotColor ?? AppTheme.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasProvider && hasClient) const SizedBox(width: 3),
                    if (hasClient)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dotColor ?? _clientAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final CalendarEventItem event;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = event.isProvider ? AppTheme.brand : _clientAccent;
    final time =
        '${event.startsAt.hour.toString().padLeft(2, '0')}:${event.startsAt.minute.toString().padLeft(2, '0')}';
    final phone = event.phone?.trim();
    final notes = event.isManual ? event.notes?.trim() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$time · ${event.title}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        [
                          event.roleLabel,
                          event.source == 'order' ? 'zrabi' : 'вручную',
                          if (event.location != null && event.location!.isNotEmpty)
                            event.location!,
                          if (event.counterpartyName != null &&
                              event.counterpartyName!.isNotEmpty)
                            event.counterpartyName!,
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        Text(' · ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        GestureDetector(
                          onTap: () => _dial(phone),
                          child: Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.brand,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.brand.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                      if (event.statusLabel != null)
                        Text(
                          ' · ${event.statusLabel}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      if (notes != null && notes.isNotEmpty)
                        Text(
                          ' · ${_limit(notes, 90)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Редактировать',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: Colors.grey.shade600,
              visualDensity: VisualDensity.compact,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Удалить',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade600,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  static String _limit(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 1)}…';
  }

  static Future<void> _dial(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendDot(color: AppTheme.brand, label: 'Я исполнитель'),
        _LegendDot(color: _clientAccent, label: 'Я заказчик'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}

class _EventFormData {
  const _EventFormData({
    required this.role,
    required this.title,
    required this.startsAt,
    this.location,
    this.counterpartyName,
    this.phone,
    this.notes,
  });

  final String role;
  final String title;
  final DateTime startsAt;
  final String? location;
  final String? counterpartyName;
  final String? phone;
  final String? notes;
}

class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({
    required this.initialDay,
    required this.onSave,
    this.initial,
  });

  final DateTime initialDay;
  final CalendarEventItem? initial;
  final Future<void> Function(_EventFormData data) onSave;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _counterparty;
  late final TextEditingController _phone;
  late final TextEditingController _notes;
  late String _role;
  late DateTime _day;
  late TimeOfDay _time;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _location = TextEditingController(text: i?.location ?? '');
    _counterparty = TextEditingController(text: i?.counterpartyName ?? '');
    _phone = TextEditingController(text: i?.phone ?? '');
    _notes = TextEditingController(text: i?.notes ?? '');
    _role = i?.role ?? 'provider';
    _day = DateTime(
      (i?.startsAt ?? widget.initialDay).year,
      (i?.startsAt ?? widget.initialDay).month,
      (i?.startsAt ?? widget.initialDay).day,
    );
    _time = alignTimeOfDay(TimeOfDay.fromDateTime(i?.startsAt ?? widget.initialDay));
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _counterparty.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Укажите название');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _EventFormData(
          role: _role,
          title: title,
          startsAt: DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute),
          location: _location.text.trim(),
          counterpartyName: _counterparty.text.trim(),
          phone: _phone.text.trim(),
          notes: _notes.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.displayMessage;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось сохранить';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initial == null ? 'Своя запись' : 'Изменить запись',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'provider', label: Text('Я делаю')),
                ButtonSegment(value: 'client', label: Text('Мне делают')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Что',
                hintText: 'Установка унитаза, ремонт ТВ…',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _day,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) setState(() => _day = d);
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('${_day.day}.${_day.month}.${_day.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await pickFiveMinuteTime(context, _time);
                      if (t != null) setState(() => _time = alignTimeOfDay(t));
                    },
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Где',
                hintText: 'Сухарево',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _counterparty,
              decoration: const InputDecoration(
                labelText: 'Кто',
                hintText: 'Имя клиента или мастера',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                hintText: '+375 29 000-00-00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Заметка',
                hintText: 'Источник: Авито, Kufar…',
              ),
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.initial == null ? 'Добавить' : 'Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTimeSheet extends StatefulWidget {
  const _OrderTimeSheet({
    required this.initial,
    required this.onSave,
  });

  final CalendarEventItem initial;
  final Future<void> Function(DateTime startsAt) onSave;

  @override
  State<_OrderTimeSheet> createState() => _OrderTimeSheetState();
}

class _OrderTimeSheetState extends State<_OrderTimeSheet> {
  late DateTime _day;
  late TimeOfDay _time;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final at = widget.initial.startsAt;
    _day = DateTime(at.year, at.month, at.day);
    _time = alignTimeOfDay(TimeOfDay.fromDateTime(at));
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.displayMessage;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось сохранить';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Время заказа',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'У заказа zrabi здесь меняется только время.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            widget.initial.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setState(() => _day = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('${_day.day}.${_day.month}.${_day.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await pickFiveMinuteTime(context, _time);
                    if (t != null) setState(() => _time = alignTimeOfDay(t));
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(_time.format(context)),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
