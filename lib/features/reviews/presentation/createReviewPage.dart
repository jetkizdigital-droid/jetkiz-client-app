import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/reviews/data/createReviewApi.dart';
import 'package:jetkiz_mobile/features/reviews/data/reviewMediaUploadApi.dart';
import 'package:jetkiz_mobile/features/reviews/domain/createReviewModels.dart';

class CreateReviewPage extends StatefulWidget {
  const CreateReviewPage({
    super.key,
    required this.orderId,
    required this.restaurantName,
    this.restaurantImageUrl,
    this.restaurantRating,
    this.orderItemTitle,
    this.orderItemImageUrl,
    this.orderItemPrice,
  });

  final String orderId;
  final String restaurantName;
  final String? restaurantImageUrl;
  final double? restaurantRating;
  final String? orderItemTitle;
  final String? orderItemImageUrl;
  final int? orderItemPrice;

  @override
  State<CreateReviewPage> createState() => _CreateReviewPageState();
}

enum _DraftMediaType {
  photo,
}

class _DraftMediaItem {
  _DraftMediaItem({
    required this.id,
    required this.file,
    required this.type,
  });

  final String id;
  final File file;
  final _DraftMediaType type;

  bool get isPhoto => type == _DraftMediaType.photo;
}

class _QuickReactionOption {
  const _QuickReactionOption({
    required this.emoji,
    required this.label,
  });

  final String emoji;
  final String label;
}

