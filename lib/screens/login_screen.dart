import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../database/database.dart';
import 'tasks_list_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    if (username.isEmpty || password.isEmpty) {
      _showError('يرجى ملء جميع الحقول');
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      if (_isLogin) {
        final user = await _dbHelper.getUserByUsername(username);
        if (user != null && user.password == password) {
          await _saveUserSession(user.id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TasksListScreen(userId: user.id)),
          );
        } else {
          _showError('اسم المستخدم أو كلمة المرور غير صحيحة');
        }
      } else {
        // تسجيل جديد
        final existingUser = await _dbHelper.getUserByUsername(username);
        if (existingUser != null) {
          _showError('اسم المستخدم موجود مسبقاً');
        } else {
          final newUser = User(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: username,
            password: password,
            createdAt: DateTime.now(),
          );
          
          await _dbHelper.insertUser(newUser);
          await _saveUserSession(newUser.id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TasksListScreen(userId: newUser.id)),
          );
        }
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue.shade700, Colors.purple.shade500],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _authenticate,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.blue.shade800,
                              ),
                              child: Text(
                                _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() => _isLogin = !_isLogin);
                      },
                      child: Text(
                        _isLogin
                            ? 'ليس لديك حساب؟ إنشاء حساب جديد'
                            : 'لديك حساب بالفعل؟ تسجيل الدخول',
                        style: TextStyle(color: Colors.blue.shade800),
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}