import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/datasources/portfolio_remote_datasource.dart';
import '../../data/models/portfolio_model.dart';
import '../widgets/portfolio_card.dart';
import 'create_portfolio_page.dart';

class PortfolioFeedPage extends StatefulWidget {
  final String token;
  final String userEmail;

  const PortfolioFeedPage({
    super.key,
    required this.token,
    required this.userEmail,
  });

  @override
  State<PortfolioFeedPage> createState() => _PortfolioFeedPageState();
}

class _PortfolioFeedPageState extends State<PortfolioFeedPage> {
  final _dataSource = PortfolioRemoteDataSourceImpl();

  List<PortfolioModel> _portfolios = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPortfolios();
  }

  Future<void> _fetchPortfolios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _dataSource.getPortfolios(token: widget.token);
      if (mounted) {
        setState(() {
          _portfolios = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreatePortfolio() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreatePortfolioPage(token: widget.token),
      ),
    );
    if (created == true) {
      _fetchPortfolios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolios & Feed',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Discover public showcases & interact',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _openCreatePortfolio,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.black),
              label: const Text(
                'Post',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPortfolios,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.error, size: 54),
              const SizedBox(height: 16),
              const Text('Could not load portfolios',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPortfolios,
                icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                label: const Text('Try Again',
                    style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_portfolios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.auto_awesome_mosaic_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Portfolios Yet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create and publish your first portfolio post to showcase your documents and credentials to the community.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openCreatePortfolio,
                icon: const Icon(Icons.add_rounded, color: Colors.black),
                label: const Text(
                  'Create Portfolio',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _portfolios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final portfolio = _portfolios[index];
        return PortfolioCard(
          token: widget.token,
          portfolio: portfolio,
          currentUserId: widget.userEmail,
          onPortfolioUpdated: _fetchPortfolios,
        );
      },
    );
  }
}
