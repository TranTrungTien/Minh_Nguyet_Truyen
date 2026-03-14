import 'package:flutter/material.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';
import 'package:minh_nguyet_truyen/core/constants/constants.dart';
import 'package:minh_nguyet_truyen/core/utils/noti.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerHome extends StatefulWidget {
  const DrawerHome(
      {super.key, required this.selectedIndex, required this.onChanged});

  final int selectedIndex;

  final void Function(int indexSelect) onChanged;

  @override
  State<DrawerHome> createState() => _DrawerHomeState();
}

class _DrawerHomeState extends State<DrawerHome> {
  @override
  Widget build(BuildContext context) {
    final int indexSelect = widget.selectedIndex;
    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 6),
                child: Text(
                  APP_NAME,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _menuItem(
                  title: "Trang chủ",
                  icon: Icons.home_outlined,
                  index: 0,
                  indexSelect: indexSelect,
                  isCommingSoonFeature: false,
                ),
                _menuItem(
                  title: "Thể loại",
                  icon: Icons.category_outlined,
                  index: 1,
                  indexSelect: indexSelect,
                  isCommingSoonFeature: false,
                ),
                _menuItem(
                  title: "Bookmark",
                  icon: Icons.bookmark_border_outlined,
                  index: 2,
                  indexSelect: indexSelect,
                  isCommingSoonFeature: false,
                ),
                _menuItem(
                    title: "Xếp hạng",
                    icon: Icons.hotel_class_outlined,
                    index: 3,
                    indexSelect: indexSelect),
                _menuItem(
                    title: "Lịch sử",
                    icon: Icons.history_outlined,
                    index: 4,
                    indexSelect: indexSelect),
                ListTile(
                  leading: const Icon(Icons.email_outlined,
                      color: AppColors.textPrimary),
                  title: const Text(
                    "Góp ý & Báo lỗi",
                    style:
                        TextStyle(fontSize: 18, color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    _sendEmail();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendEmail() async {
    final String subject = Uri.encodeComponent("[Góp ý/Báo lỗi] - Ứng dụng Minh Nguyệt Truyện");
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'trantrungtien9x@gmail.com',
      query: 'subject=$subject',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở ứng dụng email. Vui lòng gửi trực tiếp đến trantrungtien9x@gmail.com'),
          ),
        );
      }
    }
  }

  Widget _menuItem({
    required String title,
    required IconData icon,
    required int index,
    required int indexSelect,
    bool isCommingSoonFeature = true,
  }) {
    final bool isSelected = indexSelect == index;

    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primary,
      tileColor: Colors.transparent,
      selectedColor: AppColors.textOnPrimary,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
        ),
      ),
      onTap: () {
        if (indexSelect != index && !isCommingSoonFeature) {
          widget.onChanged(index);
        } else {
          showFeatureComingSoon(context);
        }
        Navigator.pop(context);
      },
    );
  }
}