class _CreateReviewPageState extends State<CreateReviewPage>
    with TickerProviderStateMixin {
  static const _green = Color(0xFF4CAF50);
  static const _greenDark = Color(0xFF45A049);
  static const _bg = Color(0xFFF9FAFB);
  static const _textMain = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF6B7280);
  static const _textLight = Color(0xFF9CA3AF);

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  late final CreateReviewApi _reviewApi;
  late final ReviewMediaUploadApi _uploadApi;

  final List<_QuickReactionOption> _reactionOptions = const [
    _QuickReactionOption(emoji: '👍', label: 'Вкусно'),
    _QuickReactionOption(emoji: '❤️', label: 'Любимое'),
    _QuickReactionOption(emoji: '🔥', label: 'Огонь'),
    _QuickReactionOption(emoji: '😋', label: 'Вау'),
  ];

  final Set<int> _selectedReactionIndexes = <int>{};
  final List<_DraftMediaItem> _draftMedia = <_DraftMediaItem>[];

  int _rating = 0;
  int _hoverRating = 0;

  bool _isSubmitting = false;
  bool _isUploading = false;
  bool _showSuccess = false;

  late final AnimationController _successScaleController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _reviewApi = CreateReviewApi(apiClient);
    _uploadApi = ReviewMediaUploadApi(apiClient);

    _successScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _successScale = CurvedAnimation(
      parent: _successScaleController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _successScaleController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _rating > 0;
  int get _effectiveRating => _hoverRating > 0 ? _hoverRating : _rating;

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Ужасно';
      case 2:
        return 'Плохо';
      case 3:
        return 'Нормально';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично';
      default:
        return '';
    }
  }

  String? _normalizeUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = AppConfig.baseUrl.trim();
    if (base.isEmpty) return raw;

    if (raw.startsWith('/')) {
      if (base.endsWith('/')) {
        return '${base.substring(0, base.length - 1)}$raw';
      }
      return '$base$raw';
    }

    if (base.endsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
  }

  Future<void> _pickPhotoFromCamera() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );

      if (file == null) return;

      HapticFeedback.lightImpact();

      setState(() {
        _draftMedia.add(
          _DraftMediaItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            file: File(file.path),
            type: _DraftMediaType.photo,
          ),
        );
      });
    } catch (_) {
      _showSnack('Не удалось сделать фото');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
        ],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null || path.trim().isEmpty) return;

      HapticFeedback.lightImpact();

      setState(() {
        _draftMedia.add(
          _DraftMediaItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            file: File(path),
            type: _DraftMediaType.photo,
          ),
        );
      });
    } catch (_) {
      _showSnack('Не удалось выбрать фото');
    }
  }

  void _removeMedia(String id) {
    setState(() {
      _draftMedia.removeWhere((item) => item.id == id);
    });
  }

  Future<List<CreateReviewMediaInput>> _uploadDraftMedia() async {
    if (_draftMedia.isEmpty) {
      return <CreateReviewMediaInput>[];
    }

    setState(() {
      _isUploading = true;
    });

    final uploaded = <CreateReviewMediaInput>[];

    try {
      for (final item in _draftMedia) {
        final response = await _uploadApi.uploadFile(item.file);
        uploaded.add(
          CreateReviewMediaInput(
            type: response.type,
            url: response.url,
            previewUrl: response.previewUrl,
          ),
        );
      }

      return uploaded;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_isFormValid || _isSubmitting) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final uploadedMedia = await _uploadDraftMedia();

      final selectedPros = _selectedReactionIndexes
          .map((index) => _reactionOptions[index].label)
          .toList();

      final request = CreateReviewRequest(
        orderId: widget.orderId,
        rating: _rating,
        text: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        pros: selectedPros.isEmpty ? null : selectedPros,
        media: uploadedMedia,
      );

      await _reviewApi.createReview(request);

      if (!mounted) return;

      setState(() {
        _showSuccess = true;
      });

      _successScaleController.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 1700));

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _showSnack('Не удалось отправить отзыв');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnack(String text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _buildPreviewCard(_DraftMediaItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        item.file,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedRestaurantImage = _normalizeUrl(widget.restaurantImageUrl);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(
                  onBackTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        height: 196,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (normalizedRestaurantImage != null)
                                Image.network(
                                  normalizedRestaurantImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return _HeroPlaceholder(
                                      title: widget.restaurantName,
                                    );
                                  },
                                )
                              else
                                _HeroPlaceholder(
                                  title: widget.restaurantName,
                                ),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x66000000),
                                      Color(0x33000000),
                                      Color(0xA6000000),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 2,
                                    sigmaY: 2,
                                  ),
                                  child: Container(
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.88),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 16,
                                                color: Color(0xFFFBBF24),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                ((widget.restaurantRating ?? 4.9))
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: _textMain,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _green.withOpacity(0.92),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 15,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'Доставлен',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      widget.restaurantName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Ваш заказ успешно доставлен',
                                      style: TextStyle(
                                        color: Color(0xE5FFFFFF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SectionCard(
                        child: Column(
                          children: [
                            const Text(
                              'Оцените ваш заказ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final star = index + 1;
                                final active = _effectiveRating >= star;

                                return MouseRegion(
                                  onEnter: (_) {
                                    setState(() {
                                      _hoverRating = star;
                                    });
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      _hoverRating = 0;
                                    });
                                  },
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _rating = star;
                                      });
                                    },
                                    child: AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      scale: active ? 1.14 : 1.0,
                                      curve: Curves.easeOutBack,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Icon(
                                          Icons.star_rounded,
                                          size: 42,
                                          color: active
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFD1D5DB),
                                          shadows: active
                                              ? const [
                                                  Shadow(
                                                    blurRadius: 12,
                                                    color: Color(0x80FBBF24),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _rating > 0
                                  ? Padding(
                                      key: ValueKey(_rating),
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        _ratingLabel,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _textMuted,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Вы заказали:',
                              style: TextStyle(
                                fontSize: 13,
                                color: _textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: widget.orderItemImageUrl != null &&
                                            widget.orderItemImageUrl!
                                                .trim()
                                                .isNotEmpty
                                        ? Image.network(
                                            _normalizeUrl(
                                                  widget.orderItemImageUrl,
                                                ) ??
                                                '',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return const _OrderImagePlaceholder();
                                            },
                                          )
                                        : const _OrderImagePlaceholder(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ((widget.orderItemTitle ?? '')
                                                .trim()
                                                .isEmpty)
                                            ? 'Ваш заказ'
                                            : widget.orderItemTitle!.trim(),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: _textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (widget.orderItemPrice != null)
                                        Text(
                                          '${widget.orderItemPrice} ₸',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: _green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ваше впечатление',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _textController,
                              focusNode: _textFocusNode,
                              minLines: 6,
                              maxLines: 10,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    'Поделитесь впечатлениями о заказе...\n\n• Что понравилось?\n• Как была доставка?\n• Какое блюдо было самым вкусным?',
                                hintStyle: const TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: _textLight,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.all(16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: _green,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: _textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Быстрые реакции',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  List.generate(_reactionOptions.length, (index) {
                                final option = _reactionOptions[index];
                                final active =
                                    _selectedReactionIndexes.contains(index);

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (active) {
                                        _selectedReactionIndexes.remove(index);
                                      } else {
                                        _selectedReactionIndexes.add(index);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? _green
                                          : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: active
                                            ? _green
                                            : const Color(0xFFE5E7EB),
                                        width: 2,
                                      ),
                                      boxShadow: active
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x334CAF50),
                                                blurRadius: 16,
                                                offset: Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedScale(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          scale: active ? 1.2 : 1,
                                          child: Text(
                                            option.emoji,
                                            style:
                                                const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          option.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: active
                                                ? Colors.white
                                                : _textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Добавить фото',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _MediaActionButton(
                                  color: const Color(0xFF3B82F6),
                                  icon: Icons.camera_alt_rounded,
                                  label: 'Фото',
                                  onTap: _pickPhotoFromCamera,
                                ),
                                _MediaActionButton(
                                  color: const Color(0xFF22C55E),
                                  icon: Icons.image_rounded,
                                  label: 'Галерея',
                                  onTap: _pickFromGallery,
                                ),
                              ],
                            ),
                            if (_draftMedia.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 104,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _draftMedia.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final item = _draftMedia[index];

                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          scale: 1,
                                          child: _buildPreviewCard(item),
                                        ),
                                        Positioned(
                                          top: -8,
                                          right: -8,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _removeMedia(item.id),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0x33000000),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Center(
                    child: ScaleTransition(
                      scale: _successScale,
                      child: Container(
                        width: 310,
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                color: _green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x334CAF50),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Спасибо!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Ваш отзыв успешно отправлен',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Он поможет другим сделать выбор',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: _textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: GestureDetector(
          onTap: (_isFormValid && !_isSubmitting) ? _submit : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: _isFormValid
                  ? const LinearGradient(
                      colors: [_green, _greenDark],
                    )
                  : null,
              color: _isFormValid ? null : const Color(0xFFE5E7EB),
              boxShadow: _isFormValid
                  ? const [
                      BoxShadow(
                        color: Color(0x334CAF50),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: _isSubmitting || _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isUploading ? 'Загрузка фото...' : 'Отправка...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Отправить отзыв',
                    style: TextStyle(
                      color:
                          _isFormValid ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBackTap,
  });

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: _CreateReviewPageState._textMain,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Оставить отзыв',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _CreateReviewPageState._textMain,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF3F4F6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MediaActionButton extends StatelessWidget {
  const _MediaActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _CreateReviewPageState._textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD1D5DB),
            Color(0xFF9CA3AF),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderImagePlaceholder extends StatelessWidget {
  const _OrderImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        size: 30,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}