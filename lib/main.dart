import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'models.dart';

const green = Color(0xFF145943);
const deepGreen = Color(0xFF083F2C);
const gold = Color(0xFFF6C53D);
const cream = Color(0xFFF7F5EC);
const orange = Color(0xFFF39A1F);

void main() => runApp(const MaphricApp());

class MaphricApp extends StatefulWidget {
  const MaphricApp({super.key});
  @override
  State<MaphricApp> createState() => _MaphricAppState();
}

class _MaphricAppState extends State<MaphricApp> {
  final api = ApiService();
  bool loading = true;
  bool signedIn = false;
  Map<String, dynamic> user = {};

  @override
  void initState() {
    super.initState();
    api.restoreSession().then((value) {
      if (mounted) {
        setState(() {
          signedIn = value;
          user = api.currentUser;
          loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Maphric Express',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        secondary: orange,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: cream,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: green.withValues(alpha: .10)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFDCEBDF),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
    home: loading
        ? const SplashScreen()
        : signedIn
        ? MobileHome(
            api: api,
            user: user,
            logout: () async {
              await api.logout();
              setState(() {
                signedIn = false;
                user = {};
              });
            },
          )
        : AuthScreen(
            api: api,
            onSignedIn: (value) => setState(() {
              user = value;
              signedIn = true;
            }),
          ),
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 100,
    this.width,
    this.asset = 'assets/images/maphric_logo.png',
    this.padding = 8,
  });
  final double height;
  final double? width;
  final String asset;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width ?? double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: const Color(0xFFE3E4DE),
      borderRadius: BorderRadius.circular(22),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(asset, fit: BoxFit.contain, alignment: Alignment.center),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: deepGreen,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutBack,
          tween: Tween(begin: .72, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(scale: value, child: child),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(height: 180),
              SizedBox(height: 24),
              Text(
                'Fresh groceries. Fast delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: gold),
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.api, required this.onSignedIn});
  final ApiService api;
  final ValueChanged<Map<String, dynamic>> onSignedIn;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signup = true, busy = false, obscure = true;
  String error = '';
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      if (signup) {
        if (name.text.trim().isEmpty ||
            email.text.trim().isEmpty ||
            phone.text.trim().isEmpty ||
            password.text.length < 8) {
          throw ApiException(
            'Complete every field and use at least 8 password characters.',
          );
        }
        await widget.api.register(
          name: name.text,
          email: email.text,
          phone: phone.text,
          password: password.text,
        );
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {
          signup = false;
          username.text = email.text;
          password.clear();
        });
      } else {
        final authenticatedUser = await widget.api.login(
          username.text.trim(),
          password.text,
        );
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
        widget.onSignedIn(authenticatedUser);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;
        return Stack(
          children: [
            const _AuthBackground(),
            if (wide)
              Positioned(
                left: 64,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * .43,
                child: const _DesktopAuthHero(),
              ),
            SafeArea(
              child: Align(
                alignment: wide ? Alignment.centerRight : Alignment.center,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, wide ? 64 : 24, 24),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, 28 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: cream.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .75),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: deepGreen.withValues(alpha: .20),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            const BrandLogo(
                              height: 112,
                              asset: 'assets/images/maphric_dashboard_logo.png',
                              padding: 0,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Fresh shopping,\nmade local.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                signup
                                    ? 'Create your Maphric account.'
                                    : 'Welcome back to Maphric Express.',
                                key: ValueKey(signup),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _AuthBenefit(
                                  icon: Icons.bolt,
                                  label: 'Fast delivery',
                                ),
                                _AuthBenefit(
                                  icon: Icons.eco_outlined,
                                  label: 'Fresh & local',
                                ),
                                _AuthBenefit(
                                  icon: Icons.shield_outlined,
                                  label: 'Secure',
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  label: Text('Sign up'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('Sign in'),
                                ),
                              ],
                              selected: {signup},
                              onSelectionChanged: (value) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  signup = value.first;
                                  error = '';
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween(
                                        begin: const Offset(0, -.06),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: signup
                                  ? Column(
                                      key: const ValueKey('signup-fields'),
                                      children: [
                                        TextField(
                                          controller: name,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            labelText: 'Full name',
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: email,
                                          textInputAction: TextInputAction.next,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: phone,
                                          textInputAction: TextInputAction.next,
                                          keyboardType: TextInputType.phone,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone number',
                                            prefixIcon: Icon(
                                              Icons.phone_outlined,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : TextField(
                                      key: const ValueKey('signin-field'),
                                      controller: username,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Username or email',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: password,
                              obscureText: obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => obscure = !obscure),
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                            ),
                            if (error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: green,
                                padding: const EdgeInsets.all(17),
                              ),
                              onPressed: busy ? null : submit,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: busy
                                    ? const SizedBox.square(
                                        key: ValueKey('busy'),
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        key: const ValueKey('ready'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            signup
                                                ? Icons.person_add_alt_1
                                                : Icons.login,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            signup
                                                ? 'Create account'
                                                : 'Sign in',
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
            ),
          ],
        );
      },
    ),
  );
}

class _DesktopAuthHero extends StatelessWidget {
  const _DesktopAuthHero();

  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(-36 * (1 - value), 0),
        child: Opacity(opacity: value, child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'BRADFIELD · BULAWAYO',
              style: TextStyle(
                color: deepGreen,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your local shop,\nnow in your pocket.',
            style: TextStyle(
              color: deepGreen,
              fontSize: 52,
              height: .98,
              letterSpacing: -1.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Fresh groceries, secure checkout, live order tracking,\nand friendly local delivery across Bulawayo.',
            style: TextStyle(
              color: Color(0xFF49635A),
              fontSize: 17,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 30),
          const _HeroFeature(
            icon: Icons.shopping_basket_outlined,
            title: 'Shop smarter',
            subtitle: 'Favourites, shopping lists and an AI assistant.',
          ),
          const _HeroFeature(
            icon: Icons.payments_outlined,
            title: 'Pay your way',
            subtitle: 'Secure checkout with local payment options.',
          ),
          const _HeroFeature(
            icon: Icons.local_shipping_outlined,
            title: 'Follow every order',
            subtitle: 'From checkout to delivery at your door.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final label in ['FRESH', 'LOCAL', 'FAST'])
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .70),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: green.withValues(alpha: .12)),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: green,
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: .20),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: deepGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AuthBenefit extends StatelessWidget {
  const _AuthBenefit({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: green.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: green),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _AuthBackground extends StatefulWidget {
  const _AuthBackground();

  @override
  State<_AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<_AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F2E8), cream, Color(0xFFFFF0C7)],
        ),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final drift = controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -90 + (drift * 28),
                top: -70 + (drift * 18),
                child: _GlowOrb(size: 250, color: green.withValues(alpha: .16)),
              ),
              Positioned(
                right: -80 + (drift * 20),
                bottom: -100 + (drift * 30),
                child: _GlowOrb(size: 280, color: gold.withValues(alpha: .25)),
              ),
              Positioned(
                right: 40 + (drift * 18),
                top: 80 - (drift * 18),
                child: Transform.rotate(
                  angle: drift * .18,
                  child: Icon(
                    Icons.eco,
                    size: 74,
                    color: green.withValues(alpha: .10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class MobileHome extends StatefulWidget {
  const MobileHome({
    super.key,
    required this.api,
    required this.user,
    required this.logout,
  });
  final ApiService api;
  final Map<String, dynamic> user;
  final VoidCallback logout;
  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int index = 0;
  bool sidebarOpen = false;
  final cart = <int, int>{};
  final wishlist = <int, int>{};
  List<Product> products = [];
  List<CustomerOrder> orders = [];
  DeliverySettings delivery = DeliverySettings.fallback;
  bool loading = true;
  String error = '';

  void toggleNavigation() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => sidebarOpen = !sidebarOpen);
  }

  void selectPage(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      index = value;
      sidebarOpen = false;
    });
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final values = await Future.wait([
        widget.api.products(),
        widget.api.orders(),
        widget.api.cart(),
        widget.api.wishlist(),
        widget.api.deliverySettings(),
      ]);
      if (!mounted) return;
      products = values[0] as List<Product>;
      orders = values[1] as List<CustomerOrder>;
      cart
        ..clear()
        ..addAll(values[2] as Map<int, int>);
      wishlist
        ..clear()
        ..addAll(values[3] as Map<int, int>);
      delivery = values[4] as DeliverySettings;
    } catch (e) {
      if (mounted) error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add(Product product) async {
    try {
      await widget.api.addToCart(product.id);
      if (!mounted) return;
      setState(() => cart[product.id] = (cart[product.id] ?? 0) + 1);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> changeCartQuantity(Product product, int quantity) async {
    final previous = cart[product.id] ?? 0;
    final next = quantity.clamp(0, product.stock);
    setState(() {
      if (next == 0) {
        cart.remove(product.id);
      } else {
        cart[product.id] = next;
      }
    });
    try {
      await widget.api.setCartQuantity(product.id, next);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (previous == 0) {
          cart.remove(product.id);
        } else {
          cart[product.id] = previous;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> toggleWishlist(Product product) async {
    final existing = wishlist[product.id];
    setState(() {
      if (existing == null) {
        wishlist[product.id] = -1;
      } else {
        wishlist.remove(product.id);
      }
    });
    try {
      if (existing == null) {
        await widget.api.addWishlist(product.id);
      } else if (existing > 0) {
        await widget.api.removeWishlist(existing);
      }
      final saved = await widget.api.wishlist();
      if (mounted) {
        setState(() {
          wishlist
            ..clear()
            ..addAll(saved);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (existing == null) {
          wishlist.remove(product.id);
        } else {
          wishlist[product.id] = existing;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StorePage(
        products: products,
        loading: loading,
        error: error,
        add: add,
        wishlist: wishlist.keys.toSet(),
        toggleWishlist: toggleWishlist,
        refresh: refresh,
      ),
      CartPage(
        api: widget.api,
        user: widget.user,
        products: products,
        cart: cart,
        changeQuantity: changeCartQuantity,
        delivery: delivery,
        onOrdered: (order) {
          setState(() {
            orders.insert(0, order);
            cart.clear();
            index = 2;
          });
          refresh();
        },
      ),
      OrdersPage(api: widget.api, orders: orders),
      ProfilePage(user: widget.user, logout: widget.logout),
      AssistantPage(api: widget.api, openCart: () => setState(() => index = 1)),
      FavoritesPage(
        products: products
            .where((product) => wishlist.containsKey(product.id))
            .toList(),
        add: add,
        remove: toggleWishlist,
      ),
      LocationPage(delivery: delivery),
      const ShoppingListPage(),
    ];
    final cartCount = cart.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final header = Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          color: deepGreen,
          child: Row(
            children: [
              Tooltip(
                message: 'Open or close navigation',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: toggleNavigation,
                  child: Container(
                    width: 180,
                    height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E4DE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/maphric_dashboard_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (cartCount > 0)
                Badge(
                  label: Text('$cartCount'),
                  child: IconButton(
                    color: Colors.white,
                    tooltip: 'Cart',
                    onPressed: () => setState(() => index = 1),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ),
              IconButton(
                color: Colors.white,
                tooltip: 'Refresh',
                onPressed: refresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                color: Colors.white,
                tooltip: 'Sign out',
                onPressed: widget.logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        );
        return Scaffold(
          key: scaffoldKey,
          body: Column(
            children: [
              header,
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IndexedStack(index: index, children: pages),
                    ),
                    if (sidebarOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: toggleNavigation,
                          child: Container(color: Colors.black38),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      left: sidebarOpen ? 0 : -250,
                      top: 0,
                      bottom: 0,
                      width: 250,
                      child: Material(
                        elevation: 18,
                        child: _CustomerNav(
                          index: index,
                          cartCount: cartCount,
                          logout: widget.logout,
                          select: selectPage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerNav extends StatelessWidget {
  const _CustomerNav({
    required this.index,
    required this.cartCount,
    required this.select,
    required this.logout,
  });

  final int index;
  final int cartCount;
  final ValueChanged<int> select;
  final VoidCallback logout;

  static const destinations = [
    (Icons.storefront_outlined, 'Store'),
    (Icons.shopping_cart_outlined, 'Cart'),
    (Icons.receipt_long_outlined, 'Order history'),
    (Icons.person_outline, 'My profile'),
    (Icons.auto_awesome_outlined, 'Shopping assistant'),
    (Icons.favorite_border, 'Favourites'),
    (Icons.location_on_outlined, 'Shop location'),
    (Icons.checklist_outlined, 'Shopping list'),
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF171B2D),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(12, 30, 12, 16),
      children: [
        const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'CUSTOMER WORKSPACE',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        for (var i = 0; i < destinations.length; i++)
          ListTile(
            selected: index == i,
            selectedTileColor: green,
            textColor: Colors.white70,
            selectedColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: i == 1
                ? Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    child: Icon(destinations[i].$1),
                  )
                : Icon(destinations[i].$1),
            title: Text(destinations[i].$2),
            onTap: () => select(i),
          ),
        const Divider(color: Colors.white24),
        ListTile(
          textColor: Colors.white70,
          iconColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: logout,
        ),
      ],
    ),
  );
}

class StorePage extends StatefulWidget {
  const StorePage({
    super.key,
    required this.products,
    required this.loading,
    required this.error,
    required this.add,
    required this.wishlist,
    required this.toggleWishlist,
    required this.refresh,
  });
  final List<Product> products;
  final bool loading;
  final String error;
  final ValueChanged<Product> add;
  final Set<int> wishlist;
  final ValueChanged<Product> toggleWishlist;
  final Future<void> Function() refresh;
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final shown = widget.products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (widget.loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: widget.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 24 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [deepGreen, green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: .18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FRESH FROM BRADFIELD',
                    style: TextStyle(color: gold, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Big value.\nFresh choices.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Groceries delivered across Bulawayo.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search groceries…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (widget.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    widget.error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(
            '${shown.length} groceries',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: green,
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty && widget.error.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text('No groceries match your search.'),
                ],
              ),
            ),
          ...shown.map(
            (product) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => widget.toggleWishlist(product),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE5F0EA),
                    backgroundImage: product.image.isEmpty
                        ? null
                        : NetworkImage(product.image),
                    child: product.image.isEmpty
                        ? Text(product.category.characters.first)
                        : null,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: widget.wishlist.contains(product.id)
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                      onPressed: () => widget.toggleWishlist(product),
                      icon: Icon(
                        widget.wishlist.contains(product.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.wishlist.contains(product.id)
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${product.category} · ${product.stock > 0 ? '${product.stock} in stock' : 'Out of stock'}',
                ),
                trailing: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 28,
                        width: 72,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: product.stock > 0
                              ? () => widget.add(product)
                              : null,
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.api,
    required this.user,
    required this.products,
    required this.cart,
    required this.changeQuantity,
    required this.delivery,
    required this.onOrdered,
  });
  final ApiService api;
  final Map<String, dynamic> user;
  final List<Product> products;
  final Map<int, int> cart;
  final Future<void> Function(Product product, int quantity) changeQuantity;
  final DeliverySettings delivery;
  final ValueChanged<CustomerOrder> onOrdered;
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController();
  bool busy = false;
  String error = '';
  String payment = 'EcoCash';
  final updating = <int>{};

  @override
  void initState() {
    super.initState();
    final fullName =
        '${widget.user['first_name'] ?? ''} ${widget.user['last_name'] ?? ''}'
            .trim();
    name.text = fullName;
    phone.text = (widget.user['phone_number'] ?? '').toString();
    address.text = (widget.user['address'] ?? '').toString();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> change(Product product, int quantity) async {
    if (updating.contains(product.id)) return;
    setState(() => updating.add(product.id));
    await widget.changeQuantity(product, quantity);
    if (mounted) setState(() => updating.remove(product.id));
  }

  @override
  Widget build(BuildContext context) {
    final productsById = {
      for (final product in widget.products) product.id: product,
    };
    final rows = widget.cart.entries
        .where((row) => productsById.containsKey(row.key))
        .toList();
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + productsById[row.key]!.price * row.value,
    );
    final deliveryCharge = total > 0 && total < widget.delivery.freeThreshold
        ? widget.delivery.fee
        : 0.0;
    final checkoutTotal = total + deliveryCharge;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Expanded(child: _CheckoutStep(label: '1 Cart', active: true)),
            Expanded(child: _CheckoutStep(label: '2 Delivery')),
            Expanded(child: _CheckoutStep(label: '3 Payment')),
            Expanded(child: _CheckoutStep(label: '4 Receipt')),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Your cart',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: green,
          ),
        ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 70,
                  color: Colors.black26,
                ),
                SizedBox(height: 12),
                Text('Your basket is empty'),
              ],
            ),
          ),
        ...rows.map((row) {
          final p = productsById[row.key]!;
          return Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text('${row.value} × \$${p.price.toStringAsFixed(2)}'),
              trailing: SizedBox(
                width: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: row.value == 1 ? 'Remove' : 'Decrease quantity',
                      onPressed: updating.contains(p.id)
                          ? null
                          : () => change(p, row.value - 1),
                      icon: Icon(
                        row.value == 1
                            ? Icons.delete_outline
                            : Icons.remove_circle_outline,
                      ),
                    ),
                    Text(
                      '${row.value}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity',
                      onPressed: row.value < p.stock
                          ? updating.contains(p.id)
                                ? null
                                : () => change(p, row.value + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    Expanded(
                      child: Text(
                        '\$${(p.price * row.value).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Items: \$${total.toStringAsFixed(2)}\n'
            'Delivery: ${deliveryCharge == 0 ? 'FREE' : '\$${deliveryCharge.toStringAsFixed(2)}'}\n'
            'Order total: \$${checkoutTotal.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Delivery name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Delivery address'),
          ),
          const SizedBox(height: 14),
          Text(
            widget.delivery.policy,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Areas: ${widget.delivery.areas} · About ${widget.delivery.estimatedMinutes} minutes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          const Text(
            'Payment method',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['EcoCash', 'InnBucks', 'ePay', 'Bank card']
                .map(
                  (method) => ChoiceChip(
                    label: Text(method),
                    selected: payment == method,
                    onSelected: (_) => setState(() => payment = method),
                  ),
                )
                .toList(),
          ),
          if (payment != 'EcoCash')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Provider processing will activate when merchant credentials are connected.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: green,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: busy
                ? null
                : () async {
                    if (name.text.trim().isEmpty ||
                        phone.text.trim().isEmpty ||
                        address.text.trim().isEmpty) {
                      setState(() => error = 'Complete the delivery details.');
                      return;
                    }
                    setState(() {
                      busy = true;
                      error = '';
                    });
                    try {
                      final order = await widget.api.checkout(
                        name: name.text,
                        phone: phone.text,
                        address: address.text,
                      );
                      if (!mounted) return;
                      String? paymentNotice;
                      if (payment == 'EcoCash') {
                        try {
                          await widget.api.initiateEcoCash(
                            order.id,
                            phone.text,
                          );
                          paymentNotice =
                              'Approve the EcoCash prompt on your phone.';
                        } catch (e) {
                          paymentNotice =
                              'Your order was created, but EcoCash could not start: $e';
                        }
                      }
                      if (!context.mounted) return;
                      FocusManager.instance.primaryFocus?.unfocus();
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => AlertDialog(
                          icon: const Icon(
                            Icons.check_circle,
                            color: green,
                            size: 52,
                          ),
                          title: const Text('Order confirmed'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                order.number,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: \$${order.total.toStringAsFixed(2)}',
                              ),
                              Text('Payment: $payment'),
                              if (paymentNotice != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    paymentNotice,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('View orders'),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      widget.onOrdered(order);
                    } catch (e) {
                      if (mounted) setState(() => error = e.toString());
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(
              busy
                  ? 'Confirming order...'
                  : 'Pay \$${checkoutTotal.toStringAsFixed(2)} & place order',
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckoutStep extends StatelessWidget {
  const _CheckoutStep({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: active ? green : Colors.black12,
          width: active ? 3 : 1,
        ),
      ),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: active ? green : Colors.black45,
        fontWeight: active ? FontWeight.w900 : FontWeight.w500,
        fontSize: 11,
      ),
    ),
  );
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, required this.api, required this.orders});
  final ApiService api;
  final List<CustomerOrder> orders;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Orders & tracking',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: green,
        ),
      ),
      const SizedBox(height: 14),
      if (orders.isEmpty) const Text('Completed orders will appear here.'),
      ...orders.map(
        (order) => Card(
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: green,
              child: Icon(Icons.local_shipping_outlined, color: Colors.white),
            ),
            title: Text(
              order.number,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${order.status.toUpperCase()} · ${order.paymentStatus.toUpperCase()}',
            ),
            trailing: Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            children: [
              _TrackingProgress(status: order.status),
              const SizedBox(height: 12),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.productName} × ${item.quantity}'),
                      ),
                      Text(
                        '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              if (order.shippingAddress.isNotEmpty) ...[
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Deliver to: ${order.shippingAddress}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              if (order.paymentMethod == 'EcoCash' &&
                  order.paymentStatus != 'paid')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final paid = await api.paymentPaid(order.id);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              paid
                                  ? 'Payment confirmed.'
                                  : 'Payment is still pending.',
                            ),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check payment'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TrackingProgress extends StatelessWidget {
  const _TrackingProgress({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    const stages = ['pending', 'paid', 'processing', 'shipped', 'delivered'];
    final current = stages.indexOf(status.toLowerCase());
    final reached = current < 0 ? 0 : current;
    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Icon(
                  i <= reached
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= reached ? green : Colors.black26,
                ),
                Text(
                  stages[i],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          if (i < stages.length - 1)
            Container(width: 8, height: 2, color: Colors.black12),
        ],
      ],
    );
  }
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key, required this.api, required this.openCart});
  final ApiService api;
  final VoidCallback openCart;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[
    {
      'role': 'assistant',
      'content':
          'Hello! Ask me about products, prices, delivery, budgets, or your latest order.',
    },
  ];
  bool busy = false;
  String error = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final message = controller.text.trim();
    if (message.isEmpty || busy) return;
    setState(() {
      messages.add({'role': 'user', 'content': message});
      controller.clear();
      busy = true;
      error = '';
    });
    try {
      final answer = await widget.api.askAssistant(message, messages);
      if (mounted) {
        setState(() => messages.add({'role': 'assistant', 'content': answer}));
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Shopping assistant',
                style: TextStyle(
                  color: green,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Open cart',
              onPressed: widget.openCart,
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final mine = message['role'] == 'user';
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mine ? green : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message['content'] ?? '',
                  style: TextStyle(color: mine ? Colors.white : Colors.black87),
                ),
              ),
            );
          },
        ),
      ),
      if (error.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => send(),
                  decoration: const InputDecoration(
                    hintText: 'Ask about your shopping...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send',
                onPressed: busy ? null : send,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.products,
    required this.add,
    required this.remove,
  });
  final List<Product> products;
  final ValueChanged<Product> add;
  final ValueChanged<Product> remove;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Favourites',
        style: TextStyle(
          color: green,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 12),
      if (products.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 70),
          child: Column(
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.black26),
              SizedBox(height: 12),
              Text('Tap a heart in the store to save a favourite.'),
            ],
          ),
        ),
      ...products.map(
        (product) => Card(
          child: ListTile(
            leading: product.image.isEmpty
                ? const Icon(Icons.local_grocery_store)
                : CircleAvatar(backgroundImage: NetworkImage(product.image)),
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Remove favourite',
                  onPressed: () => remove(product),
                  icon: const Icon(Icons.favorite, color: Colors.red),
                ),
                IconButton.filled(
                  tooltip: 'Add to cart',
                  onPressed: product.stock > 0 ? () => add(product) : null,
                  icon: const Icon(Icons.add_shopping_cart),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  static const storageKey = 'maphric_shopping_list';
  final controller = TextEditingController();
  final items = <String>[];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (!mounted) return;
      setState(() => items.addAll(preferences.getStringList(storageKey) ?? []));
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(storageKey, items);
  }

  void addItem() {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      items.add(value);
      controller.clear();
    });
    save();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Shopping list',
        style: TextStyle(
          color: green,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => addItem(),
              decoration: const InputDecoration(
                hintText: 'Add milk, bread, vegetables...',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Add item',
            onPressed: addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.checklist, size: 64, color: Colors.black26),
              SizedBox(height: 10),
              Text('Your personal shopping list is empty.'),
            ],
          ),
        ),
      for (var index = 0; index < items.length; index++)
        Card(
          child: CheckboxListTile(
            value: false,
            onChanged: (_) {
              setState(() => items.removeAt(index));
              save();
            },
            title: Text(items[index]),
            secondary: IconButton(
              tooltip: 'Remove',
              onPressed: () {
                setState(() => items.removeAt(index));
                save();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
    ],
  );
}

class LocationPage extends StatelessWidget {
  const LocationPage({super.key, required this.delivery});
  final DeliverySettings delivery;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Visit & support',
        style: TextStyle(
          color: green,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 16),
      Container(
        height: 210,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [deepGreen, green]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: gold, size: 64),
            SizedBox(height: 10),
            Text(
              '1 St Andrews Road, Bradfield\nBulawayo, Zimbabwe',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Card(
        child: ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Opening hours'),
          subtitle: Text(
            delivery.openingHours.isEmpty
                ? 'Contact the store for today’s hours.'
                : delivery.openingHours,
          ),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.local_shipping_outlined),
          title: const Text('Delivery'),
          subtitle: Text(
            '${delivery.policy}\nAreas: ${delivery.areas}\nEstimated ${delivery.estimatedMinutes} minutes',
          ),
        ),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.support_agent),
          title: Text('WhatsApp or call'),
          subtitle: SelectableText('+263 77 291 0496'),
        ),
      ),
    ],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.logout});
  final Map<String, dynamic> user;
  final VoidCallback logout;
  @override
  Widget build(BuildContext context) {
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundColor: green,
          child: Icon(Icons.person, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          fullName.isEmpty
              ? (user['username'] ?? 'Maphric customer')
              : fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(user['email'] ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        const Card(
          child: ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Secure account'),
            subtitle: Text('Connected to your Maphric customer profile'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('WhatsApp support'),
            subtitle: Text('+263 77 291 0496'),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
