import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../models/specialist_cabinet.dart';
import '../../services/order_service.dart';
import '../../services/specialist_cabinet_service.dart';
import '../../state/auth_controller.dart';
import '../theme/app_theme.dart';
import 'service_picker_sheet.dart';

class SpecialistCabinetScreen extends StatefulWidget {
  const SpecialistCabinetScreen({super.key});

  @override
  State<SpecialistCabinetScreen> createState() =>
      _SpecialistCabinetScreenState();
}

class _SpecialistCabinetScreenState extends State<SpecialistCabinetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController(text: '0');

  SpecialistCabinetMeta? _meta;
  List<SpecialistOfferingDraft> _offerings = [];
  List<SpecialistPromotionDraft> _promotions = [];
  List<Map<String, dynamic>> _educations = [];
  List<SpecialistPhotoItem> _photos = [];
  List<OrderServiceRef> _services = const [];
  List<NamedRef> _cities = const [];
  int? _cityId;
  int? _profileId;
  bool _isPublished = false;
  bool _loading = true;
  bool _saving = false;
  bool _photoBusy = false;
  String? _error;
  String? _statusHint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orderService = context.read<OrderService>();
      final cabinetService = context.read<SpecialistCabinetService>();
      final catalog = await orderService.catalogOptions();
      final payload = await cabinetService.show();
      if (!mounted) {
        return;
      }
      final profile = payload.profile;
      setState(() {
        _services = catalog.services;
        _cities = catalog.cities;
        _meta = payload.meta;
        _titleController.text = profile?.title ?? '';
        _bioController.text = profile?.bio ?? '';
        _experienceController.text = '${profile?.experienceYears ?? 0}';
        _cityId = profile?.cityId;
        _profileId = profile?.id;
        _isPublished = profile?.isPublished ?? false;
        _photos = List<SpecialistPhotoItem>.from(profile?.photos ?? const []);
        _offerings = profile?.offerings.isNotEmpty == true
            ? profile!.offerings
                .map(
                  (o) => SpecialistOfferingDraft(
                    serviceId: o.serviceId,
                    pendingServiceName: o.pendingServiceName,
                    pendingServiceCategory: o.pendingServiceCategory,
                    title: o.title,
                    type: o.type,
                    from: o.from,
                    to: o.to,
                    unit: o.unit,
                    note: o.note,
                  ),
                )
                .toList()
            : [SpecialistOfferingDraft()];
        _promotions = profile?.promotions
                .map(
                  (p) => SpecialistPromotionDraft(
                    badge: p.badge,
                    text: p.text,
                  ),
                )
                .toList() ??
            [];
        _educations = profile?.educations
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        _statusHint = _statusText(payload.meta.specialistStatus);
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить анкету');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Статус: исполнитель';
      case 'pending':
        return 'Статус: на модерации';
      case 'rejected':
        return 'Статус: отклонено — можно подать снова';
      case 'none':
        return 'Заполните анкету и сохраните — отправим на проверку';
      default:
        return '';
    }
  }

  void _addOffering() {
    setState(() => _offerings.add(SpecialistOfferingDraft()));
  }

  void _removeOffering(int index) {
    if (_offerings.length <= 1) {
      return;
    }
    setState(() => _offerings.removeAt(index));
  }

  void _addPromotion() {
    if (_promotions.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Можно добавить не больше 10 акций')),
      );
      return;
    }
    setState(() => _promotions.add(SpecialistPromotionDraft()));
  }

  void _removePromotion(int index) {
    setState(() => _promotions.removeAt(index));
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_photoBusy) {
      return;
    }
    if (_profileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала сохраните анкету, потом добавляйте фото'),
        ),
      );
      return;
    }
    final max = _meta?.maxPhotos ?? 20;
    if (_photos.length >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Можно загрузить не больше $max фото')),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() => _photoBusy = true);
    try {
      final photo = await context.read<SpecialistCabinetService>().uploadPhoto(
            filePath: file.path,
            fileName: file.name,
          );
      if (!mounted) {
        return;
      }
      setState(() => _photos = [..._photos, photo]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото загружено')),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить фото')),
      );
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  Future<void> _deletePhoto(SpecialistPhotoItem photo) async {
    if (_photoBusy) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить фото?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _photoBusy = true);
    try {
      await context.read<SpecialistCabinetService>().deletePhoto(photo.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _photos = _photos.where((item) => item.id != photo.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото удалено')),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить фото')),
      );
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  Future<void> _movePhoto(int index, int delta) async {
    final next = index + delta;
    if (_photoBusy || next < 0 || next >= _photos.length) {
      return;
    }
    final reordered = List<SpecialistPhotoItem>.from(_photos);
    final item = reordered.removeAt(index);
    reordered.insert(next, item);
    setState(() {
      _photos = reordered;
      _photoBusy = true;
    });
    try {
      final updated = await context
          .read<SpecialistCabinetService>()
          .reorderPhotos(reordered.map((e) => e.id).toList());
      if (!mounted) {
        return;
      }
      if (updated.isNotEmpty) {
        setState(() => _photos = updated);
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось изменить порядок')),
      );
      await _load();
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    for (var i = 0; i < _offerings.length; i++) {
      final row = _offerings[i];
      final pendingName = row.pendingServiceName?.trim() ?? '';
      final pendingCategory = row.pendingServiceCategory?.trim() ?? '';
      if (pendingName.isNotEmpty != pendingCategory.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Позиция ${i + 1}: укажите и категорию, и название новой услуги',
            ),
          ),
        );
        return;
      }
      if (row.serviceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Выберите услугу в позиции ${i + 1}')),
        );
        return;
      }
      if (row.title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Укажите название в позиции ${i + 1}')),
        );
        return;
      }
    }
    for (var i = 0; i < _promotions.length; i++) {
      final promo = _promotions[i];
      final badgeEmpty = promo.badge.trim().isEmpty;
      final textEmpty = promo.text.trim().isEmpty;
      if (badgeEmpty && textEmpty) {
        continue;
      }
      if (badgeEmpty || textEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Акция ${i + 1}: заполните и плашку, и текст (или удалите строку)',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final cabinetService = context.read<SpecialistCabinetService>();
      final auth = context.read<AuthController>();
      final payload = await cabinetService.save(
            title: _titleController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            cityId: _cityId,
            experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
            isPublished: _isPublished,
            offerings: _offerings,
            promotions: _promotions,
            educations: _educations,
          );
      if (!mounted) {
        return;
      }
      if (payload.userJson != null) {
        await auth.refreshMe();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _meta = payload.meta;
        _profileId = payload.profile?.id ?? _profileId;
        _isPublished = payload.profile?.isPublished ?? _isPublished;
        _photos = List<SpecialistPhotoItem>.from(
          payload.profile?.photos ?? _photos,
        );
        if (payload.profile != null) {
          _promotions = payload.profile!.promotions
              .map(
                (p) => SpecialistPromotionDraft(
                  badge: p.badge,
                  text: p.text,
                ),
              )
              .toList();
          _educations = payload.profile!.educations
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        _statusHint = _statusText(payload.meta.specialistStatus);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            payload.meta.specialistStatus == 'pending' &&
                    !(payload.meta.canPublish)
                ? 'Анкета сохранена и отправлена на модерацию'
                : 'Анкета сохранена',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить анкету')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Анкета специалиста')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppTheme.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppTheme.formPadding,
                    children: [
                      if (_statusHint != null && _statusHint!.isNotEmpty) ...[
                        Text(
                          _statusHint!,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Специализация',
                          hintText: 'Например, Сантехник',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Укажите специализацию';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'О себе',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        value: _cityId,
                        decoration: const InputDecoration(labelText: 'Город'),
                        items: [
                          for (final city in _cities)
                            DropdownMenuItem(
                              value: city.id,
                              child: Text(city.name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _cityId = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Опыт, лет',
                        ),
                      ),
                      if (_meta?.canPublish == true) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Опубликовать анкету'),
                          value: _isPublished,
                          onChanged: (value) =>
                              setState(() => _isPublished = value),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Фото',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _photoBusy ? null : _pickAndUploadPhoto,
                            icon: _photoBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              '${_photos.length}/${_meta?.maxPhotos ?? 20}',
                            ),
                          ),
                        ],
                      ),
                      if (_profileId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Сохраните анкету — после этого можно добавлять фото.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      else if (_photos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Пока нет фото. Добавьте работы или портрет.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      else
                        SizedBox(
                          height: 132,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              return _PhotoTile(
                                photo: photo,
                                canMoveLeft: index > 0,
                                canMoveRight: index < _photos.length - 1,
                                busy: _photoBusy,
                                onDelete: () => _deletePhoto(photo),
                                onMoveLeft: () => _movePhoto(index, -1),
                                onMoveRight: () => _movePhoto(index, 1),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Прайс',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addOffering,
                            icon: const Icon(Icons.add),
                            label: const Text('Позиция'),
                          ),
                        ],
                      ),
                      for (var i = 0; i < _offerings.length; i++)
                        _OfferingCard(
                          index: i,
                          offering: _offerings[i],
                          services: _services,
                          priceTypes: _meta?.priceTypes ?? const {},
                          priceUnits: _meta?.priceUnits ?? const {},
                          canRemove: _offerings.length > 1,
                          onRemove: () => _removeOffering(i),
                          onChanged: () => setState(() {}),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Акции',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addPromotion,
                            icon: const Icon(Icons.local_offer_outlined),
                            label: const Text('Акция'),
                          ),
                        ],
                      ),
                      Text(
                        'Плашка (например −10%) и короткий текст. До 10 штук.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_promotions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Пока без акций — добавьте, если есть скидка или спецпредложение.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      for (var i = 0; i < _promotions.length; i++)
                        _PromotionCard(
                          index: i,
                          promotion: _promotions[i],
                          onRemove: () => _removePromotion(i),
                          onChanged: () => setState(() {}),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _meta?.canApply == true
                                    ? 'Сохранить и отправить'
                                    : 'Сохранить',
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({
    required this.index,
    required this.offering,
    required this.services,
    required this.priceTypes,
    required this.priceUnits,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final SpecialistOfferingDraft offering;
  final List<OrderServiceRef> services;
  final Map<String, String> priceTypes;
  final Map<String, String> priceUnits;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  Future<void> _pickService(BuildContext context) async {
    final result = await showServicePickerSheet(
      context: context,
      services: services,
      current: offering,
    );
    if (result == null) {
      return;
    }
    offering.serviceId = result.service.id;
    if (result.isPending) {
      offering.pendingServiceName = result.pendingName;
      offering.pendingServiceCategory = result.pendingCategory;
      if (offering.title.trim().isEmpty) {
        offering.title = result.pendingName!.trim();
      }
    } else {
      offering.pendingServiceName = null;
      offering.pendingServiceCategory = null;
      if (offering.title.trim().isEmpty) {
        offering.title = result.service.name;
      }
    }
    onChanged();
  }

  String _serviceLabel() {
    if (offering.isPending) {
      return '${offering.pendingLabel} (на проверке)';
    }
    if (offering.serviceId == null) {
      return 'Выберите услугу или предложите новую';
    }
    for (final service in services) {
      if (service.id == offering.serviceId) {
        final category = service.category?.name;
        if (category == null || category.isEmpty) {
          return service.name;
        }
        return '$category → ${service.name}';
      }
    }
    return 'Услуга #${offering.serviceId}';
  }

  @override
  Widget build(BuildContext context) {
    final types = priceTypes.isEmpty
        ? const {
            'from': 'Цена от',
            'fixed': 'Фиксированная',
            'range': 'Диапазон',
            'negotiable': 'По договорённости',
          }
        : priceTypes;
    final units = priceUnits.isEmpty
        ? const {
            'service': 'за услугу',
            'hour': 'за час',
            'visit': 'за выезд',
          }
        : priceUnits;
    final scheme = Theme.of(context).colorScheme;
    final pending = offering.isPending;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Позиция ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            Material(
              color: pending
                  ? const Color(0xFFFFF8E8)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pickService(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pending
                            ? Icons.hourglass_top_rounded
                            : Icons.handyman_outlined,
                        color: pending
                            ? const Color(0xFFB45309)
                            : scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pending ? 'Услуга на проверке' : 'Услуга',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _serviceLabel(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: offering.serviceId == null && !pending
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: offering.title,
              decoration: const InputDecoration(labelText: 'Название работы'),
              onChanged: (value) => offering.title = value,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: types.containsKey(offering.type) ? offering.type : 'from',
              decoration: const InputDecoration(labelText: 'Тип цены'),
              items: [
                for (final entry in types.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (value) {
                offering.type = value ?? 'from';
                onChanged();
              },
            ),
            if (offering.type != 'negotiable') ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: offering.from?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Цена, BYN'),
                onChanged: (value) {
                  offering.from = int.tryParse(value.trim());
                },
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: units.containsKey(offering.unit) ? offering.unit : 'service',
              decoration: const InputDecoration(labelText: 'Единица'),
              items: [
                for (final entry in units.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (value) {
                offering.unit = value ?? 'service';
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.busy,
    required this.onDelete,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final SpecialistPhotoItem photo;
  final bool canMoveLeft;
  final bool canMoveRight;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photo.thumbUrl.isNotEmpty ? photo.thumbUrl : photo.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: busy ? null : onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
                onPressed: busy || !canMoveLeft ? null : onMoveLeft,
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
                onPressed: busy || !canMoveRight ? null : onMoveRight,
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.index,
    required this.promotion,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final SpecialistPromotionDraft promotion;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Акция ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Удалить',
                ),
              ],
            ),
            TextFormField(
              initialValue: promotion.badge,
              decoration: const InputDecoration(
                labelText: 'Плашка',
                hintText: '−10% / Акция / Подарок',
              ),
              maxLength: 24,
              onChanged: (value) {
                promotion.badge = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: promotion.text,
              decoration: const InputDecoration(
                labelText: 'Текст акции',
                hintText: 'Скидка на первый вызов',
              ),
              maxLength: 160,
              maxLines: 2,
              onChanged: (value) {
                promotion.text = value;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
