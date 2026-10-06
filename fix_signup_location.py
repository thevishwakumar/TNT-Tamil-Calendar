path = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\signup_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# 1. Import location models and selector
if 'import \'../../models/location_models.dart\';' not in content:
    content = content.replace("import '../../models/tnt_models.dart';", "import '../../models/tnt_models.dart';\nimport '../../models/location_models.dart';\nimport '../../core/widgets/location_selector_modal.dart';")

# 2. Change TNTLocationSelection _selectedLocation = TNTLocationSelection();
# to TNTCity _selectedLocation = TNTCity(...);
content = re.sub(
    r"TNTLocationSelection\s+_selectedLocation\s*=\s*TNTLocationSelection\(\);",
    r'''TNTCity _selectedLocation = const TNTCity(
    id: 'cbe',
    districtId: 'cbe_dist',
    stateId: 'tn',
    countryId: 'in',
    name: 'Coimbatore',
    nameTa: '?????????????',
    latitude: 11.01,
    longitude: 76.95,
    timezone: 'Asia/Kolkata',
  );''',
    content
)

# 3. Fix location usages
content = content.replace("_selectedLocation.city.nameEn", "_selectedLocation.name")
content = content.replace("_selectedLocation.city.latitude", "_selectedLocation.latitude")
content = content.replace("_selectedLocation.city.longitude", "_selectedLocation.longitude")
content = content.replace("_selectedLocation.city.timezone", "_selectedLocation.timezone")
content = content.replace("_selectedLocation.formattedSummary(isTamil)", "isTamil ? _selectedLocation.nameTa : _selectedLocation.name")

# 4. Fix _openLocationPicker
pattern_picker = r"void _openLocationPicker\(bool isTamil\) async \{[\s\S]*?\n\s*\}"
replacement_picker = '''void _openLocationPicker(bool isTamil) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: LocationSelectorModal(
          initialCity: _selectedLocation,
          isTamil: isTamil,
          onCitySelected: (city) {
            setState(() {
              _selectedLocation = city;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }'''
content = re.sub(pattern_picker, replacement_picker, content)

# 5. Remove MockCity and TNTLocationSelection classes at the bottom
content = re.sub(r"class MockCity\s*\{[\s\S]*?\}\s*class TNTLocationSelection\s*\{[\s\S]*?\}", "", content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
