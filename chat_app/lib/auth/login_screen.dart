import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService auth = AuthService();
  final TextEditingController loginUsername = TextEditingController();
  final TextEditingController loginPassword = TextEditingController();
  final TextEditingController registerUsername = TextEditingController();
  final TextEditingController registerPassword = TextEditingController();
  final TextEditingController registerConfirmPassword = TextEditingController();

  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoginForm = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _toggleForm() {
    setState(() {
      _isLoginForm = !_isLoginForm;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void login() async {
    if (loginUsername.text.isEmpty || loginPassword.text.isEmpty) {
      _showSnackBar('Username và password không được để trống', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService().login(loginUsername.text, loginPassword.text);
    setState(() => _isLoading = false);

    if (result == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(username: loginUsername.text)),
      );
    } else {
      _showSnackBar(result ?? 'Đăng nhập thất bại', isError: true);
    }
  }

  void register() async {
    if (registerUsername.text.isEmpty || registerPassword.text.isEmpty || registerConfirmPassword.text.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin', isError: true);
      return;
    }

    if (registerPassword.text != registerConfirmPassword.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService().register(registerUsername.text, registerPassword.text);
    setState(() => _isLoading = false);

    if (result?.contains('thành công') == true) {
      _showSnackBar(result!, isError: false);
      setState(() {
        _isLoginForm = true;
        registerUsername.clear();
        registerPassword.clear();
        registerConfirmPassword.clear();
      });
    } else {
      _showSnackBar(result ?? 'Đăng ký thất bại', isError: true);
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
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Color(0xFFE74C3C) : Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF283593),
              Color(0xFF3949AB),
            ],
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
                    // Logo với hiệu ứng sang trọng
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.forum_rounded,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),

                    // Tiêu đề
                    Text(
                      _isLoginForm ? 'Chào Mừng Trở Lại' : 'Tạo Tài Khoản',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isLoginForm
                          ? 'Đăng nhập để tiếp tục trải nghiệm'
                          : 'Tham gia cộng đồng của chúng tôi',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 40),

                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: _isLoginForm ? _buildLoginForm() : _buildRegisterForm(),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Toggle button
                    TextButton(
                      onPressed: _toggleForm,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
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
                              style: TextStyle(
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
        SizedBox(height: 18),
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
        SizedBox(height: 28),
        _buildActionButton(
          label: 'Đăng Nhập',
          onPressed: login,
        ),
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
        SizedBox(height: 18),
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
        SizedBox(height: 18),
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
        SizedBox(height: 28),
        _buildActionButton(
          label: 'Đăng Ký',
          onPressed: register,
        ),
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
      style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
        prefixIcon: Icon(icon, color: Color(0xFF3949AB), size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (obscureText ?? true)
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Color(0xFF7F8C8D),
            size: 22,
          ),
          onPressed: onToggleVisibility,
        )
            : null,
        filled: true,
        fillColor: Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFECF0F1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFF3949AB), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
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
          backgroundColor: Color(0xFF3949AB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          shadowColor: Color(0xFF3949AB).withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
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