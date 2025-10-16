import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

typedef OnSearch = void Function(String value);
typedef OnTypeChange = void Function(String type);

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String initialType;
  final OnSearch onSearch;
  final OnTypeChange onTypeChange;

  const SearchBar({
    super.key,
    required this.controller,
    this.initialType = 'all',
    required this.onSearch,
    required this.onTypeChange,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late String _searchType;
  bool _showSearchOptions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchType = widget.initialType;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchTypes = [
      {'key': 'all', 'label': 'Tous les champs', 'icon': Icons.search},
      {'key': 'code', 'label': 'Code équipement', 'icon': Icons.qr_code},
      {'key': 'description', 'label': 'Description', 'icon': Icons.description},
      {'key': 'zone', 'label': 'Zone', 'icon': Icons.location_on},
      {'key': 'famille', 'label': 'Famille', 'icon': Icons.category},
    ];

    String getSearchPlaceholder() {
      switch (_searchType) {
        case 'code':
          return 'Rechercher par code...';
        case 'description':
          return 'Rechercher par description...';
        case 'zone':
          return 'Rechercher par zone...';
        case 'famille':
          return 'Rechercher par famille...';
        default:
          return 'Rechercher par...';
      }
    }

    return Column(
      children: [
        TextFormField(
          controller: widget.controller,
          style: const TextStyle(color: AppTheme.thirdColor),
          decoration: InputDecoration(
            labelText: getSearchPlaceholder(),
            prefixIcon: IconButton(
              icon: Icon(_showSearchOptions ? Icons.filter_list : Icons.tune),
              onPressed:
                  () =>
                      setState(() => _showSearchOptions = !_showSearchOptions),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchType != 'all')
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _searchType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => widget.onSearch(widget.controller.text),
                ),
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onSearch('');
                      FocusScope.of(context).unfocus();
                    },
                  ),
              ],
            ),
          ),
          onChanged: _onChanged,
          onFieldSubmitted: widget.onSearch,
          textInputAction: TextInputAction.search,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showSearchOptions ? 60 : 0,
          child:
              _showSearchOptions
                  ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children:
                          searchTypes.map((type) {
                            final key = type['key'] as String;
                            final isSelected = _searchType == key;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _searchType = key);
                                widget.onTypeChange(key);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppTheme.secondaryColor
                                          : AppTheme.primaryColor20,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppTheme.secondaryColor
                                            : AppTheme.thirdColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      type['icon'] as IconData,
                                      size: 16,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : AppTheme.thirdColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      type['label'] as String,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppTheme.thirdColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
