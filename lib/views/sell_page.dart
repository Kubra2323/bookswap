import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../data/book_repository.dart';
import '../data/listing_repository.dart';
import '../models/listing.dart';
import '../models/price_guide.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/sell_view_model.dart';

class SellPage extends StatelessWidget {
  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SellViewModel>(
      create: (c) => SellViewModel(
        books: c.read<BookRepository>(),
        listings: c.read<ListingRepository>(),
        ownerId: c.read<AuthViewModel>().user!.uid,
      ),
      child: const _SellForm(),
    );
  }
}

class _SellForm extends StatefulWidget {
  const _SellForm();

  @override
  State<_SellForm> createState() => _SellFormState();
}

class _SellFormState extends State<_SellForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _isbn = TextEditingController();
  final _edition = TextEditingController();
  final _price = TextEditingController();
  String _condition = listingConditions[1];

  @override
  void dispose() {
    _title.dispose();
    _isbn.dispose();
    _edition.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sell a book')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // TODO(week 8): ISBN barcode scan (ML Kit) fills these fields.
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => validateRequired(v, 'the title'),
            ),
            TextFormField(
              controller: _isbn,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ISBN'),
              validator: validateIsbn,
            ),
            TextFormField(
              controller: _edition,
              decoration: const InputDecoration(labelText: 'Edition', hintText: '4th'),
              validator: (v) => validateRequired(v, 'the edition'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: [for (final c in listingConditions) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _condition = v ?? _condition),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: vm.loadingGuide ? null : _askGuide,
              icon: const Icon(Icons.auto_awesome),
              label: Text(vm.loadingGuide ? 'Looking up offers...' : 'Get AI price guide'),
            ),
            if (vm.guide != null) _GuideCard(guide: vm.guide!),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Your price (TL)'),
              validator: validatePriceTry,
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 8),
              Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: vm.publishing ? null : _publish,
              child: const Text('Publish listing'),
            ),
          ],
        ),
      ),
    );
  }

  void _askGuide() {
    final isbnError = validateIsbn(_isbn.text);
    final editionError = validateRequired(_edition.text, 'the edition');
    if (isbnError != null || editionError != null) {
      _formKey.currentState?.validate();
      return;
    }
    context.read<SellViewModel>().loadGuide(
          isbn: _isbn.text,
          edition: _edition.text,
          condition: _condition,
        );
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    final ok = await context.read<SellViewModel>().publish(
          title: _title.text,
          isbn: _isbn.text,
          edition: _edition.text,
          condition: _condition,
          priceTry: int.parse(_price.text.trim()),
        );
    if (ok) navigator.pop();
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final PriceGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (guide.hasEstimate) ...[
              Text('${guide.low}-${guide.high} TL', style: theme.textTheme.headlineSmall),
              Text('Based on ${guide.offersUsed} similar listings'),
              if (guide.summary != null) ...[const SizedBox(height: 8), Text(guide.summary!)],
              for (final c in guide.caveats) Text('• $c', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Text('Sources (listing id · price · date)', style: theme.textTheme.labelMedium),
              for (final s in guide.sources)
                Text('${s.listingId} · ${s.priceTry} TL · ${s.date?.split('T').first ?? '-'}',
                    style: theme.textTheme.bodySmall),
            ] else
              Text(_noEstimateText(guide)),
          ],
        ),
      ),
    );
  }

  // No range is shown when there is too little evidence. We never invent a price.
  String _noEstimateText(PriceGuide g) => g.reason == 'edition_required'
      ? 'Enter the edition to get a price guide.'
      : 'Only ${g.offersUsed} matching listings so far (we need at least 3). Set your own price.';
}
