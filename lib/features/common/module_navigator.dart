import 'package:flutter/material.dart';

import '../home/business_add_screen.dart';
import '../home/module_config.dart';
import '../home/worker_categories_screen.dart';
import 'api_list_screen.dart';
import 'module_layout.dart';

void openReadModule(BuildContext context, ReadModule module) {
  if (module.useCategoryView) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkerCategoriesScreen()));
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ApiListScreen(
        title: module.title,
        endpoint: module.endpoint,
        layout: module.layout,
        floatingActionButton: module.layout == ModuleLayout.business
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BusinessAddScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_business),
                label: const Text('ব্যবসা যোগ করুন'),
              )
            : null,
      ),
    ),
  );
}
