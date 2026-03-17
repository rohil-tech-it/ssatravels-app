// lib/utils/location_helper.dart
class LocationHelper {
  // Tamil Nadu major cities and towns
  static const List<String> tamilNaduCities = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tirunelveli',
    'Trichy',
    'Salem',
    'Erode',
    'Tiruppur',
    'Vellore',
    'Virudhunagar',
    'Kanyakumari',
    'Nagercoil',
    'Thoothukudi',
    'Dindigul',
    'Thanjavur',
    'Krishnagiri',
    'Dharmapuri',
    'Namakkal',
    'Kanchipuram',
    'Chengalpattu',
    'Cuddalore',
    'Villupuram',
    'Kallakurichi',
    'Ariyalur',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Sivagangai',
    'Theni',
    'Tenkasi',
    'Tirupathur',
    'Ranipet',
    'Walajapet',
    'Ambur',
    'Vaniyambadi',
    'Gudiyatham',
    'Katpadi',
    'Hosur',
    'Pollachi',
    'Palani',
    'Kodaikanal',
    'Ooty',
    'Coonoor',
    'Mettupalayam',
    'Gobichettipalayam',
    'Bhavani',
    'Perundurai',
    'Sankagiri',
    'Attur',
    'Mettur',
    'Omalur',
    'Sivakasi',
    'Rajapalayam',
    'Satur',
    'Kovilpatti',
    'Tiruchendur',
    'Karaikudi',
    'Kumbakonam',
    'Mayiladuthurai',
    'Nagapattinam',
    'Thiruvarur',
    'Pondicherry',
    'Bengaluru',
    'Palakkad',
  ];

  // Filter cities based on search query
  static List<String> searchCities(String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return tamilNaduCities.where((city) {
      return city.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get popular routes for quick selection
  static List<Map<String, String>> getPopularRoutes() {
    return [
      {'from': 'Chennai', 'to': 'Madurai'},
      {'from': 'Chennai', 'to': 'Coimbatore'},
      {'from': 'Chennai', 'to': 'Tirunelveli'},
      {'from': 'Coimbatore', 'to': 'Madurai'},
      {'from': 'Madurai', 'to': 'Tirunelveli'},
      {'from': 'Virudhunagar', 'to': 'Madurai'},
      {'from': 'Tirunelveli', 'to': 'Coimbatore'},
      {'from': 'Salem', 'to': 'Coimbatore'},
      {'from': 'Trichy', 'to': 'Madurai'},
      {'from': 'Vellore', 'to': 'Chennai'},
    ];
  }
}
