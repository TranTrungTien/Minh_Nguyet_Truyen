import 'package:flutter/material.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';
import 'package:minh_nguyet_truyen/services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _shouldIgnoreUpdate = false;

  void _onClose() {
    if (widget.updateInfo.type == UpdateType.soft && _shouldIgnoreUpdate) {
      UpdateService.ignoreSoftUpdate(widget.updateInfo.latestVersion!);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isForce = widget.updateInfo.type == UpdateType.force;

    return PopScope(
      canPop: !isForce,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/icons/rocket.png',
                    height: 100,
                  ),
                  if (!isForce)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _onClose,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.updateInfo.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.updateInfo.message,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  if (!isForce) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _shouldIgnoreUpdate = !_shouldIgnoreUpdate;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: _shouldIgnoreUpdate,
                            onChanged: (value) {
                              setState(() {
                                _shouldIgnoreUpdate = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          const Expanded(
                            child: Text(
                              'Không hiện lại',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: UpdateService.launchStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'UPDATE NOW',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  if (!isForce) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _onClose,
                      child: const Text(
                        'Later',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
