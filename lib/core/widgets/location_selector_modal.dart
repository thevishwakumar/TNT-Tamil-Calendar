import 'package:flutter/material.dart';
import '../../models/location_models.dart';
import '../../repositories/location_repository.dart';
import '../constants/colors.dart';

class LocationSelectorModal extends StatefulWidget {
  final TNTCity? initialCity;
  final bool isTamil;
  final ValueChanged<TNTCity> onCitySelected;

  const LocationSelectorModal({
    Key? key,
    this.initialCity,
    required this.isTamil,
    required this.onCitySelected,
  }) : super(key: key);

  @override
  State<LocationSelectorModal> createState() => _LocationSelectorModalState();
}

class _LocationSelectorModalState extends State<LocationSelectorModal> {
  final LocationRepository _repo = LocationRepository();
  final TextEditingController _searchController = TextEditingController();
  
  int _currentStep = 0; 
  // 0: Country, 1: State, 2: District, 3: City
  
  TNTCountry? _selectedCountry;
  TNTState? _selectedState;
  TNTDistrict? _selectedDistrict;
  TNTCity? _selectedCity;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildStepList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _currentStep--;
                  _searchController.clear();
                });
              },
            )
          else
            const SizedBox(width: 48),
          
          Text(
            _getStepTitle(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return widget.isTamil ? 'நாட்டை தேர்ந்தெடுக்கவும்' : 'Select Country';
      case 1: return widget.isTamil ? 'மாநிலத்தை தேர்ந்தெடுக்கவும்' : 'Select State';
      case 2: return widget.isTamil ? 'மாவட்டத்தை தேர்ந்தெடுக்கவும்' : 'Select District';
      case 3: return widget.isTamil ? 'நகரத்தை தேர்ந்தெடுக்கவும்' : 'Select City';
      default: return 'Select';
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.isTamil ? 'தேடுக...' : 'Search...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildStepList() {
    Future future;
    if (_currentStep == 0) future = _repo.getCountries();
    else if (_currentStep == 1) future = _repo.getStates(_selectedCountry!.id);
    else if (_currentStep == 2) future = _repo.getDistricts(_selectedState!.id);
    else future = _repo.searchCities(_searchQuery, districtId: _selectedDistrict!.id);

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final list = (snapshot.data as List).where((item) {
          if (_searchQuery.isEmpty) return true;
          // Step 3 cities are already server-side filtered, but no harm in local filter just in case
          if (item is TNTCity) return item.name.toLowerCase().contains(_searchQuery) || item.nameTa.toLowerCase().contains(_searchQuery);
          if (item is TNTDistrict) return item.name.toLowerCase().contains(_searchQuery) || item.nameTa.toLowerCase().contains(_searchQuery);
          if (item is TNTState) return item.name.toLowerCase().contains(_searchQuery) || item.nameTa.toLowerCase().contains(_searchQuery);
          if (item is TNTCountry) return item.name.toLowerCase().contains(_searchQuery) || item.nameTa.toLowerCase().contains(_searchQuery);
          return true;
        }).toList();

        if (list.isEmpty) {
          return Center(child: Text(widget.isTamil ? 'முடிவுகள் இல்லை' : 'No results found'));
        }

        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: const Color(0xFFE0E0E0)),
          itemBuilder: (context, index) {
            final item = list[index];
            return ListTile(
              title: Text(widget.isTamil ? item.nameTa : item.name),
              onTap: () {
                setState(() {
                  _searchController.clear();
                  if (_currentStep == 0) {
                    _selectedCountry = item as TNTCountry;
                    _currentStep = 1;
                  } else if (_currentStep == 1) {
                    _selectedState = item as TNTState;
                    _currentStep = 2;
                  } else if (_currentStep == 2) {
                    _selectedDistrict = item as TNTDistrict;
                    _currentStep = 3;
                  } else {
                    _selectedCity = item as TNTCity;
                    widget.onCitySelected(_selectedCity!);
                    Navigator.pop(context);
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
