import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/listing_repository.dart';
import '../models/listing.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/listings_view_model.dart';
import 'sell_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Created here (not at app level) so it only reads Firestore after sign-in.
    return ChangeNotifierProvider<ListingsViewModel>(
      create: (c) => ListingsViewModel(c.read<ListingRepository>())..start(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ListingsViewModel>();
    final uid = context.read<AuthViewModel>().user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookSwap'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Title or ISBN',
              ),
              onChanged: vm.setQuery,
            ),
          ),
          Expanded(child: _list(context, vm, uid)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SellPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Sell a book'),
      ),
    );
  }

  Widget _list(BuildContext context, ListingsViewModel vm, String? uid) {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.error != null) return Center(child: Text(vm.error!));
    final items = vm.visible;
    if (items.isEmpty) return const Center(child: Text('No listings yet. Be the first to sell a book.'));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _ListingTile(listing: items[i], isMine: items[i].ownerId == uid),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.isMine});

  final Listing listing;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(listing.title),
      subtitle: Text('${listing.edition} · ${listing.condition}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${listing.priceTry} TL', style: Theme.of(context).textTheme.titleMedium),
          if (isMine)
            IconButton(
              tooltip: 'Mark as sold',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => context.read<ListingsViewModel>().markSold(listing.id),
            ),
        ],
      ),
    );
  }
}
