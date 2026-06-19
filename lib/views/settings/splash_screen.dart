// lib/views/settings/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/logger.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.debug('SplashScreen initState');
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _controller.forward();
    
    // ✅ انتظر 3 ثواني ثم انتقل
    Future.delayed(const Duration(seconds: 3), () {
      if (!_navigated && mounted) _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    if (_navigated) return;
    _navigated = true;
    _logger.debug('SplashScreen _navigateNext called');
    
    try {
      final user = SupabaseService().currentUser;
      final isLoggedIn = user != null;
      
      _logger.debug('isLoggedIn = $isLoggedIn, user = ${user?.id ?? 'null'}');
      
      if (!mounted) return;
      
      // ✅ التحقق من وجود بيانات المستخدم
      if (isLoggedIn) {
        try {
          final userData = await SupabaseService().getUser(user.id);
          final hasProfile = userData != null && (userData.name?.isNotEmpty ?? false);
          
          Navigator.pushReplacementNamed(
            context,
            hasProfile ? '/home' : '/profile',
          );
        } catch (e) {
          _logger.error('Error loading user profile: $e');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e, s) {
      _logger.error('Error in SplashScreen _navigateNext: $e\n$s');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.privooGold.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.lock_outline,
                            size: 60,
                            color: AppTheme.privooDeepPurple,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Privoo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooGold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure • Private • Smart',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.privooGold),
                    strokeWidth: 2,
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