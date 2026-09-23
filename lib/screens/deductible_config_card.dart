import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/deductible_template.dart';

class DeductibleConfigCard extends StatefulWidget {
  const DeductibleConfigCard({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const DeductibleConfigCard(),
    );
  }

  @override
  State<DeductibleConfigCard> createState() => _DeductibleConfigCardState();
}

class _DeductibleConfigCardState extends State<DeductibleConfigCard> {
  final FirestoreService _service = FirestoreService();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  String _type = 'percentage';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addDeductible() async {
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text) ?? 0;

    if (name.isEmpty) {
      _showError('Enter a deductible name');
      return;
    }
    if (value <= 0) {
      _showError('Value must be greater than 0');
      return;
    }
    if (_type == 'percentage' && value > 100) {
      _showError('Percentage cannot exceed 100');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.addDeductibleTemplate(DeductibleTemplate(
        id: '',
        name: name,
        type: _type,
        value: value,
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      _nameController.clear();
      _valueController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deductible added')),
      );
    } catch (e) {
      if (mounted) _showError('Failed to add deductible. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _deleteDeductible(DeductibleTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Deductible'),
        content: Text('Remove "${template.name}" from payroll deductibles?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: BaycelColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteDeductibleTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deductible removed')),
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to remove deductible. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: BaycelColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(BaycelSpacing.lg),
          decoration: BoxDecoration(
            color: BaycelColors.card,
            borderRadius: BorderRadius.circular(BaycelRadius.lg),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: BaycelSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddSection(),
                      SizedBox(height: BaycelSpacing.md),
                      _buildListSection(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: BaycelSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: BaycelComponents.buttonPrimary,
                  child: const Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BaycelColors.crimson.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calculate_outlined, color: BaycelColors.crimson, size: 20),
        ),
        SizedBox(width: BaycelSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payroll Deductibles',
                style: BaycelTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                'Applied to every generated payslip',
                style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20, color: BaycelColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildAddSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BaycelSpacing.md),
      decoration: BoxDecoration(
        color: BaycelColors.surface,
        borderRadius: BorderRadius.circular(BaycelRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Deductible', style: BaycelTypography.labelSm.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: BaycelSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: BaycelComponents.input.copyWith(hintText: 'Name (e.g., Tax, SSS, PhilHealth)'),
            style: BaycelTypography.body.copyWith(fontSize: 13),
            maxLength: 60,
          ),
          SizedBox(height: BaycelSpacing.xs),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Percentage'),
                  selected: _type == 'percentage',
                  onSelected: (_) => setState(() => _type = 'percentage'),
                  selectedColor: BaycelColors.crimson,
                  backgroundColor: BaycelColors.card,
                  labelStyle: BaycelTypography.labelSm.copyWith(
                    color: _type == 'percentage' ? Colors.white : BaycelColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: _type == 'percentage' ? BaycelColors.crimson : BaycelColors.divider,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.full)),
                  showCheckmark: false,
                ),
              ),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Fixed Amount'),
                  selected: _type == 'fixed',
                  onSelected: (_) => setState(() => _type = 'fixed'),
                  selectedColor: BaycelColors.crimson,
                  backgroundColor: BaycelColors.card,
                  labelStyle: BaycelTypography.labelSm.copyWith(
                    color: _type == 'fixed' ? Colors.white : BaycelColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: _type == 'fixed' ? BaycelColors.crimson : BaycelColors.divider,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.full)),
                  showCheckmark: false,
                ),
              ),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: BaycelComponents.input.copyWith(
              hintText: _type == 'percentage' ? 'Percent of gross pay' : 'Amount in pesos',
              suffixText: _type == 'percentage' ? '%' : '\u20B1',
              suffixStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
            ),
            style: BaycelTypography.body.copyWith(fontSize: 13),
            maxLength: 10,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _addDeductible,
              icon: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text('Add Deductible', style: const TextStyle(color: Colors.white)),
              style: BaycelComponents.buttonPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection() {
    return StreamBuilder<List<DeductibleTemplate>>(
      stream: _service.getDeductibleTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final templates = snapshot.data ?? [];
        if (templates.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: BaycelSpacing.base),
            decoration: BoxDecoration(
              color: BaycelColors.card,
              borderRadius: BorderRadius.circular(BaycelRadius.sm),
              border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                'No deductibles configured yet',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configured Deductibles', style: BaycelTypography.labelSm.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: BaycelSpacing.sm),
            ...templates.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: BaycelSpacing.xs),
                  padding: const EdgeInsets.symmetric(horizontal: BaycelSpacing.md, vertical: BaycelSpacing.sm),
                  decoration: BoxDecoration(
                    color: BaycelColors.card,
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                    border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        t.type == 'percentage' ? Icons.percent : Icons.payments_outlined,
                        size: 16,
                        color: BaycelColors.crimson,
                      ),
                      SizedBox(width: BaycelSpacing.sm),
                      Expanded(
                        child: Text(t.name, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: BaycelColors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(BaycelRadius.full),
                        ),
                        child: Text(
                          t.type == 'percentage' ? '${_trim(t.value)}% of gross' : '\u20B1${_trim(t.value)}',
                          style: BaycelTypography.labelXs.copyWith(color: BaycelColors.blue),
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.xs),
                      IconButton(
                        onPressed: () => _deleteDeductible(t),
                        icon: Icon(Icons.delete_outline, size: 18, color: BaycelColors.error),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}

String _trim(double value) {
  return value == value.truncateToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
