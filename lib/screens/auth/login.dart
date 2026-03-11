import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/screens/auth/forgotPassword.dart';
import 'package:hybstockadvisor/screens/auth/signup.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/screens/firstlogin.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/services/request.dart';
import 'package:hybstockadvisor/themes/theme.dart';
import 'package:hybstockadvisor/widgets/customButton.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.login(
      emailController.text.trim(),
      passwordController.text,
    );

    setState(() => _isLoading = false);

    // if (response['status'] == 'success') {
    //   String token = response['token'];
    //   String firstName = response['user_data']['first_name'];

    //   await RequestService.saveAuthToken(token);

    //   final box = await Hive.openBox('user');
    //   await box.put('first_name', firstName);

    //   // ✅ Check if portfolio already set up
    //   final hasSetup = box.get('has_setup_portfolio', defaultValue: false);

    //   if (mounted) {
    //     context.pushFade(hasSetup ? const Dashboard() : const FirstLogin());
    //   }
    // }
    if (response['status'] == 'success') {
      String token = response['token'];
      String firstName = response['user_data']['first_name'];
      int userId = response['user_data']['id'];

      await RequestService.saveAuthToken(token);

      // 🚨 FIX 1: YOU MUST SAVE THE USER ID SO THE API SERVICE KNOWS WHO IS LOGGED IN! 🚨
      final authBox = await Hive.openBox('auth');
      await authBox.put('user_id', userId);

      // Save user data to Hive
      final userBox = await Hive.openBox('user');
      await userBox.put('first_name', firstName);
      await userBox.put('last_name', response['user_data']['last_name'] ?? '');

      // Ask the database if they already have stocks
      bool needsSetup = true;

      // We check Hive first just in case
      final localSetupFlag = userBox.get(
        'has_setup_portfolio',
        defaultValue: false,
      );

      if (localSetupFlag) {
        needsSetup = false; // Fast path: Hive knows they are setup
      } else {
        // Slow path: Ask the Python API!
        // Because we JUST saved the user_id to authBox above, this will fetch the correct user!
        final assets = await ApiService.getUserAssets();
        if (assets != null) {
          List portfolio = assets['portfolio'] ?? [];
          List watchlist = assets['watchlist'] ?? [];

          if (portfolio.isNotEmpty || watchlist.isNotEmpty) {
            needsSetup = false;
            await userBox.put('has_setup_portfolio', true);
          }
        }
      }

      if (mounted) {
        // 🚨 FIX 2: DESTROY OLD SCREENS 🚨
        // pushFade keeps the old user's Dashboard hidden in the background.
        // pushAndRemoveUntil completely wipes the slate clean for the new user.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                needsSetup ? const FirstLogin() : const Dashboard(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      // Failed (Wrong password, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['detail']),
          backgroundColor: Colors.red,
        ),
      );
    }
    // if (response['status'] == 'success') {
    //   String token = response['token'];
    //   String firstName = response['user_data']['first_name'];
    //   int userId = response['user_data']['id'];

    //   await RequestService.saveAuthToken(token);

    //   // Save user data to Hive
    //   final userBox = await Hive.openBox('user');
    //   await userBox.put('first_name', firstName);
    //   await userBox.put(
    //     'last_name',
    //     response['user_data']['last_name'] ?? '',
    //   ); // ✅ save last name

    //   // 🚨 THE FIX: Ask the database if they already have stocks!
    //   bool needsSetup = true;

    //   // We check Hive first just in case
    //   final localSetupFlag = userBox.get(
    //     'has_setup_portfolio',
    //     defaultValue: false,
    //   );

    //   if (localSetupFlag) {
    //     needsSetup = false; // Fast path: Hive knows they are setup
    //   } else {
    //     // Slow path: Hive doesn't know (maybe they logged out or are on a new phone).
    //     // Let's ask the Python API!
    //     final assets = await ApiService.getUserAssets();
    //     if (assets != null) {
    //       List portfolio = assets['portfolio'] ?? [];
    //       List watchlist = assets['watchlist'] ?? [];

    //       if (portfolio.isNotEmpty || watchlist.isNotEmpty) {
    //         // They have data in the database! Skip setup.
    //         needsSetup = false;
    //         // Save it to Hive so we don't have to ask the database next time
    //         await userBox.put('has_setup_portfolio', true);
    //       }
    //     }
    //   }

    //   if (mounted) {
    //     // If needsSetup is true, go to FirstLogin. If false, go to Dashboard.
    //     context.pushFade(needsSetup ? const FirstLogin() : const Dashboard());
    //   }
    // } else {
    //   // Failed (Wrong password, etc.)
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(response['detail']),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
    // // if (response['status'] == 'success') {
    //   String token = response['token'];
    //   String firstName = response['user_data']['first_name'];
    //   int userId =
    //       response['user_data']['id']; // <-- GET THE USER ID FROM PYTHON

    //   await RequestService.saveAuthToken(token);

    //   // Save user data to Hive
    //   final userBox = await Hive.openBox('user');
    //   await userBox.put('first_name', firstName);
    //   await userBox.put('last_name', response['user_data']['last_name'] ?? '');

    //   // Check if portfolio already set up
    //   final hasSetup = userBox.get('has_setup_portfolio', defaultValue: false);

    //   if (mounted) {
    //     context.pushFade(hasSetup ? const Dashboard() : const FirstLogin());
    //   }
    // } else {
    //   // Failed (Wrong password, etc.)
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(response['detail']),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Logo Image
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 300,
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 16),

              // App Name
              const Text(
                'HYBSTOCKADVISOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Protect Your Investments with AI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(252, 242, 212, 1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: "Enter Email Address",
                              hintStyle: TextStyle(
                                color: HybStockAdvisor.darkBorderColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              errorStyle: TextStyle(fontSize: 0),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(252, 242, 212, 1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: passwordController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Enter Password",
                              hintStyle: const TextStyle(
                                color: HybStockAdvisor.darkBorderColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              errorStyle: const TextStyle(fontSize: 0),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              GestureDetector(
                onTap: () {
                  context.pushFade(const ForgotPassword());
                },
                child: Center(
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                child: CustomButton(
                  ontap: () {
                    // context.pushFade(const Dashboard());
                    handleLogin();
                  },
                  data: "Login",
                  textcolor: Colors.white,
                  backgroundcolor: _isLoading
                      ? Colors.grey
                      : const Color(0xFF0A3D62),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
                ),

              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Divider(
              //           color: HybStockAdvisor.darkBorderColor,
              //           thickness: 1,
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
              //         child: Text(
              //           "or",
              //           style: TextStyle(
              //             fontSize: 19,
              //             fontWeight: FontWeight.w500,
              //             color: HybStockAdvisor.darkBorderColor,
              //           ),
              //         ),
              //       ),
              //       Expanded(
              //         child: Divider(
              //           color: HybStockAdvisor.darkBorderColor,
              //           thickness: 1,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?    ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pushFade(const SignUp());
                      },
                      child: Text(
                        "Sign up now!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A3D62),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Padding(
              //   padding: const EdgeInsets.all(20.0),
              //   child: CustomButton(
              //     ontap: () {
              //       context.pushFade(const SignUp());
              //     },
              //     data: "Create An Account",
              //     textcolor: Colors.white,
              //     backgroundcolor: const Color(0xFF0A3D62),
              //     width: MediaQuery.of(context).size.width,
              //     height: 50,
              //   ),
              // ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Center(
                child: const Text(
                  "By Continuing, you agree to our",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Terms of Service",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    " and ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Privacy Policy",
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
