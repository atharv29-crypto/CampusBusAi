import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _studentBusId = TextEditingController();

  final AuthService _authService = AuthService();

  String _role = 'student';
  String? _selectedBusId;

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _studentBusId.dispose();
    super.dispose();
  }

  // Navigate back to Login Screen
  void _goToLogin({String? message}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    // RegisterScreen was opened using MaterialPageRoute
    Navigator.of(context).pop();

    if (message != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // Registration Function
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await _authService.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
        selectedBusId: _role == 'student' ? _selectedBusId : null,
        requestedStudentBusId: _role == 'parent'
            ? _studentBusId.text.trim()
            : '',
      );

      if (!mounted) return;

      // Registration successful - Return to Login
      _goToLogin(message: 'Account created successfully! Please login.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        _showAlreadyRegisteredDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Registration failed. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('AuthFlowException: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Duplicate Email Dialog
  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Account Already Exists'),
          content: const Text(
            'This email is already registered. '
            'Please login using your existing account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _goToLogin();
              },
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7900);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),

            child: Card(
              elevation: 2,
              color: Colors.white,

              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // Bus Icon
                      const Icon(Icons.directions_bus, color: orange, size: 54),

                      const SizedBox(height: 12),

                      // App Title
                      const Text(
                        'Join CampusBusAI 360',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Register As
                      DropdownButtonFormField<String>(
                        value: _role,

                        decoration: const InputDecoration(
                          labelText: 'Register as',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'parent',
                            child: Text('Parent'),
                          ),
                        ],

                        onChanged: _loading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _role = value;
                                    _selectedBusId = null;
                                    _studentBusId.clear();
                                  });
                                }
                              },
                      ),

                      const SizedBox(height: 16),

                      // Full Name
                      TextFormField(
                        controller: _name,

                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,

                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              !RegExp(
                                r'^[^@]+@[^@]+\.[^@]+$',
                              ).hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,

                        decoration: InputDecoration(
                          labelText: 'Password (minimum 6 characters)',

                          prefixIcon: const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },

                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),

                          border: const OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Student Bus Selection
                      if (_role == 'student')
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _authService.activeBusesStream(),

                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Unable to load buses: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final buses =
                                snapshot.data!.docs.where((doc) {
                                  final data = doc.data();

                                  return data['isActive'] == true &&
                                      (data['busNumber'] ?? '')
                                          .toString()
                                          .trim()
                                          .isNotEmpty;
                                }).toList()..sort((a, b) {
                                  return (a.data()['busNumber'] ?? '')
                                      .toString()
                                      .compareTo(
                                        (b.data()['busNumber'] ?? '')
                                            .toString(),
                                      );
                                });

                            if (buses.isEmpty) {
                              return const Text(
                                'No active buses available. '
                                'Please contact Admin.',
                              );
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedBusId,
                              isExpanded: true,

                              decoration: const InputDecoration(
                                labelText: 'Select Bus Number',
                                prefixIcon: Icon(Icons.directions_bus),
                                border: OutlineInputBorder(),
                              ),

                              items: buses.map((doc) {
                                return DropdownMenuItem<String>(
                                  value: doc.id,

                                  child: Text(
                                    (doc.data()['busNumber'] ?? 'Bus')
                                        .toString(),
                                  ),
                                );
                              }).toList(),

                              onChanged: _loading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedBusId = value;
                                      });
                                    },

                              validator: (value) {
                                if (value == null) {
                                  return 'Please select your bus';
                                }

                                return null;
                              },
                            );
                          },
                        )
                      // Parent Student Bus ID
                      else
                        TextFormField(
                          controller: _studentBusId,

                          textCapitalization: TextCapitalization.characters,

                          decoration: const InputDecoration(
                            labelText: 'Student Bus ID (e.g. A0001)',

                            prefixIcon: Icon(
                              Icons.confirmation_number_outlined,
                            ),

                            border: OutlineInputBorder(),
                          ),

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter Student Bus ID';
                            }

                            return null;
                          },
                        ),

                      // Student Information
                      if (_role == 'student') ...[
                        const SizedBox(height: 10),

                        const Text(
                          'Your Student Bus ID will be generated '
                          'automatically after registration.',

                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Create Account Button
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: orange,

                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),

                        onPressed: _loading ? null : _register,

                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Account'),
                      ),

                      const SizedBox(height: 16),

                      // Already Have Account
                      TextButton(
                        onPressed: _loading ? null : () => _goToLogin(),

                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
