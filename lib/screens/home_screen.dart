import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/screens/ot_list_screen.dart'; // ✅ Import du nouvel écran
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'OT';

  final List<Order> otOrders = List.generate(
    5,
    (index) => Order(
      id: '$index',
      icon: Icons.assignment,
      code: '#OT12345$index',
      famille: 'Famille OT $index',
      zone: 'Zone OT $index',
      entity: 'Entité OT $index',
      unite: 'Unité OT $index',
      centre: 'Centre OT $index',
      description: 'Description de l\'ordre de travail OT $index',
    ),
  );

  final List<Order> diOrders = List.generate(
    5,
    (index) => Order(
      id: '$index',
      icon: Icons.build,
      code: '#DI12345$index',
      famille: 'Famille DI $index',
      zone: 'Zone DI $index',
      entity: 'Entité DI $index',
      unite: 'Unité DI $index',
      centre: 'Centre DI $index',
      description: 'Description de la demande d\'intervention DI $index',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: Text(
          'Bienvenue sur l\'accueil',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(18),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: AppTheme.secondaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: spacing.custom(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _boxOne(responsive, spacing)),
                SizedBox(width: spacing.medium),
                Expanded(child: _boxTwo(responsive, spacing)),
              ],
            ),
            SizedBox(height: spacing.large),
            Text(
              selectedCategory == 'OT'
                  ? '${otOrders.length} Ordres de Travail en cours'
                  : '${diOrders.length} Demandes d\'Intervention en cours',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.normal,
                color: AppTheme.thirdColor,
                fontSize: responsive.sp(15),
              ),
            ),
            SizedBox(height: spacing.medium),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey(selectedCategory),
                  padding: EdgeInsets.zero,
                  itemCount:
                      selectedCategory == 'OT'
                          ? otOrders.length
                          : diOrders.length,
                  itemBuilder: (context, index) {
                    final order =
                        selectedCategory == 'OT'
                            ? otOrders[index]
                            : diOrders[index];
                    return Padding(
                      padding: spacing.custom(bottom: 10),
                      child: ListItemCustom.order(
                        id: order.id,
                        code: order.code,
                        famille: order.famille,
                        zone: order.zone,
                        entity: order.entity,
                        unite: order.unite,
                        centre: order.centre,
                        description: order.description,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boxOne(Responsive responsive, ResponsiveSpacing spacing) {
    return GestureDetector(
      onTap: () {
        // ✅ Navigation vers la page liste complète des OT
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OTListScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(responsive.spacing(10)),
          border:
              selectedCategory == 'OT'
                  ? Border.all(color: AppTheme.secondaryColor, width: 2)
                  : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: spacing.custom(all: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: responsive.spacing(50),
                        height: responsive.spacing(50),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment,
                          size: responsive.iconSize(24),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Transform(
                        transform: Matrix4.rotationZ(-0.785398),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          size: responsive.iconSize(24),
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.small),
                  Text(
                    'Ordre de Travail',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: responsive.sp(14),
                    ),
                  ),
                  SizedBox(height: spacing.small),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'De',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.thirdColor,
                          fontSize: responsive.sp(14),
                        ),
                      ),
                      Text(
                        '${otOrders.length}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontSize: responsive.sp(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(responsive.spacing(8)),
                  bottomRight: Radius.circular(responsive.spacing(8)),
                ),
                child: SizedBox(
                  height: responsive.spacing(80),
                  child: Image.asset(
                    'assets/images/bg_card.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boxTwo(Responsive responsive, ResponsiveSpacing spacing) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = 'DI';
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(responsive.spacing(10)),
          border:
              selectedCategory == 'DI'
                  ? Border.all(color: AppTheme.secondaryColor, width: 2)
                  : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: spacing.custom(all: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: responsive.spacing(50),
                        height: responsive.spacing(50),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.build,
                          size: responsive.iconSize(24),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Transform(
                        transform: Matrix4.rotationZ(-0.785398),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          size: responsive.iconSize(24),
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.small),
                  Text(
                    'Demande d\'Intervention',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: responsive.sp(14),
                    ),
                  ),
                  SizedBox(height: spacing.small),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'De',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.thirdColor,
                          fontSize: responsive.sp(14),
                        ),
                      ),
                      Text(
                        '${diOrders.length}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontSize: responsive.sp(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(responsive.spacing(8)),
                  bottomRight: Radius.circular(responsive.spacing(8)),
                ),
                child: SizedBox(
                  height: responsive.spacing(80),
                  child: Image.asset(
                    'assets/images/bg_card.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
