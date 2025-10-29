import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService auth = AuthService();
  final loginUsername = TextEditingController();
  final loginPassword = TextEditingController();
  final registerUsername = TextEditingController();
  final registerPassword = TextEditingController();
  final registerConfirmPassword = TextEditingController();

  bool _isLoginForm = true;
  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _login() async {
    final username = loginUsername.text.trim();
    final password = loginPassword.text;
    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await auth.login(username, password);
    setState(() => _isLoading = false);

    if (res == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(username: username)),
      );
    } else {
      _showSnackBar(res ?? 'Đăng nhập thất bại', isError: true);
    }
  }

  Future<void> _register() async {
    final user = registerUsername.text.trim();
    final pass = registerPassword.text;
    final confirm = registerConfirmPassword.text;

    if (user.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin', isError: true);
      return;
    }
    if (pass != confirm) {
      _showSnackBar('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await auth.register(user, pass);
    setState(() => _isLoading = false);

    if (res?.contains('thành công') == true) {
      _showSnackBar('Đăng ký thành công! Hãy đăng nhập.', isError: false);
      setState(() {
        _isLoginForm = true;
        registerUsername.clear();
        registerPassword.clear();
        registerConfirmPassword.clear();
      });
    } else {
      _showSnackBar(res ?? 'Đăng ký thất bại', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleForm() {
    setState(() {
      _isLoginForm = !_isLoginForm;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.forum_rounded, size: 70, color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _isLoginForm ? 'Chào mừng trở lại' : 'Tạo tài khoản',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginForm
                          ? 'Đăng nhập để tiếp tục trải nghiệm'
                          : 'Tham gia cộng đồng của chúng tôi',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: _isLoginForm ? _buildLoginForm() : _buildRegisterForm(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _toggleForm,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          children: [
                            TextSpan(
                              text: _isLoginForm
                                  ? 'Chưa có tài khoản? '
                                  : 'Đã có tài khoản? ',
                            ),
                            TextSpan(
                              text: _isLoginForm ? 'Đăng ký ngay' : 'Đăng nhập',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: loginUsername,
          label: 'Username',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: loginPassword,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureLoginPassword,
          onToggleVisibility: () {
            setState(() => _obscureLoginPassword = !_obscureLoginPassword);
          },
        ),
        const SizedBox(height: 28),
        _buildActionButton(label: 'Đăng nhập', onPressed: _login),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _buildTextField(
          controller: registerUsername,
          label: 'Username',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: registerPassword,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureRegisterPassword,
          onToggleVisibility: () {
            setState(() => _obscureRegisterPassword = !_obscureRegisterPassword);
          },
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: registerConfirmPassword,
          label: 'Xác nhận Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        const SizedBox(height: 28),
        _buildActionButton(label: 'Đăng ký', onPressed: _register),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && (obscureText ?? true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF3949AB)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (obscureText ?? true)
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF7F8C8D),
          ),
          onPressed: onToggleVisibility,
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3949AB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    loginUsername.dispose();
    loginPassword.dispose();
    registerUsername.dispose();
    registerPassword.dispose();
    registerConfirmPassword.dispose();
    super.dispose();
  }
}
