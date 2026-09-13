import 'package:flutter/material.dart';
import 'services/app_database.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  runApp(const SimmanoPengajianApp());
}

class SimmanoPengajianApp extends StatelessWidget {
  const SimmanoPengajianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMMANO PENGAJIAN V1 Lite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

enum AppRole { ketua, bendahara, sekretaris, anggota }

extension AppRoleLabel on AppRole {
  String get label => switch (this) {
        AppRole.ketua => 'Ketua',
        AppRole.bendahara => 'Bendahara',
        AppRole.sekretaris => 'Sekretaris',
        AppRole.anggota => 'Anggota',
      };
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  AppRole _role = AppRole.ketua;
  bool _loading = false;

  Future<void> _login() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengguna wajib diisi.')),
      );
      return;
    }
    setState(() => _loading = true);
    await SessionService.instance.login(name, _role);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(role: _role, name: name)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.groups_rounded, size: 64, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'SIMMANO PENGAJIAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Sederhana digunakan • Transparan dikelola • Histori aman',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Masuk ke aplikasi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama pengguna',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AppRole>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Peran',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: AppRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _role = value);
                    },
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Masuk'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppRole role;
  final String name;
  const HomePage({super.key, required this.role, required this.name});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(role: widget.role, name: widget.name),
      const PlaceholderPage(title: 'Kas'),
      const PlaceholderPage(title: 'Kelompok'),
      const PlaceholderPage(title: 'Anggota'),
      const MorePage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIMMANO PENGAJIAN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfilePage(name: widget.name, role: widget.role),
              ),
            ),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Kas'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Kelompok'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Anggota'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Lainnya'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final AppRole role;
  final String name;
  const DashboardPage({super.key, required this.role, required this.name});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Assalamu’alaikum, $name',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Peran: ${role.label}'),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _stat(context, 'Anggota', '0', Icons.people)),
          const SizedBox(width: 10),
          Expanded(child: _stat(context, 'Kelompok', '0', Icons.groups)),
        ]),
        Row(children: [
          Expanded(child: _stat(context, 'Saldo Kas', 'Rp 0', Icons.account_balance_wallet)),
          const SizedBox(width: 10),
          Expanded(child: _stat(context, 'Jadwal', '0', Icons.event)),
        ]),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fondasi aplikasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Bagian 01 menyiapkan login, role, navigasi, database lokal, '
                  'dan session. Modul berikutnya akan ditambahkan pada checkpoint selanjutnya.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title),
        ]),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Modul dibangun pada bagian berikutnya.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Lainnya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(leading: Icon(Icons.calendar_month), title: Text('Jadwal'))),
        Card(child: ListTile(leading: Icon(Icons.how_to_vote), title: Text('Voting / Musyawarah'))),
        Card(child: ListTile(leading: Icon(Icons.bar_chart), title: Text('Laporan'))),
        Card(child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Pengaturan'))),
        Card(child: ListTile(leading: Icon(Icons.security_outlined), title: Text('Keamanan & Audit'))),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String name;
  final AppRole role;
  const ProfilePage({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(name),
              subtitle: Text(role.label),
            ),
          ),
        ],
      ),
    );
  }
}
