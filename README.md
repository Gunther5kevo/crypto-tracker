# Crypto UI Kit - Flutter

A modern, production-ready cryptocurrency tracking UI kit built with Flutter. Features beautiful animations, dark/light themes, and clean architecture.

## Features

✅ **3 Complete Screens** - Home, Watchlist, Settings  
✅ **Dark & Light Themes** - Smooth theme switching  
✅ **Animated Transitions** - Hero animations, swipe gestures  
✅ **Interactive Charts** - Custom sparkline widgets  
✅ **Star/Watchlist System** - Add favorites with animations  
✅ **Swipe to Remove** - Dismissible watchlist items  
✅ **Clean Architecture** - Organized, reusable code  

## Installation

1. **Clone or download** this project
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

## Requirements

- Flutter 3.0 or higher
- Dart 3.0 or higher

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── services/
│   └── theme_service.dart       # Theme management
├── screens/
│   ├── main_navigation.dart     # Bottom navigation
│   ├── home_screen.dart         # Home screen
│   ├── watchlist_screen.dart    # Watchlist screen
│   └── settings_screen.dart     # Settings screen
├── data/
│   ├── coin_model.dart          # Coin data model
│   └── coin_provider.dart       # State management
└── widgets/
    ├── coin_item.dart           # Coin list item
    ├── portfolio_card.dart      # Portfolio summary card
    ├── stat_card.dart           # Stat display card
    ├── section_header.dart      # Section headers
    └── sparkline_chart.dart     # Mini chart widget
```

## Customization

### Change Colors

Edit `lib/services/theme_service.dart`:

```dart
static ThemeData get lightTheme => ThemeData(
  scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Your color
  // ... customize more
);
```

### Add Real API Data

Replace dummy data in `lib/data/coin_provider.dart`:

```dart
// Replace this:
final List<Coin> _coins = [ /* dummy data */ ];

// With API call:
Future<void> fetchCoins() async {
  final response = await http.get('your-api-url');
  // Parse and update _coins
  notifyListeners();
}
```

### Change Icons

Icons are in each screen file. Example from `home_screen.dart`:

```dart
Icon(Icons.notifications_outlined) // Change to any Material icon
```

### Extend Charts

Edit `lib/widgets/sparkline_chart.dart` to add:
- Gradient fills
- Interactive tooltips
- Multiple lines
- Grid lines

## Add New Screens

1. Create new file in `lib/screens/`
2. Add navigation in `main_navigation.dart`:

```dart
final List<Widget> _screens = const [
  HomeScreen(),
  WatchlistScreen(),
  YourNewScreen(), 
  SettingsScreen(),
];
```

## Dummy Data

Located in `lib/data/coin_provider.dart`. Contains:
- 4 sample coins
- Price data
- Sparkline charts
- Star/favorite status

## License

**Commercial License Included** ✅

You can use this UI kit in:
- Personal projects
- Commercial apps
- Client work
- Products you sell

## Support

For questions or issues, contact: kipyegokevin82@gmail.com





---

**Built with Flutter** 💙 | **Ready for iOS, Android & Web** 📱