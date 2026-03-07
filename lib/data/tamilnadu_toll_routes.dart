// lib/data/tamilnadu_toll_routes.dart
class TamilNaduTollRoutes {
  // Get all default toll routes in Tamil Nadu
  static List<Map<String, dynamic>> getAllTollRoutes() {
    return [
      // ==================== CHENNAI TO ALL MAJOR CITIES ====================
      {
        'id': 'chennai_madurai',
        'source': 'Chennai',
        'destination': 'Madurai',
        'distance': 460,
        'baseToll': 580,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 635,
        'isActive': true,
      },
      {
        'id': 'chennai_coimbatore',
        'source': 'Chennai',
        'destination': 'Coimbatore',
        'distance': 510,
        'baseToll': 650,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'salem_toll',
          'erode_toll',
          'coimbatore_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Coimbatore Toll', 'amount': 105},
        ],
        'totalTollAmount': 660,
        'isActive': true,
      },
      {
        'id': 'chennai_tirunelveli',
        'source': 'Chennai',
        'destination': 'Tirunelveli',
        'distance': 610,
        'baseToll': 780,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 805,
        'isActive': true,
      },
      {
        'id': 'chennai_kanyakumari',
        'source': 'Chennai',
        'destination': 'Kanyakumari',
        'distance': 720,
        'baseToll': 920,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll',
          'kanyakumari_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Kanyakumari Toll', 'amount': 75},
        ],
        'totalTollAmount': 880,
        'isActive': true,
      },
      {
        'id': 'chennai_pondicherry',
        'source': 'Chennai',
        'destination': 'Pondicherry',
        'distance': 170,
        'baseToll': 220,
        'tollPlazaIds': [
          'chengalpattu_toll',
          'tindivanam_toll',
          'pondicherry_toll'
        ],
        'tollDetails': [
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Pondicherry Toll', 'amount': 55},
        ],
        'totalTollAmount': 240,
        'isActive': true,
      },
      {
        'id': 'chennai_bengaluru',
        'source': 'Chennai',
        'destination': 'Bengaluru',
        'distance': 350,
        'baseToll': 450,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'shoolagiri_toll',
          'hosur_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Shoolagiri Toll', 'amount': 90},
          {'name': 'Hosur Toll', 'amount': 60},
        ],
        'totalTollAmount': 510,
        'isActive': true,
      },
      {
        'id': 'chennai_salem',
        'source': 'Chennai',
        'destination': 'Salem',
        'distance': 350,
        'baseToll': 450,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 460,
        'isActive': true,
      },
      {
        'id': 'chennai_trichy',
        'source': 'Chennai',
        'destination': 'Trichy',
        'distance': 330,
        'baseToll': 420,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 435,
        'isActive': true,
      },
      {
        'id': 'chennai_vellore',
        'source': 'Chennai',
        'destination': 'Vellore',
        'distance': 140,
        'baseToll': 190,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'pallikonda_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Pallikonda Toll', 'amount': 80},
        ],
        'totalTollAmount': 235,
        'isActive': true,
      },
      {
        'id': 'chennai_kanchipuram',
        'source': 'Chennai',
        'destination': 'Kanchipuram',
        'distance': 75,
        'baseToll': 100,
        'tollPlazaIds': ['sriperumbudur_toll'],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
        ],
        'totalTollAmount': 60,
        'isActive': true,
      },
      {
        'id': 'chennai_tiruvallur',
        'source': 'Chennai',
        'destination': 'Tiruvallur',
        'distance': 45,
        'baseToll': 60,
        'tollPlazaIds': ['nallur_toll'],
        'tollDetails': [
          {'name': 'Nallur Toll', 'amount': 55},
        ],
        'totalTollAmount': 55,
        'isActive': true,
      },
      {
        'id': 'chennai_cuddalore',
        'source': 'Chennai',
        'destination': 'Cuddalore',
        'distance': 200,
        'baseToll': 250,
        'tollPlazaIds': [
          'chengalpattu_toll',
          'tindivanam_toll',
          'pondicherry_toll'
        ],
        'tollDetails': [
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Pondicherry Toll', 'amount': 55},
        ],
        'totalTollAmount': 240,
        'isActive': true,
      },
      {
        'id': 'chennai_thanjavur',
        'source': 'Chennai',
        'destination': 'Thanjavur',
        'distance': 380,
        'baseToll': 480,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 435,
        'isActive': true,
      },

      // ==================== CHENNAI TO ALL OTHER DISTRICTS ====================
      {
        'id': 'chennai_erode',
        'source': 'Chennai',
        'destination': 'Erode',
        'distance': 400,
        'baseToll': 520,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'salem_toll',
          'erode_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Erode Toll', 'amount': 95},
        ],
        'totalTollAmount': 555,
        'isActive': true,
      },
      {
        'id': 'chennai_tiruppur',
        'source': 'Chennai',
        'destination': 'Tiruppur',
        'distance': 450,
        'baseToll': 580,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'salem_toll',
          'erode_toll',
          'avinashi_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Avinashi Toll', 'amount': 60},
        ],
        'totalTollAmount': 615,
        'isActive': true,
      },
      {
        'id': 'chennai_dindigul',
        'source': 'Chennai',
        'destination': 'Dindigul',
        'distance': 420,
        'baseToll': 540,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
        ],
        'totalTollAmount': 525,
        'isActive': true,
      },
      {
        'id': 'chennai_virudhunagar',
        'source': 'Chennai',
        'destination': 'Virudhunagar',
        'distance': 520,
        'baseToll': 660,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 720,
        'isActive': true,
      },
      {
        'id': 'chennai_thoothukudi',
        'source': 'Chennai',
        'destination': 'Thoothukudi',
        'distance': 620,
        'baseToll': 790,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll',
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 805,
        'isActive': true,
      },
      {
        'id': 'chennai_krishnagiri',
        'source': 'Chennai',
        'destination': 'Krishnagiri',
        'distance': 260,
        'baseToll': 340,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
        ],
        'totalTollAmount': 360,
        'isActive': true,
      },
      {
        'id': 'chennai_dharmapuri',
        'source': 'Chennai',
        'destination': 'Dharmapuri',
        'distance': 300,
        'baseToll': 390,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'dharmapuri_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Dharmapuri Toll', 'amount': 95},
        ],
        'totalTollAmount': 455,
        'isActive': true,
      },
      {
        'id': 'chennai_namakkal',
        'source': 'Chennai',
        'destination': 'Namakkal',
        'distance': 360,
        'baseToll': 470,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'walajapet_toll',
          'ambur_toll',
          'krishnagiri_toll',
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Walajapet Toll', 'amount': 95},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 460,
        'isActive': true,
      },
      {
        'id': 'chennai_kallakurichi',
        'source': 'Chennai',
        'destination': 'Kallakurichi',
        'distance': 240,
        'baseToll': 320,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'kallakurichi_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Kallakurichi Toll', 'amount': 95},
        ],
        'totalTollAmount': 340,
        'isActive': true,
      },
      {
        'id': 'chennai_villupuram',
        'source': 'Chennai',
        'destination': 'Villupuram',
        'distance': 180,
        'baseToll': 240,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
        ],
        'totalTollAmount': 245,
        'isActive': true,
      },
      {
        'id': 'chennai_ariyalur',
        'source': 'Chennai',
        'destination': 'Ariyalur',
        'distance': 300,
        'baseToll': 390,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'perambalur_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Perambalur Toll', 'amount': 80},
        ],
        'totalTollAmount': 325,
        'isActive': true,
      },
      {
        'id': 'chennai_perambalur',
        'source': 'Chennai',
        'destination': 'Perambalur',
        'distance': 280,
        'baseToll': 360,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'perambalur_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Perambalur Toll', 'amount': 80},
        ],
        'totalTollAmount': 325,
        'isActive': true,
      },
      {
        'id': 'chennai_pudukkottai',
        'source': 'Chennai',
        'destination': 'Pudukkottai',
        'distance': 380,
        'baseToll': 490,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 435,
        'isActive': true,
      },
      {
        'id': 'chennai_ramanathapuram',
        'source': 'Chennai',
        'destination': 'Ramanathapuram',
        'distance': 560,
        'baseToll': 710,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 635,
        'isActive': true,
      },
      {
        'id': 'chennai_sivagangai',
        'source': 'Chennai',
        'destination': 'Sivagangai',
        'distance': 480,
        'baseToll': 610,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 635,
        'isActive': true,
      },
      {
        'id': 'chennai_theni',
        'source': 'Chennai',
        'destination': 'Theni',
        'distance': 540,
        'baseToll': 690,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 635,
        'isActive': true,
      },
      {
        'id': 'chennai_tenkasi',
        'source': 'Chennai',
        'destination': 'Tenkasi',
        'distance': 640,
        'baseToll': 810,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 720,
        'isActive': true,
      },
      {
        'id': 'chennai_nagercoil',
        'source': 'Chennai',
        'destination': 'Nagercoil',
        'distance': 700,
        'baseToll': 890,
        'tollPlazaIds': [
          'sriperumbudur_toll',
          'chengalpattu_toll',
          'tindivanam_toll',
          'ulundurpet_toll',
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Ulundurpet Toll', 'amount': 105},
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 875,
        'isActive': true,
      },

      // ==================== COIMBATORE TO ALL MAJOR CITIES ====================
      {
        'id': 'coimbatore_madurai',
        'source': 'Coimbatore',
        'destination': 'Madurai',
        'distance': 220,
        'baseToll': 300,
        'tollPlazaIds': [
          'coimbatore_toll',
          'palladam_toll',
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Palladam Toll', 'amount': 65},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 370,
        'isActive': true,
      },
      {
        'id': 'coimbatore_tirunelveli',
        'source': 'Coimbatore',
        'destination': 'Tirunelveli',
        'distance': 350,
        'baseToll': 450,
        'tollPlazaIds': [
          'coimbatore_toll',
          'palladam_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Palladam Toll', 'amount': 65},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 540,
        'isActive': true,
      },
      {
        'id': 'coimbatore_kanyakumari',
        'source': 'Coimbatore',
        'destination': 'Kanyakumari',
        'distance': 420,
        'baseToll': 540,
        'tollPlazaIds': [
          'coimbatore_toll',
          'palladam_toll',
          'dindigul_toll',
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll',
          'kanyakumari_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Palladam Toll', 'amount': 65},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Kanyakumari Toll', 'amount': 75},
        ],
        'totalTollAmount': 615,
        'isActive': true,
      },
      {
        'id': 'coimbatore_salem',
        'source': 'Coimbatore',
        'destination': 'Salem',
        'distance': 160,
        'baseToll': 220,
        'tollPlazaIds': [
          'coimbatore_toll',
          'erode_toll',
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 300,
        'isActive': true,
      },
      {
        'id': 'coimbatore_erode',
        'source': 'Coimbatore',
        'destination': 'Erode',
        'distance': 100,
        'baseToll': 140,
        'tollPlazaIds': [
          'coimbatore_toll',
          'erode_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Erode Toll', 'amount': 95},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'coimbatore_tiruppur',
        'source': 'Coimbatore',
        'destination': 'Tiruppur',
        'distance': 50,
        'baseToll': 70,
        'tollPlazaIds': [
          'coimbatore_toll',
          'avinashi_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Avinashi Toll', 'amount': 60},
        ],
        'totalTollAmount': 165,
        'isActive': true,
      },
      {
        'id': 'coimbatore_ooty',
        'source': 'Coimbatore',
        'destination': 'Ooty',
        'distance': 85,
        'baseToll': 120,
        'tollPlazaIds': [
          'coimbatore_toll',
          'mettupalayam_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Mettupalayam Toll', 'amount': 70},
        ],
        'totalTollAmount': 175,
        'isActive': true,
      },
      {
        'id': 'coimbatore_pollachi',
        'source': 'Coimbatore',
        'destination': 'Pollachi',
        'distance': 40,
        'baseToll': 60,
        'tollPlazaIds': [
          'coimbatore_toll',
          'pollachi_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Pollachi Toll', 'amount': 80},
        ],
        'totalTollAmount': 185,
        'isActive': true,
      },
      {
        'id': 'coimbatore_palakkad',
        'source': 'Coimbatore',
        'destination': 'Palakkad',
        'distance': 55,
        'baseToll': 75,
        'tollPlazaIds': [
          'coimbatore_toll',
          'walayar_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Walayar Toll', 'amount': 75},
        ],
        'totalTollAmount': 180,
        'isActive': true,
      },
      {
        'id': 'coimbatore_valparai',
        'source': 'Coimbatore',
        'destination': 'Valparai',
        'distance': 100,
        'baseToll': 130,
        'tollPlazaIds': [
          'coimbatore_toll',
          'pollachi_toll'
        ],
        'tollDetails': [
          {'name': 'Coimbatore Toll', 'amount': 105},
          {'name': 'Pollachi Toll', 'amount': 80},
        ],
        'totalTollAmount': 185,
        'isActive': true,
      },

      // ==================== MADURAI TO ALL MAJOR CITIES ====================
      {
        'id': 'madurai_tirunelveli',
        'source': 'Madurai',
        'destination': 'Tirunelveli',
        'distance': 150,
        'baseToll': 380,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll',
          'sattur_toll',
          'kovilpatti_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Sattur Toll', 'amount': 55},
          {'name': 'Kovilpatti Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 420,
        'isActive': true,
      },
      {
        'id': 'madurai_kanyakumari',
        'source': 'Madurai',
        'destination': 'Kanyakumari',
        'distance': 250,
        'baseToll': 320,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll',
          'kanyakumari_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Kanyakumari Toll', 'amount': 75},
        ],
        'totalTollAmount': 355,
        'isActive': true,
      },
      {
        'id': 'madurai_dindigul',
        'source': 'Madurai',
        'destination': 'Dindigul',
        'distance': 65,
        'baseToll': 110,
        'tollPlazaIds': [
          'madurai_toll',
          'dindigul_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Dindigul Toll', 'amount': 90},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'madurai_virudhunagar',
        'source': 'Madurai',
        'destination': 'Virudhunagar',
        'distance': 55,
        'baseToll': 180,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 195,
        'isActive': true,
      },
      {
        'id': 'madurai_theni',
        'source': 'Madurai',
        'destination': 'Theni',
        'distance': 85,
        'baseToll': 150,
        'tollPlazaIds': [
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 110,
        'isActive': true,
      },
      {
        'id': 'madurai_ramanathapuram',
        'source': 'Madurai',
        'destination': 'Ramanathapuram',
        'distance': 130,
        'baseToll': 180,
        'tollPlazaIds': [
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 110,
        'isActive': true,
      },
      {
        'id': 'madurai_sivagangai',
        'source': 'Madurai',
        'destination': 'Sivagangai',
        'distance': 45,
        'baseToll': 70,
        'tollPlazaIds': [
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 110,
        'isActive': true,
      },
      {
        'id': 'madurai_kodaikanal',
        'source': 'Madurai',
        'destination': 'Kodaikanal',
        'distance': 120,
        'baseToll': 180,
        'tollPlazaIds': [
          'madurai_toll',
          'dindigul_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Dindigul Toll', 'amount': 90},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'madurai_sivakasi',
        'source': 'Madurai',
        'destination': 'Sivakasi',
        'distance': 70,
        'baseToll': 140,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 195,
        'isActive': true,
      },
      {
        'id': 'madurai_rajapalayam',
        'source': 'Madurai',
        'destination': 'Rajapalayam',
        'distance': 90,
        'baseToll': 170,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 195,
        'isActive': true,
      },
      {
        'id': 'madurai_thoothukudi',
        'source': 'Madurai',
        'destination': 'Thoothukudi',
        'distance': 160,
        'baseToll': 200,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll',
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 280,
        'isActive': true,
      },
      {
        'id': 'madurai_tenkasi',
        'source': 'Madurai',
        'destination': 'Tenkasi',
        'distance': 180,
        'baseToll': 230,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 280,
        'isActive': true,
      },
      {
        'id': 'madurai_nagercoil',
        'source': 'Madurai',
        'destination': 'Nagercoil',
        'distance': 260,
        'baseToll': 330,
        'tollPlazaIds': [
          'madurai_toll',
          'virudhunagar_toll',
          'tirunelveli_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 350,
        'isActive': true,
      },

      // ==================== TIRUNELVELI TO ALL MAJOR CITIES ====================
      {
        'id': 'tirunelveli_kanyakumari',
        'source': 'Tirunelveli',
        'destination': 'Kanyakumari',
        'distance': 90,
        'baseToll': 150,
        'tollPlazaIds': [
          'tirunelveli_toll',
          'valliyur_toll',
          'kanyakumari_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Valliyur Toll', 'amount': 60},
          {'name': 'Kanyakumari Toll', 'amount': 75},
        ],
        'totalTollAmount': 220,
        'isActive': true,
      },
      {
        'id': 'tirunelveli_thoothukudi',
        'source': 'Tirunelveli',
        'destination': 'Thoothukudi',
        'distance': 55,
        'baseToll': 110,
        'tollPlazaIds': [
          'tirunelveli_toll',
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 170,
        'isActive': true,
      },
      {
        'id': 'tirunelveli_tenkasi',
        'source': 'Tirunelveli',
        'destination': 'Tenkasi',
        'distance': 60,
        'baseToll': 120,
        'tollPlazaIds': [
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'tirunelveli_valliyur',
        'source': 'Tirunelveli',
        'destination': 'Valliyur',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'tirunelveli_toll',
          'valliyur_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Valliyur Toll', 'amount': 60},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'tirunelveli_nagercoil',
        'source': 'Tirunelveli',
        'destination': 'Nagercoil',
        'distance': 70,
        'baseToll': 140,
        'tollPlazaIds': [
          'tirunelveli_toll',
          'valliyur_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
          {'name': 'Valliyur Toll', 'amount': 60},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 215,
        'isActive': true,
      },
      {
        'id': 'tirunelveli_ambasamudram',
        'source': 'Tirunelveli',
        'destination': 'Ambasamudram',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },

      // ==================== VIRUDHUNAGAR DISTRICT ROUTES ====================
      {
        'id': 'virudhunagar_sivakasi',
        'source': 'Virudhunagar',
        'destination': 'Sivakasi',
        'distance': 30,
        'baseToll': 80,
        'tollPlazaIds': [
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'virudhunagar_rajapalayam',
        'source': 'Virudhunagar',
        'destination': 'Rajapalayam',
        'distance': 40,
        'baseToll': 90,
        'tollPlazaIds': [
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'virudhunagar_satur',
        'source': 'Virudhunagar',
        'destination': 'Satur',
        'distance': 25,
        'baseToll': 70,
        'tollPlazaIds': [
          'virudhunagar_toll',
          'sattur_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Sattur Toll', 'amount': 55},
        ],
        'totalTollAmount': 140,
        'isActive': true,
      },
      {
        'id': 'virudhunagar_kovilpatti',
        'source': 'Virudhunagar',
        'destination': 'Kovilpatti',
        'distance': 50,
        'baseToll': 100,
        'tollPlazaIds': [
          'virudhunagar_toll',
          'sattur_toll',
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Sattur Toll', 'amount': 55},
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 225,
        'isActive': true,
      },
      {
        'id': 'virudhunagar_tirunelveli',
        'source': 'Virudhunagar',
        'destination': 'Tirunelveli',
        'distance': 90,
        'baseToll': 240,
        'tollPlazaIds': [
          'virudhunagar_toll',
          'sattur_toll',
          'kovilpatti_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Sattur Toll', 'amount': 55},
          {'name': 'Kovilpatti Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 310,
        'isActive': true,
      },
      {
        'id': 'sivakasi_srivilliputhur',
        'source': 'Sivakasi',
        'destination': 'Srivilliputhur',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'sivakasi_rajapalayam',
        'source': 'Sivakasi',
        'destination': 'Rajapalayam',
        'distance': 35,
        'baseToll': 75,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'sivakasi_virudhunagar',
        'source': 'Sivakasi',
        'destination': 'Virudhunagar',
        'distance': 30,
        'baseToll': 80,
        'tollPlazaIds': [
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'sivakasi_satur',
        'source': 'Sivakasi',
        'destination': 'Satur',
        'distance': 45,
        'baseToll': 95,
        'tollPlazaIds': [
          'virudhunagar_toll',
          'sattur_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
          {'name': 'Sattur Toll', 'amount': 55},
        ],
        'totalTollAmount': 140,
        'isActive': true,
      },
      {
        'id': 'rajapalayam_srivilliputhur',
        'source': 'Rajapalayam',
        'destination': 'Srivilliputhur',
        'distance': 15,
        'baseToll': 40,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'rajapalayam_virudhunagar',
        'source': 'Rajapalayam',
        'destination': 'Virudhunagar',
        'distance': 40,
        'baseToll': 90,
        'tollPlazaIds': [
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'satur_kovilpatti',
        'source': 'Satur',
        'destination': 'Kovilpatti',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'sattur_toll',
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Sattur Toll', 'amount': 55},
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 140,
        'isActive': true,
      },
      {
        'id': 'satur_virudhunagar',
        'source': 'Satur',
        'destination': 'Virudhunagar',
        'distance': 25,
        'baseToll': 70,
        'tollPlazaIds': [
          'sattur_toll',
          'virudhunagar_toll'
        ],
        'tollDetails': [
          {'name': 'Sattur Toll', 'amount': 55},
          {'name': 'Virudhunagar Toll', 'amount': 85},
        ],
        'totalTollAmount': 140,
        'isActive': true,
      },

      // ==================== KANYAKUMARI DISTRICT ROUTES ====================
      {
        'id': 'kanyakumari_nagercoil',
        'source': 'Kanyakumari',
        'destination': 'Nagercoil',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [
          'kanyakumari_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Kanyakumari Toll', 'amount': 75},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'kanyakumari_marthandam',
        'source': 'Kanyakumari',
        'destination': 'Marthandam',
        'distance': 35,
        'baseToll': 75,
        'tollPlazaIds': [
          'kanyakumari_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Kanyakumari Toll', 'amount': 75},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'kanyakumari_thuckalay',
        'source': 'Kanyakumari',
        'destination': 'Thuckalay',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [
          'kanyakumari_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Kanyakumari Toll', 'amount': 75},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'kanyakumari_kuzhithurai',
        'source': 'Kanyakumari',
        'destination': 'Kuzhithurai',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [
          'kanyakumari_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Kanyakumari Toll', 'amount': 75},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'kanyakumari_colachel',
        'source': 'Kanyakumari',
        'destination': 'Colachel',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'kanyakumari_toll',
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Kanyakumari Toll', 'amount': 75},
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'nagercoil_marthandam',
        'source': 'Nagercoil',
        'destination': 'Marthandam',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },
      {
        'id': 'nagercoil_thuckalay',
        'source': 'Nagercoil',
        'destination': 'Thuckalay',
        'distance': 15,
        'baseToll': 40,
        'tollPlazaIds': [
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },
      {
        'id': 'nagercoil_kuzhithurai',
        'source': 'Nagercoil',
        'destination': 'Kuzhithurai',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },
      {
        'id': 'nagercoil_padmanabhapuram',
        'source': 'Nagercoil',
        'destination': 'Padmanabhapuram',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [
          'nagercoil_toll'
        ],
        'tollDetails': [
          {'name': 'Nagercoil Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },

      // ==================== THOOTHUKUDI DISTRICT ROUTES ====================
      {
        'id': 'thoothukudi_tiruchendur',
        'source': 'Thoothukudi',
        'destination': 'Tiruchendur',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'thoothukudi_kovilpatti',
        'source': 'Thoothukudi',
        'destination': 'Kovilpatti',
        'distance': 50,
        'baseToll': 95,
        'tollPlazaIds': [
          'kovilpatti_toll'
        ],
        'tollDetails': [
          {'name': 'Kovilpatti Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'thoothukudi_kayalpattinam',
        'source': 'Thoothukudi',
        'destination': 'Kayalpattinam',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'thoothukudi_tirunelveli',
        'source': 'Thoothukudi',
        'destination': 'Tirunelveli',
        'distance': 55,
        'baseToll': 110,
        'tollPlazaIds': [
          'kovilpatti_toll',
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Kovilpatti Toll', 'amount': 85},
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 170,
        'isActive': true,
      },
      {
        'id': 'thoothukudi_ettayapuram',
        'source': 'Thoothukudi',
        'destination': 'Ettayapuram',
        'distance': 35,
        'baseToll': 75,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'tiruchendur_kayalpattinam',
        'source': 'Tiruchendur',
        'destination': 'Kayalpattinam',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== SALEM DISTRICT ROUTES ====================
      {
        'id': 'salem_erode',
        'source': 'Salem',
        'destination': 'Erode',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [
          'salem_toll',
          'erode_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Erode Toll', 'amount': 95},
        ],
        'totalTollAmount': 195,
        'isActive': true,
      },
      {
        'id': 'salem_coimbatore',
        'source': 'Salem',
        'destination': 'Coimbatore',
        'distance': 160,
        'baseToll': 210,
        'tollPlazaIds': [
          'salem_toll',
          'erode_toll',
          'coimbatore_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Coimbatore Toll', 'amount': 105},
        ],
        'totalTollAmount': 300,
        'isActive': true,
      },
      {
        'id': 'salem_dharmapuri',
        'source': 'Salem',
        'destination': 'Dharmapuri',
        'distance': 65,
        'baseToll': 110,
        'tollPlazaIds': [
          'salem_toll',
          'dharmapuri_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Dharmapuri Toll', 'amount': 95},
        ],
        'totalTollAmount': 195,
        'isActive': true,
      },
      {
        'id': 'salem_krishnagiri',
        'source': 'Salem',
        'destination': 'Krishnagiri',
        'distance': 85,
        'baseToll': 135,
        'tollPlazaIds': [
          'salem_toll',
          'krishnagiri_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
        ],
        'totalTollAmount': 205,
        'isActive': true,
      },
      {
        'id': 'salem_namakkal',
        'source': 'Salem',
        'destination': 'Namakkal',
        'distance': 50,
        'baseToll': 90,
        'tollPlazaIds': [
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 100,
        'isActive': true,
      },
      {
        'id': 'salem_attur',
        'source': 'Salem',
        'destination': 'Attur',
        'distance': 50,
        'baseToll': 95,
        'tollPlazaIds': [
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 100,
        'isActive': true,
      },
      {
        'id': 'salem_omalur',
        'source': 'Salem',
        'destination': 'Omalur',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [
          'salem_toll',
          'omalur_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Omalur Toll', 'amount': 55},
        ],
        'totalTollAmount': 155,
        'isActive': true,
      },
      {
        'id': 'salem_mettur',
        'source': 'Salem',
        'destination': 'Mettur',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [
          'salem_toll',
          'mettur_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Mettur Toll', 'amount': 60},
        ],
        'totalTollAmount': 160,
        'isActive': true,
      },
      {
        'id': 'salem_sankagiri',
        'source': 'Salem',
        'destination': 'Sankagiri',
        'distance': 30,
        'baseToll': 70,
        'tollPlazaIds': [
          'salem_toll',
          'sankagiri_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
          {'name': 'Sankagiri Toll', 'amount': 65},
        ],
        'totalTollAmount': 165,
        'isActive': true,
      },

      // ==================== ERODE DISTRICT ROUTES ====================
      {
        'id': 'erode_tiruppur',
        'source': 'Erode',
        'destination': 'Tiruppur',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [
          'erode_toll',
          'avinashi_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Avinashi Toll', 'amount': 60},
        ],
        'totalTollAmount': 155,
        'isActive': true,
      },
      {
        'id': 'erode_coimbatore',
        'source': 'Erode',
        'destination': 'Coimbatore',
        'distance': 100,
        'baseToll': 140,
        'tollPlazaIds': [
          'erode_toll',
          'coimbatore_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Coimbatore Toll', 'amount': 105},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'erode_bhavani',
        'source': 'Erode',
        'destination': 'Bhavani',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [
          'erode_toll',
          'bhavani_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Bhavani Toll', 'amount': 60},
        ],
        'totalTollAmount': 155,
        'isActive': true,
      },
      {
        'id': 'erode_perundurai',
        'source': 'Erode',
        'destination': 'Perundurai',
        'distance': 15,
        'baseToll': 40,
        'tollPlazaIds': [
          'erode_toll',
          'perundurai_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Perundurai Toll', 'amount': 80},
        ],
        'totalTollAmount': 175,
        'isActive': true,
      },
      {
        'id': 'erode_gobichettipalayam',
        'source': 'Erode',
        'destination': 'Gobichettipalayam',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [
          'erode_toll',
          'gobi_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
          {'name': 'Gobi Toll', 'amount': 70},
        ],
        'totalTollAmount': 165,
        'isActive': true,
      },
      {
        'id': 'erode_sathyamangalam',
        'source': 'Erode',
        'destination': 'Sathyamangalam',
        'distance': 50,
        'baseToll': 95,
        'tollPlazaIds': [
          'erode_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
        ],
        'totalTollAmount': 95,
        'isActive': true,
      },

      // ==================== TIRUPPUR DISTRICT ROUTES ====================
      {
        'id': 'tiruppur_coimbatore',
        'source': 'Tiruppur',
        'destination': 'Coimbatore',
        'distance': 50,
        'baseToll': 70,
        'tollPlazaIds': [
          'avinashi_toll',
          'coimbatore_toll'
        ],
        'tollDetails': [
          {'name': 'Avinashi Toll', 'amount': 60},
          {'name': 'Coimbatore Toll', 'amount': 105},
        ],
        'totalTollAmount': 165,
        'isActive': true,
      },
      {
        'id': 'tiruppur_erode',
        'source': 'Tiruppur',
        'destination': 'Erode',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [
          'avinashi_toll',
          'erode_toll'
        ],
        'tollDetails': [
          {'name': 'Avinashi Toll', 'amount': 60},
          {'name': 'Erode Toll', 'amount': 95},
        ],
        'totalTollAmount': 155,
        'isActive': true,
      },
      {
        'id': 'tiruppur_pollachi',
        'source': 'Tiruppur',
        'destination': 'Pollachi',
        'distance': 70,
        'baseToll': 110,
        'tollPlazaIds': [
          'palladam_toll',
          'pollachi_toll'
        ],
        'tollDetails': [
          {'name': 'Palladam Toll', 'amount': 65},
          {'name': 'Pollachi Toll', 'amount': 80},
        ],
        'totalTollAmount': 145,
        'isActive': true,
      },
      {
        'id': 'tiruppur_dharapuram',
        'source': 'Tiruppur',
        'destination': 'Dharapuram',
        'distance': 50,
        'baseToll': 90,
        'tollPlazaIds': [
          'dharapuram_toll'
        ],
        'tollDetails': [
          {'name': 'Dharapuram Toll', 'amount': 55},
        ],
        'totalTollAmount': 55,
        'isActive': true,
      },
      {
        'id': 'tiruppur_udumalpet',
        'source': 'Tiruppur',
        'destination': 'Udumalpet',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [
          'udumalpet_toll'
        ],
        'tollDetails': [
          {'name': 'Udumalpet Toll', 'amount': 65},
        ],
        'totalTollAmount': 65,
        'isActive': true,
      },
      {
        'id': 'tiruppur_palladam',
        'source': 'Tiruppur',
        'destination': 'Palladam',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [
          'palladam_toll'
        ],
        'tollDetails': [
          {'name': 'Palladam Toll', 'amount': 65},
        ],
        'totalTollAmount': 65,
        'isActive': true,
      },

      // ==================== VELLORE DISTRICT ROUTES ====================
      {
        'id': 'vellore_ranipet',
        'source': 'Vellore',
        'destination': 'Ranipet',
        'distance': 35,
        'baseToll': 80,
        'tollPlazaIds': [
          'pallikonda_toll'
        ],
        'tollDetails': [
          {'name': 'Pallikonda Toll', 'amount': 80},
        ],
        'totalTollAmount': 80,
        'isActive': true,
      },
      {
        'id': 'vellore_walajapet',
        'source': 'Vellore',
        'destination': 'Walajapet',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [
          'walajapet_toll'
        ],
        'tollDetails': [
          {'name': 'Walajapet Toll', 'amount': 95},
        ],
        'totalTollAmount': 95,
        'isActive': true,
      },
      {
        'id': 'vellore_arcot',
        'source': 'Vellore',
        'destination': 'Arcot',
        'distance': 30,
        'baseToll': 70,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'vellore_katpadi',
        'source': 'Vellore',
        'destination': 'Katpadi',
        'distance': 15,
        'baseToll': 40,
        'tollPlazaIds': [
          'katpadi_toll'
        ],
        'tollDetails': [
          {'name': 'Katpadi Toll', 'amount': 45},
        ],
        'totalTollAmount': 45,
        'isActive': true,
      },
      {
        'id': 'vellore_gudiyatham',
        'source': 'Vellore',
        'destination': 'Gudiyatham',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [
          'gudiyatham_toll'
        ],
        'tollDetails': [
          {'name': 'Gudiyatham Toll', 'amount': 50},
        ],
        'totalTollAmount': 50,
        'isActive': true,
      },
      {
        'id': 'vellore_ambur',
        'source': 'Vellore',
        'destination': 'Ambur',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [
          'ambur_toll'
        ],
        'tollDetails': [
          {'name': 'Ambur Toll', 'amount': 100},
        ],
        'totalTollAmount': 100,
        'isActive': true,
      },
      {
        'id': 'vellore_tirupathur',
        'source': 'Vellore',
        'destination': 'Tirupathur',
        'distance': 50,
        'baseToll': 95,
        'tollPlazaIds': [
          'ambur_toll',
          'vaniyambadi_toll'
        ],
        'tollDetails': [
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Vaniyambadi Toll', 'amount': 60},
        ],
        'totalTollAmount': 160,
        'isActive': true,
      },
      {
        'id': 'vellore_krishnagiri',
        'source': 'Vellore',
        'destination': 'Krishnagiri',
        'distance': 90,
        'baseToll': 140,
        'tollPlazaIds': [
          'ambur_toll',
          'krishnagiri_toll'
        ],
        'tollDetails': [
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Krishnagiri Toll', 'amount': 105},
        ],
        'totalTollAmount': 205,
        'isActive': true,
      },

      // ==================== TIRUPATHUR DISTRICT ROUTES ====================
      {
        'id': 'tirupathur_ambur',
        'source': 'Tirupathur',
        'destination': 'Ambur',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [
          'ambur_toll'
        ],
        'tollDetails': [
          {'name': 'Ambur Toll', 'amount': 100},
        ],
        'totalTollAmount': 100,
        'isActive': true,
      },
      {
        'id': 'tirupathur_vaniyambadi',
        'source': 'Tirupathur',
        'destination': 'Vaniyambadi',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'vaniyambadi_toll'
        ],
        'tollDetails': [
          {'name': 'Vaniyambadi Toll', 'amount': 60},
        ],
        'totalTollAmount': 60,
        'isActive': true,
      },
      {
        'id': 'tirupathur_natrampalli',
        'source': 'Tirupathur',
        'destination': 'Natrampalli',
        'distance': 35,
        'baseToll': 70,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'tirupathur_vellore',
        'source': 'Tirupathur',
        'destination': 'Vellore',
        'distance': 50,
        'baseToll': 95,
        'tollPlazaIds': [
          'vaniyambadi_toll',
          'ambur_toll',
          'pallikonda_toll'
        ],
        'tollDetails': [
          {'name': 'Vaniyambadi Toll', 'amount': 60},
          {'name': 'Ambur Toll', 'amount': 100},
          {'name': 'Pallikonda Toll', 'amount': 80},
        ],
        'totalTollAmount': 240,
        'isActive': true,
      },

      // ==================== KRISHNAGIRI DISTRICT ROUTES ====================
      {
        'id': 'krishnagiri_dharmapuri',
        'source': 'Krishnagiri',
        'destination': 'Dharmapuri',
        'distance': 45,
        'baseToll': 90,
        'tollPlazaIds': [
          'krishnagiri_toll',
          'dharmapuri_toll'
        ],
        'tollDetails': [
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Dharmapuri Toll', 'amount': 95},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'krishnagiri_hosur',
        'source': 'Krishnagiri',
        'destination': 'Hosur',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [
          'shoolagiri_toll',
          'hosur_toll'
        ],
        'tollDetails': [
          {'name': 'Shoolagiri Toll', 'amount': 90},
          {'name': 'Hosur Toll', 'amount': 60},
        ],
        'totalTollAmount': 150,
        'isActive': true,
      },
      {
        'id': 'krishnagiri_salem',
        'source': 'Krishnagiri',
        'destination': 'Salem',
        'distance': 85,
        'baseToll': 135,
        'tollPlazaIds': [
          'krishnagiri_toll',
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Krishnagiri Toll', 'amount': 105},
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 205,
        'isActive': true,
      },
      {
        'id': 'krishnagiri_denkanikottai',
        'source': 'Krishnagiri',
        'destination': 'Denkanikottai',
        'distance': 35,
        'baseToll': 75,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== DHARMAPURI DISTRICT ROUTES ====================
      {
        'id': 'dharmapuri_krishnagiri',
        'source': 'Dharmapuri',
        'destination': 'Krishnagiri',
        'distance': 45,
        'baseToll': 90,
        'tollPlazaIds': [
          'dharmapuri_toll',
          'krishnagiri_toll'
        ],
        'tollDetails': [
          {'name': 'Dharmapuri Toll', 'amount': 95},
          {'name': 'Krishnagiri Toll', 'amount': 105},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'dharmapuri_salem',
        'source': 'Dharmapuri',
        'destination': 'Salem',
        'distance': 65,
        'baseToll': 110,
        'tollPlazaIds': [
          'dharmapuri_toll',
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Dharmapuri Toll', 'amount': 95},
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 195,
        'isActive': true,
      },
      {
        'id': 'dharmapuri_harur',
        'source': 'Dharmapuri',
        'destination': 'Harur',
        'distance': 35,
        'baseToll': 75,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'dharmapuri_pappireddipatti',
        'source': 'Dharmapuri',
        'destination': 'Pappireddipatti',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== NAMAKKAL DISTRICT ROUTES ====================
      {
        'id': 'namakkal_salem',
        'source': 'Namakkal',
        'destination': 'Salem',
        'distance': 50,
        'baseToll': 90,
        'tollPlazaIds': [
          'salem_toll'
        ],
        'tollDetails': [
          {'name': 'Salem Toll', 'amount': 100},
        ],
        'totalTollAmount': 100,
        'isActive': true,
      },
      {
        'id': 'namakkal_erode',
        'source': 'Namakkal',
        'destination': 'Erode',
        'distance': 70,
        'baseToll': 110,
        'tollPlazaIds': [
          'erode_toll'
        ],
        'tollDetails': [
          {'name': 'Erode Toll', 'amount': 95},
        ],
        'totalTollAmount': 95,
        'isActive': true,
      },
      {
        'id': 'namakkal_tiruchengode',
        'source': 'Namakkal',
        'destination': 'Tiruchengode',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== TRICHY DISTRICT ROUTES ====================
      {
        'id': 'trichy_madurai',
        'source': 'Trichy',
        'destination': 'Madurai',
        'distance': 140,
        'baseToll': 190,
        'tollPlazaIds': [
          'trichy_toll',
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 285,
        'isActive': true,
      },
      {
        'id': 'trichy_thanjavur',
        'source': 'Trichy',
        'destination': 'Thanjavur',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'trichy_pudukkottai',
        'source': 'Trichy',
        'destination': 'Pudukkottai',
        'distance': 55,
        'baseToll': 95,
        'tollPlazaIds': [
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'trichy_karaikudi',
        'source': 'Trichy',
        'destination': 'Karaikudi',
        'distance': 90,
        'baseToll': 140,
        'tollPlazaIds': [
          'trichy_toll',
          'lechchumanapatti_toll',
          'lembalakudi_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Lechchumanapatti Toll', 'amount': 65},
          {'name': 'Lembalakudi Toll', 'amount': 60},
        ],
        'totalTollAmount': 210,
        'isActive': true,
      },
      {
        'id': 'trichy_perambalur',
        'source': 'Trichy',
        'destination': 'Perambalur',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [
          'trichy_toll',
          'perambalur_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Perambalur Toll', 'amount': 80},
        ],
        'totalTollAmount': 165,
        'isActive': true,
      },
      {
        'id': 'trichy_manaparai',
        'source': 'Trichy',
        'destination': 'Manaparai',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [
          'trichy_toll',
          'manaparai_toll',
          'manapparai_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Manaparai Toll', 'amount': 65},
          {'name': 'Manapparai Toll', 'amount': 70},
        ],
        'totalTollAmount': 220,
        'isActive': true,
      },
      {
        'id': 'trichy_musiri',
        'source': 'Trichy',
        'destination': 'Musiri',
        'distance': 35,
        'baseToll': 75,
        'tollPlazaIds': [
          'trichy_toll',
          'musiri_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
          {'name': 'Musiri Toll', 'amount': 55},
        ],
        'totalTollAmount': 140,
        'isActive': true,
      },

      // ==================== THANJAVUR DISTRICT ROUTES ====================
      {
        'id': 'thanjavur_trichy',
        'source': 'Thanjavur',
        'destination': 'Trichy',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'thanjavur_kumbakonam',
        'source': 'Thanjavur',
        'destination': 'Kumbakonam',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'thanjavur_mayiladuthurai',
        'source': 'Thanjavur',
        'destination': 'Mayiladuthurai',
        'distance': 70,
        'baseToll': 110,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== PUDUKKOTTAI DISTRICT ROUTES ====================
      {
        'id': 'pudukkottai_trichy',
        'source': 'Pudukkottai',
        'destination': 'Trichy',
        'distance': 55,
        'baseToll': 95,
        'tollPlazaIds': [
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'pudukkottai_karaikudi',
        'source': 'Pudukkottai',
        'destination': 'Karaikudi',
        'distance': 50,
        'baseToll': 90,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== SIVAGANGAI DISTRICT ROUTES ====================
      {
        'id': 'sivagangai_madurai',
        'source': 'Sivagangai',
        'destination': 'Madurai',
        'distance': 45,
        'baseToll': 70,
        'tollPlazaIds': [
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 110,
        'isActive': true,
      },
      {
        'id': 'sivagangai_karaikudi',
        'source': 'Sivagangai',
        'destination': 'Karaikudi',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'sivagangai_ramanathapuram',
        'source': 'Sivagangai',
        'destination': 'Ramanathapuram',
        'distance': 70,
        'baseToll': 110,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== RAMANATHAPURAM DISTRICT ROUTES ====================
      {
        'id': 'ramanathapuram_madurai',
        'source': 'Ramanathapuram',
        'destination': 'Madurai',
        'distance': 130,
        'baseToll': 180,
        'tollPlazaIds': [
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 110,
        'isActive': true,
      },
      {
        'id': 'ramanathapuram_rameswaram',
        'source': 'Ramanathapuram',
        'destination': 'Rameswaram',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== DINDIGUL DISTRICT ROUTES ====================
      {
        'id': 'dindigul_madurai',
        'source': 'Dindigul',
        'destination': 'Madurai',
        'distance': 65,
        'baseToll': 110,
        'tollPlazaIds': [
          'dindigul_toll',
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 200,
        'isActive': true,
      },
      {
        'id': 'dindigul_trichy',
        'source': 'Dindigul',
        'destination': 'Trichy',
        'distance': 90,
        'baseToll': 140,
        'tollPlazaIds': [
          'dindigul_toll',
          'trichy_toll'
        ],
        'tollDetails': [
          {'name': 'Dindigul Toll', 'amount': 90},
          {'name': 'Trichy Toll', 'amount': 85},
        ],
        'totalTollAmount': 175,
        'isActive': true,
      },
      {
        'id': 'dindigul_palani',
        'source': 'Dindigul',
        'destination': 'Palani',
        'distance': 50,
        'baseToll': 90,
        'tollPlazaIds': [
          'palani_toll'
        ],
        'tollDetails': [
          {'name': 'Palani Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },
      {
        'id': 'dindigul_kodaikanal',
        'source': 'Dindigul',
        'destination': 'Kodaikanal',
        'distance': 60,
        'baseToll': 100,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== THENI DISTRICT ROUTES ====================
      {
        'id': 'theni_madurai',
        'source': 'Theni',
        'destination': 'Madurai',
        'distance': 85,
        'baseToll': 150,
        'tollPlazaIds': [
          'madurai_toll'
        ],
        'tollDetails': [
          {'name': 'Madurai Toll', 'amount': 110},
        ],
        'totalTollAmount': 110,
        'isActive': true,
      },
      {
        'id': 'theni_bodinayakanur',
        'source': 'Theni',
        'destination': 'Bodinayakanur',
        'distance': 20,
        'baseToll': 0,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'theni_cumbum',
        'source': 'Theni',
        'destination': 'Cumbum',
        'distance': 40,
        'baseToll': 0,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== TENKASI DISTRICT ROUTES ====================
      {
        'id': 'tenkasi_tirunelveli',
        'source': 'Tenkasi',
        'destination': 'Tirunelveli',
        'distance': 60,
        'baseToll': 120,
        'tollPlazaIds': [
          'tirunelveli_toll'
        ],
        'tollDetails': [
          {'name': 'Tirunelveli Toll', 'amount': 85},
        ],
        'totalTollAmount': 85,
        'isActive': true,
      },
      {
        'id': 'tenkasi_kadayanallur',
        'source': 'Tenkasi',
        'destination': 'Kadayanallur',
        'distance': 25,
        'baseToll': 60,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'tenkasi_puliyangudi',
        'source': 'Tenkasi',
        'destination': 'Puliyangudi',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'tenkasi_sankarankovil',
        'source': 'Tenkasi',
        'destination': 'Sankarankovil',
        'distance': 40,
        'baseToll': 85,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== KANCHIPURAM DISTRICT ROUTES ====================
      {
        'id': 'kanchipuram_chennai',
        'source': 'Kanchipuram',
        'destination': 'Chennai',
        'distance': 75,
        'baseToll': 100,
        'tollPlazaIds': [
          'sriperumbudur_toll'
        ],
        'tollDetails': [
          {'name': 'Sriperumbudur Toll', 'amount': 60},
        ],
        'totalTollAmount': 60,
        'isActive': true,
      },
      {
        'id': 'kanchipuram_chengalpattu',
        'source': 'Kanchipuram',
        'destination': 'Chengalpattu',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'chengalpattu_toll'
        ],
        'tollDetails': [
          {'name': 'Chengalpattu Toll', 'amount': 95},
        ],
        'totalTollAmount': 95,
        'isActive': true,
      },

      // ==================== CHENGALPATTU DISTRICT ROUTES ====================
      {
        'id': 'chengalpattu_chennai',
        'source': 'Chengalpattu',
        'destination': 'Chennai',
        'distance': 60,
        'baseToll': 95,
        'tollPlazaIds': [
          'chengalpattu_toll',
          'sriperumbudur_toll'
        ],
        'tollDetails': [
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Sriperumbudur Toll', 'amount': 60},
        ],
        'totalTollAmount': 155,
        'isActive': true,
      },
      {
        'id': 'chengalpattu_mahabalipuram',
        'source': 'Chengalpattu',
        'destination': 'Mahabalipuram',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'mahabalipuram_toll'
        ],
        'tollDetails': [
          {'name': 'Mahabalipuram Toll', 'amount': 75},
        ],
        'totalTollAmount': 75,
        'isActive': true,
      },

      // ==================== VILLUPURAM DISTRICT ROUTES ====================
      {
        'id': 'villupuram_chennai',
        'source': 'Villupuram',
        'destination': 'Chennai',
        'distance': 180,
        'baseToll': 240,
        'tollPlazaIds': [
          'tindivanam_toll',
          'chengalpattu_toll',
          'sriperumbudur_toll'
        ],
        'tollDetails': [
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Sriperumbudur Toll', 'amount': 60},
        ],
        'totalTollAmount': 245,
        'isActive': true,
      },
      {
        'id': 'villupuram_pondicherry',
        'source': 'Villupuram',
        'destination': 'Pondicherry',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [
          'pondicherry_toll'
        ],
        'tollDetails': [
          {'name': 'Pondicherry Toll', 'amount': 55},
        ],
        'totalTollAmount': 55,
        'isActive': true,
      },

      // ==================== CUDDALORE DISTRICT ROUTES ====================
      {
        'id': 'cuddalore_chennai',
        'source': 'Cuddalore',
        'destination': 'Chennai',
        'distance': 200,
        'baseToll': 250,
        'tollPlazaIds': [
          'pondicherry_toll',
          'tindivanam_toll',
          'chengalpattu_toll',
          'sriperumbudur_toll'
        ],
        'tollDetails': [
          {'name': 'Pondicherry Toll', 'amount': 55},
          {'name': 'Tindivanam Toll', 'amount': 90},
          {'name': 'Chengalpattu Toll', 'amount': 95},
          {'name': 'Sriperumbudur Toll', 'amount': 60},
        ],
        'totalTollAmount': 300,
        'isActive': true,
      },
      {
        'id': 'cuddalore_chidambaram',
        'source': 'Cuddalore',
        'destination': 'Chidambaram',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== NAGAPATTINAM DISTRICT ROUTES ====================
      {
        'id': 'nagapattinam_velankanni',
        'source': 'Nagapattinam',
        'destination': 'Velankanni',
        'distance': 15,
        'baseToll': 0,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'nagapattinam_thiruvarur',
        'source': 'Nagapattinam',
        'destination': 'Thiruvarur',
        'distance': 30,
        'baseToll': 0,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },

      // ==================== NILGIRIS DISTRICT ROUTES ====================
      {
        'id': 'ooty_coonoor',
        'source': 'Ooty',
        'destination': 'Coonoor',
        'distance': 20,
        'baseToll': 50,
        'tollPlazaIds': [],
        'tollDetails': [],
        'totalTollAmount': 0,
        'isActive': true,
      },
      {
        'id': 'ooty_mettupalayam',
        'source': 'Ooty',
        'destination': 'Mettupalayam',
        'distance': 40,
        'baseToll': 80,
        'tollPlazaIds': [
          'mettupalayam_toll'
        ],
        'tollDetails': [
          {'name': 'Mettupalayam Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },
      {
        'id': 'ooty_coimbatore',
        'source': 'Ooty',
        'destination': 'Coimbatore',
        'distance': 85,
        'baseToll': 120,
        'tollPlazaIds': [
          'mettupalayam_toll',
          'coimbatore_toll'
        ],
        'tollDetails': [
          {'name': 'Mettupalayam Toll', 'amount': 70},
          {'name': 'Coimbatore Toll', 'amount': 105},
        ],
        'totalTollAmount': 175,
        'isActive': true,
      },
      {
        'id': 'coonoor_mettupalayam',
        'source': 'Coonoor',
        'destination': 'Mettupalayam',
        'distance': 30,
        'baseToll': 65,
        'tollPlazaIds': [
          'mettupalayam_toll'
        ],
        'tollDetails': [
          {'name': 'Mettupalayam Toll', 'amount': 70},
        ],
        'totalTollAmount': 70,
        'isActive': true,
      },
    ];
  }

  // Get all route names for dropdown
  static List<String> getAllRouteNames() {
    return [
      'Chennai → Madurai',
      'Chennai → Coimbatore',
      'Chennai → Tirunelveli',
      'Chennai → Kanyakumari',
      'Chennai → Pondicherry',
      'Chennai → Bengaluru',
      'Chennai → Salem',
      'Chennai → Trichy',
      'Chennai → Vellore',
      'Chennai → Kanchipuram',
      'Chennai → Tiruvallur',
      'Chennai → Cuddalore',
      'Chennai → Thanjavur',
      'Chennai → Erode',
      'Chennai → Tiruppur',
      'Chennai → Dindigul',
      'Chennai → Virudhunagar',
      'Chennai → Thoothukudi',
      'Chennai → Krishnagiri',
      'Chennai → Dharmapuri',
      'Chennai → Namakkal',
      'Chennai → Kallakurichi',
      'Chennai → Villupuram',
      'Chennai → Ariyalur',
      'Chennai → Perambalur',
      'Chennai → Pudukkottai',
      'Chennai → Ramanathapuram',
      'Chennai → Sivagangai',
      'Chennai → Theni',
      'Chennai → Tenkasi',
      'Chennai → Nagercoil',
      'Coimbatore → Madurai',
      'Coimbatore → Tirunelveli',
      'Coimbatore → Kanyakumari',
      'Coimbatore → Salem',
      'Coimbatore → Erode',
      'Coimbatore → Tiruppur',
      'Coimbatore → Ooty',
      'Coimbatore → Pollachi',
      'Coimbatore → Palakkad',
      'Coimbatore → Valparai',
      'Madurai → Tirunelveli',
      'Madurai → Kanyakumari',
      'Madurai → Dindigul',
      'Madurai → Virudhunagar',
      'Madurai → Theni',
      'Madurai → Ramanathapuram',
      'Madurai → Sivagangai',
      'Madurai → Kodaikanal',
      'Madurai → Sivakasi',
      'Madurai → Rajapalayam',
      'Madurai → Thoothukudi',
      'Madurai → Tenkasi',
      'Madurai → Nagercoil',
      'Tirunelveli → Kanyakumari',
      'Tirunelveli → Thoothukudi',
      'Tirunelveli → Tenkasi',
      'Tirunelveli → Valliyur',
      'Tirunelveli → Nagercoil',
      'Tirunelveli → Ambasamudram',
      'Virudhunagar → Sivakasi',
      'Virudhunagar → Rajapalayam',
      'Virudhunagar → Satur',
      'Virudhunagar → Kovilpatti',
      'Virudhunagar → Tirunelveli',
      'Sivakasi → Srivilliputhur',
      'Sivakasi → Rajapalayam',
      'Sivakasi → Virudhunagar',
      'Sivakasi → Satur',
      'Rajapalayam → Srivilliputhur',
      'Rajapalayam → Virudhunagar',
      'Satur → Kovilpatti',
      'Satur → Virudhunagar',
      'Kanyakumari → Nagercoil',
      'Kanyakumari → Marthandam',
      'Kanyakumari → Thuckalay',
      'Kanyakumari → Kuzhithurai',
      'Kanyakumari → Colachel',
      'Nagercoil → Marthandam',
      'Nagercoil → Thuckalay',
      'Nagercoil → Kuzhithurai',
      'Nagercoil → Padmanabhapuram',
      'Thoothukudi → Tiruchendur',
      'Thoothukudi → Kovilpatti',
      'Thoothukudi → Kayalpattinam',
      'Thoothukudi → Tirunelveli',
      'Thoothukudi → Ettayapuram',
      'Tiruchendur → Kayalpattinam',
      'Salem → Erode',
      'Salem → Coimbatore',
      'Salem → Dharmapuri',
      'Salem → Krishnagiri',
      'Salem → Namakkal',
      'Salem → Attur',
      'Salem → Omalur',
      'Salem → Mettur',
      'Salem → Sankagiri',
      'Erode → Tiruppur',
      'Erode → Coimbatore',
      'Erode → Bhavani',
      'Erode → Perundurai',
      'Erode → Gobichettipalayam',
      'Erode → Sathyamangalam',
      'Tiruppur → Coimbatore',
      'Tiruppur → Erode',
      'Tiruppur → Pollachi',
      'Tiruppur → Dharapuram',
      'Tiruppur → Udumalpet',
      'Tiruppur → Palladam',
      'Vellore → Ranipet',
      'Vellore → Walajapet',
      'Vellore → Arcot',
      'Vellore → Katpadi',
      'Vellore → Gudiyatham',
      'Vellore → Ambur',
      'Vellore → Tirupathur',
      'Vellore → Krishnagiri',
      'Tirupathur → Ambur',
      'Tirupathur → Vaniyambadi',
      'Tirupathur → Natrampalli',
      'Tirupathur → Vellore',
      'Krishnagiri → Dharmapuri',
      'Krishnagiri → Hosur',
      'Krishnagiri → Salem',
      'Krishnagiri → Denkanikottai',
      'Dharmapuri → Krishnagiri',
      'Dharmapuri → Salem',
      'Dharmapuri → Harur',
      'Dharmapuri → Pappireddipatti',
      'Namakkal → Salem',
      'Namakkal → Erode',
      'Namakkal → Tiruchengode',
      'Trichy → Madurai',
      'Trichy → Thanjavur',
      'Trichy → Pudukkottai',
      'Trichy → Karaikudi',
      'Trichy → Perambalur',
      'Trichy → Manaparai',
      'Trichy → Musiri',
      'Thanjavur → Trichy',
      'Thanjavur → Kumbakonam',
      'Thanjavur → Mayiladuthurai',
      'Pudukkottai → Trichy',
      'Pudukkottai → Karaikudi',
      'Sivagangai → Madurai',
      'Sivagangai → Karaikudi',
      'Sivagangai → Ramanathapuram',
      'Ramanathapuram → Madurai',
      'Ramanathapuram → Rameswaram',
      'Dindigul → Madurai',
      'Dindigul → Trichy',
      'Dindigul → Palani',
      'Dindigul → Kodaikanal',
      'Theni → Madurai',
      'Theni → Bodinayakanur',
      'Theni → Cumbum',
      'Tenkasi → Tirunelveli',
      'Tenkasi → Kadayanallur',
      'Tenkasi → Puliyangudi',
      'Tenkasi → Sankarankovil',
      'Kanchipuram → Chennai',
      'Kanchipuram → Chengalpattu',
      'Chengalpattu → Chennai',
      'Chengalpattu → Mahabalipuram',
      'Villupuram → Chennai',
      'Villupuram → Pondicherry',
      'Cuddalore → Chennai',
      'Cuddalore → Chidambaram',
      'Nagapattinam → Velankanni',
      'Nagapattinam → Thiruvarur',
      'Ooty → Coonoor',
      'Ooty → Mettupalayam',
      'Ooty → Coimbatore',
      'Coonoor → Mettupalayam',
    ];
  }

  // Get route by source and destination
  static Map<String, dynamic>? getRoute(String source, String destination) {
    final routes = getAllTollRoutes();
    try {
      return routes.firstWhere((route) =>
          route['source'].toString().toLowerCase() == source.toLowerCase() &&
          route['destination'].toString().toLowerCase() == destination.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Get all unique sources
  static List<String> getAllSources() {
    final routes = getAllTollRoutes();
    final sources =
        routes.map((route) => route['source'] as String).toSet().toList();
    sources.sort();
    return sources;
  }

  // Get destinations by source
  static List<String> getDestinationsBySource(String source) {
    final routes = getAllTollRoutes();
    return routes
        .where((route) => route['source'].toString().toLowerCase() == source.toLowerCase())
        .map((route) => route['destination'] as String)
        .toList();
  }

  // Get all unique districts/cities
  static List<String> getAllLocations() {
    final routes = getAllTollRoutes();
    final sources = routes.map((route) => route['source'] as String).toSet();
    final destinations =
        routes.map((route) => route['destination'] as String).toSet();
    final allLocations = {...sources, ...destinations}.toList();
    allLocations.sort();
    return allLocations;
  }

  // Get toll details for a specific route
  static List<Map<String, dynamic>>? getTollDetails(String source, String destination) {
    final route = getRoute(source, destination);
    return route?['tollDetails'];
  }

  // Get total toll amount for a specific route
  static int getTotalTollAmount(String source, String destination) {
    final route = getRoute(source, destination);
    return route?['totalTollAmount'] ?? 0;
  }
}