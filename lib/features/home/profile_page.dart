import 'package:flutter/material.dart';

import 'more_page.dart';

@Deprecated('Use MorePage instead')
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MorePage();
  }
}
