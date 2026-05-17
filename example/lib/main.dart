import 'package:flutter/material.dart';
import 'package:hashed_image/hashed_image.dart';

void main() => runApp(const HashedImageExampleApp());

class HashedImageExampleApp extends StatelessWidget {
  const HashedImageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hashed_image Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data: (imageUrl, blurHash) pairs
// ---------------------------------------------------------------------------

const _items = [
  ('https://picsum.photos/seed/mp01/800/800', 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),

  ('https://picsum.photos/seed/mp03/800/800', 'L6PZfSi_.AyE_3t7t7R**0o#DgR4'),
  ('https://picsum.photos/seed/mp04/800/800', r'LKO2:N%2Tw=w]~RBVZRi};RPxuwH'),
  ('https://picsum.photos/seed/mp05/800/800', r'LFE.@D9F01_2%L%MIVD*9Goe-;WB'),
  ('https://picsum.photos/seed/mp06/800/800', r'LcF$nb_3WBkD?HkCx]oz%MaeRjj['),
  ('https://picsum.photos/seed/mp07/800/800', r'L9AdAqof00WCqZRjWBay~qj[-;ay'),
  ('https://picsum.photos/seed/mp08/800/800', r'LMjvI2j[xVfQ_3WBM{j[~qaeM{ay'),
  ('https://picsum.photos/seed/mp09/800/800', r'L77BAj~qOFD%~qIUM{xu00IUxuxu'),
  ('https://picsum.photos/seed/mp10/800/800', r'LfP6m+x[xboz~qoMjZj@_4WBWBay'),
  ('https://picsum.photos/seed/mp11/800/800', r'LIANcN9F-;j[?bj[Rjay00ay~qRj'),
  ('https://picsum.photos/seed/mp12/800/800', r'L4DJ1u00009F00WB9FRj00ofIUof'),
];

// ---------------------------------------------------------------------------

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _seed = 0;

  void _refresh() {
    DecayPermits.reset();
    setState(() => _seed++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hashed Image'),
        actions: [
          IconButton(icon: const Icon(Icons.replay), onPressed: _refresh),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, i) {
          final (url, hash) = _items[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ImageWithHash(
                    key: ValueKey('$_seed-$i'),
                    imageUrl: url,
                    imageHash: hash,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product ${i + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${(((i + 7) * 1234 % 90000) / 100).toStringAsFixed(2)}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
