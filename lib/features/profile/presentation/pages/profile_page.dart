import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import 'edit_profile_page.dart';
import '../../../portfolio/presentation/pages/create_portfolio_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  final String userEmail;
  final VoidCallback? onNavigateToDocuments;

  const ProfilePage({
    super.key,
    required this.token,
    required this.userEmail,
    this.onNavigateToDocuments,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _profileRepository = ProfileRepositoryImpl();
  final AuthLocalDataSource _authLocalDataSource = AuthLocalDataSourceImpl();

  ProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = _profile == null;
    });

    // 1. Try reading fast cached profile first
    final cached = await _profileRepository.getCachedProfile();
    if (cached != null && mounted && _profile == null) {
      setState(() {
        _profile = cached;
        _isLoading = false;
      });
    }

    // 2. Fetch fresh profile from GET /api/v1/profile
    try {
      final remoteProfile =
          await _profileRepository.getProfile(token: widget.token);
      if (mounted) {
        setState(() {
          _profile = remoteProfile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        // If we already had cached, don't show full screen error
        if (_profile == null) {
          final defaultUsername = widget.userEmail.contains('@')
              ? widget.userEmail.split('@').first
              : widget.userEmail;
          setState(() {
            _profile = ProfileModel(
              id: 'local_user',
              username: defaultUsername,
              email: widget.userEmail,
            );
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _openEditProfile() async {
    final current = _profile ??
        ProfileModel(
          id: 'user',
          username: widget.userEmail.split('@').first,
          email: widget.userEmail,
        );

    final updated = await Navigator.of(context).push<ProfileModel>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          token: widget.token,
          initialProfile: current,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _profile = updated);
      _loadProfile();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Lock Vault & Sign Out',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You will need your master password to unlock your vault next time.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authLocalDataSource.deleteToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  String? _resolvePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading && _profile == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildProfileHeaderCard(),
                            const SizedBox(height: 24),
                            _buildInfoSection(),
                            const SizedBox(height: 24),
                            _buildPrivacyAndSecurityCard(),
                            const SizedBox(height: 24),
                            _buildActionsSection(),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'User Profile',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          tooltip: 'Edit Profile',
          onPressed: _openEditProfile,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          tooltip: 'Sign Out',
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileHeaderCard() {
    final username = _profile?.username.isNotEmpty == true
        ? _profile!.username
        : widget.userEmail.split('@').first;
    final email = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : widget.userEmail;
    final photoUrl = _resolvePhotoUrl(_profile?.photoUrl);
    final bio = _profile?.bio;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with electric cyan glow ring
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceCard,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarInitial(username),
                    )
                  : _buildAvatarInitial(username),
            ),
          ),
          const SizedBox(height: 16),

          // Username with badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 13,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),

          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputField.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_rounded,
                  size: 16, color: AppColors.primary),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitial(String username) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final phone = _profile?.phoneNumber;
    final email = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : widget.userEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact & Account Information',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.alternate_email_rounded,
                iconColor: AppColors.primary,
                title: 'Username',
                value: _profile?.username.isNotEmpty == true
                    ? '@${_profile!.username}'
                    : 'Not set',
                trailing: 'Edit',
                onTap: _openEditProfile,
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildInfoTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.secondary,
                title: 'Email Address',
                value: email,
                trailing: 'Verified',
                trailingColor: AppColors.success,
                onTap: _openEditProfile,
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                iconColor: AppColors.accent,
                title: 'Phone Number',
                value: (phone != null && phone.isNotEmpty)
                    ? phone
                    : 'Add phone number',
                trailing: (phone != null && phone.isNotEmpty) ? 'Edit' : 'Add',
                onTap: _openEditProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String trailing,
    Color? trailingColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                color: trailingColor ?? AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: trailingColor ?? AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyAndSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy & Vault Encryption',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Default document privacy is set to Private',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Documents in your DocLock Vault remain strictly private and encrypted until you explicitly mark them as Public or include them in a Portfolio post.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        ListTile(
          tileColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          leading: const Icon(Icons.auto_awesome_mosaic_rounded,
              color: AppColors.accent),
          title: const Text(
            'Create New Portfolio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreatePortfolioPage(token: widget.token),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (widget.onNavigateToDocuments != null)
          ListTile(
            tileColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            leading: const Icon(Icons.folder_shared_outlined,
                color: AppColors.primary),
            title: const Text(
              'View My Vault Documents',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
            onTap: widget.onNavigateToDocuments,
          ),
      ],
    );
  }
}
