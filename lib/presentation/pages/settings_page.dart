import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '播放設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('播放速度'),
            subtitle: const Text('1.0x'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 設置播放速度
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('睡眠計時器'),
            subtitle: const Text('關閉'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 設置睡眠計時器
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '應用設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主題'),
            subtitle: const Text('跟隨系統'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 設置主題
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_eta),
            title: const Text('車用模式'),
            subtitle: const Text('大按鈕介面'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 切換車用模式
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '關於',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('版本'),
            subtitle: const Text(AppConstants.appVersion),
          ),
        ],
      ),
    );
  }
} 