import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressRepository.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressesApi.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';
import 'package:jetkiz_mobile/features/addresses/presentation/addressFormPage.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({
    super.key,
    this.selectionMode = false,
    this.initialSelectedAddressId,
  });

  final bool selectionMode;
  final String? initialSelectedAddressId;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF7FAF5);

  late final AddressesApi _addressesApi;
  late final AddressRepository _addressRepository;

  bool _isLoading = true;
  String? _deletingAddressId;
  String? _error;
  List<Address> _addresses = [];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();

    _addressesApi = AddressesApi(ApiClient());
    _addressRepository = AddressRepository.instance;

    _selectedAddressId =
        widget.initialSelectedAddressId ?? _addressRepository.selectedAddressId;

    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _addressesApi.getMyAddresses();

      if (!mounted) return;

      _addressRepository.syncSelectedFromList(items);

      setState(() {
        _addresses = items;
        _selectedAddressId =
            _addressRepository.selectedAddressId ?? _selectedAddressId;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'Не удалось загрузить адреса. Проверь подключение и попробуй ещё раз.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateAddress() async {
    final result = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) => const AddressFormPage(),
      ),
    );

    if (!mounted || result == null) return;

    await _loadAddresses();

    if (widget.selectionMode && mounted) {
      _selectAddress(result);
    }
  }

  Future<void> _openEditAddress(Address address) async {
    final result = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(initialAddress: address),
      ),
    );

    if (!mounted || result == null) return;

    if (_addressRepository.selectedAddressId == address.id) {
      _addressRepository.setSelectedAddress(result);
    }

    await _loadAddresses();

    if (!mounted) return;

    if (_selectedAddressId == address.id) {
      setState(() {
        _selectedAddressId = result.id;
      });
    }
  }

  Future<void> _deleteAddress(Address address) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Удалить адрес?'),
              content: Text(
                'Адрес "${address.displayTitle}" будет удалён из сохранённых.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Удалить'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;
    if (_deletingAddressId != null) return;

    setState(() {
      _deletingAddressId = address.id;
    });

    try {
      await _addressesApi.deleteAddress(address.id);

      if (!mounted) return;

      if (_selectedAddressId == address.id) {
        _selectedAddressId = null;
      }

      _addressRepository.clearIfSelected(address.id);

      await _loadAddresses();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось удалить адрес'),
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingAddressId = null);
    }
  }

  void _selectAddress(Address address) {
    if (!widget.selectionMode) return;

    _addressRepository.setSelectedAddress(address);

    setState(() {
      _selectedAddressId = address.id;
    });

    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.selectionMode ? 'Адрес доставки' : 'Мои адреса';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(title),
      ),
      body: Column(
        children: [
          Container(
            color: _green,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.selectionMode
                        ? 'Выберите сохранённый адрес или добавьте новый'
                        : 'Управляйте своими адресами доставки',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openCreateAddress,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Добавить',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: _loadAddresses,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.error_outline_rounded,
            size: 54,
            color: Color(0xFFE53935),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton(
              onPressed: _loadAddresses,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ),
        ],
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.location_on_outlined,
            size: 56,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          const Text(
            'Сохранённых адресов пока нет',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте адрес сейчас, чтобы потом выбирать его одним нажатием при заказе.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: _openCreateAddress,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Добавить адрес'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isSelected = address.id == _selectedAddressId;
        final isDeleting = _deletingAddressId == address.id;

        return _AddressCard(
          address: address,
          isSelected: isSelected,
          isDeleting: isDeleting,
          selectionMode: widget.selectionMode,
          onTap: () {
            if (widget.selectionMode) {
              _selectAddress(address);
            }
          },
          onEditTap: isDeleting ? null : () => _openEditAddress(address),
          onDeleteTap: isDeleting ? null : () => _deleteAddress(address),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _addresses.length,
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.isDeleting,
    required this.selectionMode,
    required this.onTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final Address address;
  final bool isSelected;
  final bool isDeleting;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFF489F2A) : const Color(0xFFE5E7EB);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: selectionMode && !isDeleting ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddressIcon(
                isSelected: isSelected,
                isDeleting: isDeleting,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddressInfo(address: address),
              ),
              const SizedBox(width: 8),
              _AddressActions(
                isDeleting: isDeleting,
                onEditTap: onEditTap,
                onDeleteTap: onDeleteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressIcon extends StatelessWidget {
  const _AddressIcon({
    required this.isSelected,
    required this.isDeleting,
  });

  final bool isSelected;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    if (isDeleting) {
      return const SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEAF7E4) : const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSelected ? Icons.check_circle : Icons.location_on_outlined,
        color: isSelected ? const Color(0xFF489F2A) : const Color(0xFF6B7280),
      ),
    );
  }
}

class _AddressInfo extends StatelessWidget {
  const _AddressInfo({
    required this.address,
  });

  final Address address;

  @override
  Widget build(BuildContext context) {
    final details = address.shortDetails;
    final comment = address.comment?.trim() ?? '';
    final intercom = address.intercom?.trim() ?? '';
    final contactPhone = address.contactPhone?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.displayTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          address.address,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            height: 1.25,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            details,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.25,
            ),
          ),
        ],
        if (intercom.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Домофон: $intercom',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.25,
            ),
          ),
        ],
        if (contactPhone.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Телефон: $contactPhone',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.25,
            ),
          ),
        ],
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _AddressActions extends StatelessWidget {
  const _AddressActions({
    required this.isDeleting,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final bool isDeleting;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: isDeleting ? null : onEditTap,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Редактировать',
        ),
        IconButton(
          onPressed: isDeleting ? null : onDeleteTap,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Удалить',
        ),
      ],
    );
  }
}
