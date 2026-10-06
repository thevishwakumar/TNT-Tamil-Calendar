import re

p1 = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\signup_screen.dart'
with open(p1, 'r', encoding='utf-8') as f:
    code = f.read()

# Add a mock class for TNTLocationSelection
mock_class = '''
class MockCity {
  final String nameEn = "Coimbatore";
  final double latitude = 11.01;
  final double longitude = 76.95;
  final String timezone = "Asia/Kolkata";
}

class TNTLocationSelection {
  final MockCity city = MockCity();
  String formattedSummary(bool isTamil) => "Coimbatore, Tamil Nadu, India";
}
'''

code = code.replace('String _selectedLocation = "";', 'TNTLocationSelection _selectedLocation = TNTLocationSelection();')
code = code.replace('final selection = null;', 'final selection = TNTLocationSelection();')

if 'class TNTLocationSelection' not in code:
    code = code + mock_class

with open(p1, 'w', encoding='utf-8') as f:
    f.write(code)

print("Mock injected")
