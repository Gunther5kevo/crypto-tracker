# Crypto UI Kit - Flutter

A modern, production-ready cryptocurrency tracking UI kit built with Flutter. Features live API data, beautiful animations, dark/light themes, and clean architecture.

## Features

✅ **4 Complete Screens** - Home, Portfolio, Watchlist, Settings  
✅ **Live Market Data** - Real-time prices from CoinGecko API  
✅ **Portfolio Tracking** - Add holdings with profit/loss calculations  
✅ **Dark & Light Themes** - Smooth theme switching with service  
✅ **Animated Transitions** - Hero animations, swipe gestures  
✅ **Interactive Charts** - Live 7-day sparkline charts  
✅ **Star/Watchlist System** - Add favorites with animations  
✅ **Swipe to Remove** - Dismissible watchlist items  
✅ **Pull to Refresh** - Update market data anytime  
✅ **Clean Architecture** - Organized, maintainable code  

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
- Internet connection for live API data

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # For API calls
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── services/
│   └── theme_service.dart       # Theme management service
├── screens/
│   ├── main_navigation.dart     # Bottom navigation
│   ├── home_screen.dart         # Home screen with live prices
│   ├── portfolio_screen.dart    # Portfolio tracking
│   ├── watchlist_screen.dart    # Starred coins watchlist
│   └── settings_screen.dart     # Theme & settings
├── data/
│   ├── coin_model.dart          # Coin data model
│   ├── coin_provider.dart       # Live API integration
│   └── portfolio_provider.dart  # Portfolio state management
└── widgets/
    ├── coin_item.dart           # Coin list item with star
    ├── portfolio_card.dart      # Portfolio summary card
    ├── stat_card.dart           # Stat display card
    ├── section_header.dart      # Section headers
    └── sparkline_chart.dart     # Custom sparkline chart
```

## Live API Integration

The app uses **CoinGecko API** (free, no key required) to fetch:
- ✅ Live cryptocurrency prices (USD)
- ✅ 24-hour price changes
- ✅ 7-day sparkline chart data
- ✅ Top 10 coins by market cap

**Auto-refresh options:**
- Pull down to refresh on any screen
- Tap refresh icon in app bar
- Auto-loads on app start

## Screens Overview

### 🏠 Home Screen
- Live trending coins with prices
- Portfolio summary card
- 24h volume and market cap stats
- Star coins to add to watchlist
- Pull to refresh

### 💼 Portfolio Screen
- Total balance tracker
- Profit/Loss calculations
- Add holdings with current market price
- Visual profit indicators (green/red)
- Beautiful gradient card design

### 👁️ Watchlist Screen
- All starred coins in one place
- Swipe left to remove
- Empty state with helpful message
- Live price updates

### ⚙️ Settings Screen
- Dark/Light theme toggle
- Currency selector (USD/EUR)
- About section
- Clean grouped settings

## Customization

### Change Colors

Edit `lib/services/theme_service.dart`:

```dart
static ThemeData get lightTheme => ThemeData(
  scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Your color
  cardColor: Colors.white,
  // ... customize more
);

static ThemeData get darkTheme => ThemeData(
  scaffoldBackgroundColor: const Color(0xFF0F1419), // Your color
  cardColor: const Color(0xFF1A1F26),
  // ... customize more
);
```

### Use Different API

Replace the API in `lib/data/coin_provider.dart`:

```dart
Future<void> fetchCoins() async {
  final response = await http.get(Uri.parse(
    'YOUR_API_URL_HERE'
  ));
  // Parse and update _coins
  notifyListeners();
}
```

**Popular alternatives:**
- Binance API
- CoinCap API
- CryptoCompare API

### Change Icons

Icons use Material Icons. Example from `home_screen.dart`:

```dart
Icon(Icons.refresh) // Change to any Material icon
Icon(Icons.trending_up)
Icon(Icons.account_balance_wallet)
```

### Extend Charts

Edit `lib/widgets/sparkline_chart.dart` to add:
- Gradient fills under line
- Interactive tooltips
- Multiple data lines
- Grid background
- Y-axis labels

## Add New Screens

1. Create new file in `lib/screens/your_new_screen.dart`
2. Add navigation in `main_navigation.dart`:

```dart
final List<Widget> _screens = const [
  HomeScreen(),
  PortfolioScreen(),
  WatchlistScreen(),
  YourNewScreen(), // Add here
  SettingsScreen(),
];

// Add navigation destination
NavigationDestination(
  icon: Icon(Icons.your_icon),
  label: 'Your Label',
),
```

## Known Limitations

- Portfolio profit calculation uses mock 5% gain for demo
- Watchlist doesn't persist after app restart (uses in-memory storage)
- API is rate-limited (consider caching for production use)

## Future Enhancements

Ideas to extend this UI kit:
- [ ] Persistent storage (SharedPreferences/Hive)
- [ ] Real-time WebSocket price updates
- [ ] Price alerts and notifications
- [ ] Multiple currency support
- [ ] Detailed coin info screen
- [ ] Search functionality
- [ ] Transaction history
- [ ] Export portfolio as PDF

## License

**Commercial License Included** ✅

You can use this UI kit in:
- Personal projects
- Commercial apps
- Client work
- Products you sell
- SaaS applications

## Support

For questions or issues:
- Email: kipyegokevin82@gmail.com
- Report issues in your project repository

## Credits

- **API**: CoinGecko (https://www.coingecko.com)
- **Framework**: Flutter by Google
- **Design**: Modern Material 3 Design

---

**Built with Flutter** 💙 | **Live API Data** 📈 | **Ready for iOS, Android & Web** 📱