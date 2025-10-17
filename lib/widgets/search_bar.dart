import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

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
    final responsive = context.responsive;
    final spacing = context.spacing;

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
                    margin: EdgeInsets.only(
                      right: spacing.tiny,
                    ), // ✅ Margin responsive
                    padding: spacing.custom(
                      horizontal: 6,
                      vertical: 2,
                    ), // ✅ Padding responsive
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(10),
                      ), // ✅ Border radius responsive
                    ),
                    child: Text(
                      _searchType.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.sp(10), // ✅ Texte responsive
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
          height:
              _showSearchOptions
                  ? responsive.spacing(60)
                  : 0, // ✅ Hauteur responsive
          child:
              _showSearchOptions
                  ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: spacing.custom(
                      horizontal: 12,
                      vertical: 8,
                    ), // ✅ Padding responsive
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
                                margin: EdgeInsets.only(
                                  right: spacing.small,
                                ), // ✅ Margin responsive
                                padding: spacing.custom(
                                  horizontal: 12,
                                  vertical: 6,
                                ), // ✅ Padding responsive
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppTheme.secondaryColor
                                          : AppTheme.primaryColor20,
                                  borderRadius: BorderRadius.circular(
                                    responsive.spacing(20),
                                  ), // ✅ Border radius responsive
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
                                      size: responsive.iconSize(
                                        16,
                                      ), // ✅ Icône responsive
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : AppTheme.thirdColor,
                                    ),
                                    SizedBox(
                                      width: spacing.tiny,
                                    ), // ✅ Espacement responsive
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
