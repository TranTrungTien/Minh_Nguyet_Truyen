import 'package:flutter/material.dart';
import 'package:minh_nguyet_truyen/app/presentaion/pages/bookmark/body_bookmark.dart';
import 'package:minh_nguyet_truyen/app/presentaion/pages/genres/body_genre_page.dart';
import 'package:minh_nguyet_truyen/app/presentaion/pages/home/body_home_page.dart';
import 'package:minh_nguyet_truyen/app/presentaion/pages/page_not_found.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/app_bar/app_bar.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/drawer_home.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';
import 'package:minh_nguyet_truyen/config/routes/routes_name.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final _pages = const <Widget>[
    BodyHomePage(),
    BodyGenrePage(),
    BookmarkPage(),
  ];

  @override
  Widget build(BuildContext context) {
    void handleOnPressed() {
      Navigator.of(context).pushNamed(RoutesName.kSearch);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBarWidget(
        title: "Đọc truyện miễn phí",
        onPressed: handleOnPressed,
        isSearch: true,
      ),
      drawer: DrawerHome(
        selectedIndex: _selectedIndex,
        onChanged: (selectedIndex) {
          if (selectedIndex < 0 || selectedIndex >= _pages.length) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PageNotFound()),
            );
            return;
          }
          setState(() => _selectedIndex = selectedIndex);
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}
