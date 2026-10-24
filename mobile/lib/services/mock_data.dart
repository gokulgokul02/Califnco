import '../models/product.dart';

class MockCatalogData {
  static final List<Product> products = _generate54Products();

  static List<Product> _generate54Products() {
    final productBases = [
      // RO Purifiers
      {
        'name': 'Califnco AquaPure RO 7-Stage Purifier',
        'cat': 'RO Purifier',
        'desc': '7-Stage multi-barrier purification with Alkaline Mineralizer and Copper Charge technology. Suitable for TDS up to 2000 ppm.',
        'price': 14999.0,
        'wholesale': 10800.0,
        'img': 'https://images.unsplash.com/photo-1585672840545-be5e76a6d654?auto=format&fit=crop&w=800&q=80',
        'specs': {'Stages': '7-Stage RO+UV+UF+Alkaline', 'TDS Capacity': 'Up to 2000 ppm', 'Storage': '10 Liters', 'Power': '36W'},
      },
      {
        'name': 'Califnco HydroShield Smart RO+UV Touch',
        'cat': 'RO Purifier',
        'desc': 'Digital display purifier with real-time TDS and filter life indicator. In-tank UV sterilization.',
        'price': 17499.0,
        'wholesale': 12500.0,
        'img': 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=800&q=80',
        'specs': {'Stages': '8-Stage Digital RO', 'TDS Capacity': 'Up to 2500 ppm', 'Storage': '8.5 Liters', 'Display': 'Digital LED'},
      },
      {
        'name': 'Califnco AquaCompact Under-Sink RO',
        'cat': 'RO Purifier',
        'desc': 'Space-saving under-the-counter RO purifier with brushed stainless steel faucet and hydrostatic tank.',
        'price': 19999.0,
        'wholesale': 14200.0,
        'img': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
        'specs': {'Stages': '6-Stage RO System', 'TDS Capacity': 'Up to 1800 ppm', 'Flow Rate': '15 L/hr', 'Installation': 'Under-sink'},
      },
      {
        'name': 'Califnco PureElite Commercial 50 LPH RO',
        'cat': 'RO Purifier',
        'desc': 'Heavy-duty commercial RO system for offices, restaurants and clinics with dual booster pumps.',
        'price': 34999.0,
        'wholesale': 26500.0,
        'img': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
        'specs': {'Capacity': '50 Liters/Hour', 'Pumps': 'Dual 100 GPD', 'Membrane': '4x 75 GPD', 'Duty Cycle': 'Commercial'},
      },
      // UV Purifiers
      {
        'name': 'Califnco CrystalClear UV Flow',
        'cat': 'UV Purifier',
        'desc': 'Instant microbiological disinfection using high-intensity UV-C lamp with stainless steel disinfection chamber.',
        'price': 7999.0,
        'wholesale': 5800.0,
        'img': 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f9?auto=format&fit=crop&w=800&q=80',
        'specs': {'Lamp': '11W High-Intensity UV-C', 'Flow': '2.0 Liters/min', 'Chamber': 'SS-304 Grade', 'Water Source': 'Municipal'},
      },
      {
        'name': 'Califnco ClearWave UV+UF Compact',
        'cat': 'UV Purifier',
        'desc': 'Zero water wastage dual disinfection purifier for municipal and low TDS water sources.',
        'price': 8999.0,
        'wholesale': 6400.0,
        'img': 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=800&q=80',
        'specs': {'Filtration': 'UV-C + Ultrafiltration', 'Wastage': 'Zero Water Wastage', 'Filter Life': '6000 Liters'},
      },
      // UF Purifiers
      {
        'name': 'Califnco PureGravity Non-Electric UF',
        'cat': 'UF Purifier',
        'desc': 'Electricity-free hollow-fiber membrane purifier with 18-liter storage. Removes bacteria and cysts completely.',
        'price': 3299.0,
        'wholesale': 2250.0,
        'img': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=800&q=80',
        'specs': {'Power': 'Zero Electricity Needed', 'Storage': '18 Liters', 'Membrane': '0.01 Micron Hollow Fiber'},
      },
      {
        'name': 'Califnco FlowStream Pressure UF',
        'cat': 'UF Purifier',
        'desc': 'Direct tap pressure UF purifier without water wastage, preserving natural essential minerals.',
        'price': 4499.0,
        'wholesale': 3100.0,
        'img': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=800&q=80',
        'specs': {'Pressure Range': '0.5 - 3.0 Bar', 'Pore Size': '0.01 Micron', 'Wastage': 'Zero'},
      },
      // Water Dispensers
      {
        'name': 'Califnco HydraCool Hot & Cold Dispenser',
        'cat': 'Water Dispenser',
        'desc': 'Floor standing water dispenser with compressor cooling, child safety hot water tap and storage cabinet.',
        'price': 12499.0,
        'wholesale': 9200.0,
        'img': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=800&q=80',
        'specs': {'Hot Tank': '1.2 L (85-95°C)', 'Cold Tank': '3.2 L (5-10°C)', 'Cooling': 'Eco R134a Compressor'},
      },
      {
        'name': 'Califnco TableTop Tri-Temp Dispenser',
        'cat': 'Water Dispenser',
        'desc': 'Compact table-top dispenser serving Hot, Cold, and Ambient water at the touch of a button.',
        'price': 9999.0,
        'wholesale': 7400.0,
        'img': 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80',
        'specs': {'Type': 'Tabletop Tri-Temperature', 'Cooling': 'Silent Thermoelectric', 'Child Lock': 'Included'},
      },
      // Booster Pumps
      {
        'name': 'Califnco FlowMax 100 GPD Booster Pump',
        'cat': 'Booster Pump',
        'desc': 'Heavy duty 24V DC diaphragm pump with copper winding, low noise vibration dampers and 125 PSI peak pressure.',
        'price': 2299.0,
        'wholesale': 1650.0,
        'img': 'https://images.unsplash.com/photo-1581092335397-9583fe92d232?auto=format&fit=crop&w=800&q=80',
        'specs': {'Rating': '100 GPD', 'Voltage': '24V DC / 1.5A', 'Peak Pressure': '125 PSI', 'Winding': '100% Pure Copper'},
      },
      {
        'name': 'Califnco HeavyDuty 150 GPD Commercial Pump',
        'cat': 'Booster Pump',
        'desc': 'High suction booster pump designed for commercial 25/50 LPH RO purification units.',
        'price': 3499.0,
        'wholesale': 2450.0,
        'img': 'https://images.unsplash.com/photo-1581092162384-8987c1d64718?auto=format&fit=crop&w=800&q=80',
        'specs': {'Rating': '150 GPD', 'Voltage': '36V DC', 'Flow Rate': '2.2 LPM', 'Duty': 'Continuous'},
      },
      // Sediment Filters
      {
        'name': 'Califnco Spun Polypropylene Sediment 10"',
        'cat': 'Sediment Filter',
        'desc': '5-micron melt-blown polypropylene filter removing rust, sand, silt and suspended dirt particles.',
        'price': 299.0,
        'wholesale': 140.0,
        'img': 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?auto=format&fit=crop&w=800&q=80',
        'specs': {'Micron Rating': '5 Micron', 'Length': '10 Inches', 'Material': '100% Virgin Polypropylene'},
      },
      {
        'name': 'Califnco High-Density Wound Sediment Cartridge',
        'cat': 'Sediment Filter',
        'desc': 'Precision string wound cartridge for high sediment load borewell water supplies.',
        'price': 449.0,
        'wholesale': 220.0,
        'img': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
        'specs': {'Rating': '1 Micron', 'Capacity': 'Up to 8000 Liters', 'Compatible': 'All standard 10" housings'},
      },
      // Carbon Filters
      {
        'name': 'Califnco Activated Carbon Block Filter',
        'cat': 'Carbon Filter',
        'desc': 'Premium coconut shell carbon block with high iodine rating (1100 IV) for chlorine and odor removal.',
        'price': 699.0,
        'wholesale': 380.0,
        'img': 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=800&q=80',
        'specs': {'Iodine Value': '1100 mg/g', 'Pore Size': '5 Micron', 'Source': 'Natural Coconut Shell'},
      },
      {
        'name': 'Califnco Granular Activated Carbon (GAC) Inline',
        'cat': 'Carbon Filter',
        'desc': 'Inline post-carbon filter for polishing water taste and eliminating volatile organic compounds.',
        'price': 549.0,
        'wholesale': 290.0,
        'img': 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=800&q=80',
        'specs': {'Connection': '1/4" Quick Connect Push-fit', 'Life': '6000 Liters / 12 Months'},
      },
      // RO Membranes
      {
        'name': 'Califnco Thin Film Composite 75 GPD Membrane',
        'cat': 'RO Membrane',
        'desc': 'Precision polyamide thin-film composite sheet delivering 97% salt rejection even under variable feed water TDS.',
        'price': 1899.0,
        'wholesale': 1150.0,
        'img': 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?auto=format&fit=crop&w=800&q=80',
        'specs': {'Permeate Flow': '75 GPD (~12-15 LPH)', 'Rejection': '96% - 98%', 'TDS Range': 'Up to 2500 ppm'},
      },
      {
        'name': 'Califnco UltraRejection 100 GPD Membrane',
        'cat': 'RO Membrane',
        'desc': 'High recovery membrane certified for heavy metals, fluoride, arsenic and TDS reduction.',
        'price': 2399.0,
        'wholesale': 1450.0,
        'img': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
        'specs': {'Permeate Flow': '100 GPD', 'Rejection': '98.5%', 'Certifications': 'NSF/ANSI Standard 58 compliant'},
      },
      // Spare Parts & Fittings
      {
        'name': 'Califnco Universal 10-Inch Transparent Bowl Housing',
        'cat': 'Spare Parts',
        'desc': 'Heavy-duty food-grade pre-filter transparent housing with 1/4-inch brass-threaded ports and Teflon ring.',
        'price': 899.0,
        'wholesale': 480.0,
        'img': 'https://images.unsplash.com/photo-1581092335397-9583fe92d232?auto=format&fit=crop&w=800&q=80',
        'specs': {'Size': '10 Inch Universal', 'Port': '1/4" NPT Thread', 'Burst Pressure': '350 PSI'},
      },
      {
        'name': 'Califnco SV (Solenoid Valve) 24V DC Quick Connect',
        'cat': 'Spare Parts',
        'desc': 'High-durability automatic inlet solenoid valve preventing continuous back-flow and overflow.',
        'price': 599.0,
        'wholesale': 320.0,
        'img': 'https://images.unsplash.com/photo-1581092162384-8987c1d64718?auto=format&fit=crop&w=800&q=80',
        'specs': {'Voltage': '24V DC', 'Connection': '1/4" Push Fit', 'Operation': 'Normally Closed'},
      },
    ];

    final List<Product> list = [];
    final totalRequired = 55;

    for (int i = 0; i < totalRequired; i++) {
      final base = productBases[i % productBases.length];
      final modelIndex = (i ~/ productBases.length) + 1;
      final id = 'prod_${(i + 1).toString().padLeft(3, '0')}';
      final basePrice = (base['price'] as double);
      final baseWholesale = (base['wholesale'] as double);
      final priceVariance = ((i % 5) * 50).toDouble();

      final name = modelIndex == 1
          ? (base['name'] as String)
          : '${base['name']} - Edition $modelIndex';

      list.add(Product(
        id: id,
        name: name,
        category: base['cat'] as String,
        description: base['desc'] as String,
        price: basePrice + priceVariance,
        wholesalePrice: baseWholesale + (priceVariance * 0.7),
        stock: 40 + (i * 3) % 80,
        active: true,
        imageUrl: base['img'] as String,
        rating: 4.5 + ((i % 5) * 0.1),
        reviewsCount: 15 + (i * 4),
        specifications: Map<String, String>.from(base['specs'] as Map),
      ));
    }

    return list;
  }
}
