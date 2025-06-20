import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // 模擬載入時間（實際應用中這裡會初始化各種服務）
      await Future.delayed(const Duration(seconds: 2));
      
      // 導航到主頁
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      // 處理初始化錯誤
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('初始化錯誤'),
        content: Text('應用程式初始化失敗：$error'),
        actions: [
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text('退出'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp();
            },
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkColorScheme.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.playerGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 應用程式圖標
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: AppTheme.playerAccent,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.playerAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.podcasts,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // 應用程式名稱
                      Text(
                        'Wolf Podcast',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.playerText,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // 標語
                      Text(
                        '您的專業 Podcast 播放器',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.playerSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      // 載入指示器
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.playerAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 載入文字
                      Text(
                        '正在初始化應用程式...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.playerSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 