import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../documents/data/datasources/document_remote_datasource.dart';
import '../../../documents/data/models/document_model.dart';
import '../../../documents/presentation/pages/document_upload_page.dart';
import '../../../documents/presentation/pages/documents_list_page.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../portfolio/presentation/pages/portfolio_feed_page.dart';

class DashboardPage extends StatefulWidget {
  final String userEmail;
  final String? initialToken;

  const DashboardPage({
    super.key,
    required this.userEmail,
    this.initialToken,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final AuthLocalDataSource _localDataSource = AuthLocalDataSourceImpl();
  final DocumentRemoteDataSource _documentDataSource =
      DocumentRemoteDataSourceImpl();

  String? _token;
  bool _isLoadingDocs = false;
  final Set<String> _downloadingIds = {};

  List<DocumentModel> _recentDocuments = [
    DocumentModel(
      id: '1',
      title: 'Passport Copy',
      category: 'Identity',
      type: DocumentType.image,
      fileSize: '2.4 MB',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isPinned: true,
      tags: ['identity', 'travel'],
    ),
    DocumentModel(
      id: '2',
      title: 'Tax Return 2024',
      category: 'Finance',
      type: DocumentType.pdf,
      fileSize: '1.1 MB',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      tags: ['tax', 'finance'],
    ),
    DocumentModel(
      id: '3',
      title: 'Insurance Policy',
      category: 'Finance',
      type: DocumentType.pdf,
      fileSize: '850 KB',
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      tags: ['insurance'],
    ),
    DocumentModel(
      id: '4',
      title: 'Birth Certificate',
      category: 'Identity',
      type: DocumentType.certificate,
      fileSize: '540 KB',
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      isPinned: true,
      tags: ['identity', 'legal'],
    ),
    DocumentModel(
      id: '5',
      title: 'Property Deed',
      category: 'Legal',
      type: DocumentType.text,
      fileSize: '320 KB',
      updatedAt: DateTime.now().subtract(const Duration(days: 14)),
      tags: ['legal', 'property'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final token = _token ?? await _localDataSource.getToken();
    if (!mounted) return;
    setState(() => _token = token);

    if (token != null && token.isNotEmpty) {
      _fetchRecentDocuments(token);
    }
  }

  Future<void> _fetchRecentDocuments(String token) async {
    setState(() => _isLoadingDocs = true);
    try {
      final docs = await _documentDataSource.getDocuments(token: token);
      if (mounted && docs.isNotEmpty) {
        setState(() => _recentDocuments = docs);
      }
    } catch (_) {
      // Keep existing items if offline or error
    } finally {
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _userName {
    final email = widget.userEmail;
    final name = email.contains('@') ? email.split('@').first : email;
    if (name.isEmpty) return 'User';
    return name[0].toUpperCase() + name.substring(1);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _openUploadPage() async {
    String? token = _token;
    if (token == null || token.isEmpty) {
      token = await _localDataSource.getToken();
      if (mounted) setState(() => _token = token);
    }
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again.')),
      );
      return;
    }
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentUploadPage(token: token!),
      ),
    );
    if (!mounted) return;
    if (uploaded == true) {
      _fetchRecentDocuments(token);
    }
  }

  Future<void> _downloadAndOpenFile(DocumentModel doc) async {
    String? token = _token;
    if (token == null || token.isEmpty) {
      token = await _localDataSource.getToken();
      if (mounted) setState(() => _token = token);
    }
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to download.')),
      );
      return;
    }

    setState(() => _downloadingIds.add(doc.id));
    try {
      final filePath = await _documentDataSource.downloadDocument(
        token: token,
        documentId: doc.id,
        filename: doc.displayName,
      );
      if (!mounted) return;
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(doc.id));
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Lock Vault?',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your vault will be locked. You\'ll need your master password to unlock it again.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Lock Vault', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _localDataSource.deleteToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildBody(),
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        if (_token != null && _token!.isNotEmpty) {
          return DocumentsListPage(token: _token!);
        }
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case 2:
        return PortfolioFeedPage(
          token: _token ?? '',
          userEmail: widget.userEmail,
        );
      case 3:
        return ProfilePage(
          token: _token ?? '',
          userEmail: widget.userEmail,
          onNavigateToDocuments: () => setState(() => _selectedIndex = 1),
        );
      default:
        return _buildHomePage();
    }
  }

  // ─── HOME TAB ───────────────────────────────────────────────────────────────

  Widget _buildHomePage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildSecurityBanner(),
                const SizedBox(height: 28),
                _buildStatsRow(),
                const SizedBox(height: 28),
                _buildQuickActions(),
                const SizedBox(height: 28),
                _buildRecentDocumentsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting,',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _headerIconButton(Icons.search_rounded,
                      onTap: () => setState(() => _selectedIndex = 1)),
                  const SizedBox(width: 8),
                  _headerIconButton(Icons.notifications_outlined, onTap: () {}),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 3),
                    onLongPress: _handleLogout,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Color(0xFF070B14),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF0A1929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) =>
                Transform.scale(scale: _pulseAnimation.value, child: child),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: AppColors.success, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vault Secured',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'AES-256-GCM encryption \u2022 All documents protected',
                  style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard('${_recentDocuments.length}', 'Documents',
              Icons.folder_rounded, AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
              '4', 'Categories', Icons.grid_view_rounded, AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              _statCard('2', 'Shared', Icons.people_rounded, AppColors.accent),
        ),
      ],
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surfaceCard,
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _quickActionTile(
                icon: Icons.upload_file_rounded,
                label: 'Upload',
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF006B7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: _openUploadPage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF2D2B7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: _openUploadPage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.auto_awesome_mosaic_rounded,
                label: 'Portfolio',
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5A0), Color(0xFF005C3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.lock_clock_rounded,
                label: 'Audit',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFAB00), Color(0xFF7A4E00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Recent Documents', style: AppTextStyles.heading2),
                if (_isLoadingDocs) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text(
                'View All',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recentDocuments.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _documentCard(doc),
            )),
      ],
    );
  }

  Widget _documentCard(DocumentModel doc) {
    final isDownloading = _downloadingIds.contains(doc.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surfaceCard,
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: doc.accentColor.withValues(alpha: 0.1),
          onTap: () => _downloadAndOpenFile(doc),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: doc.accentColor.withValues(alpha: 0.12),
                    border: Border.all(
                        color: doc.accentColor.withValues(alpha: 0.25),
                        width: 1),
                  ),
                  child: Icon(doc.icon, color: doc.accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doc.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doc.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.push_pin_rounded,
                                  color: AppColors.warning.withValues(alpha: 0.8),
                                  size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _docTag(doc.category, doc.accentColor),
                          const SizedBox(width: 8),
                          Text(doc.fileSize, style: AppTextStyles.caption),
                          const Spacer(),
                          Text(_timeAgo(doc.updatedAt),
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isDownloading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _docTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }


  // ─── BOTTOM NAV ─────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.folder_rounded, 'Docs'),
              const SizedBox(width: 64), // FAB gap
              _navItem(2, Icons.auto_awesome_mosaic_rounded, 'Feed'),
              _navItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _openUploadPage,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded,
                color: Color(0xFF070B14), size: 28),
          ),
        ),
      ),
    );
  }
}
