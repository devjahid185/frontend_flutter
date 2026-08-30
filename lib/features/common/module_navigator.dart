import 'package:flutter/material.dart';

import '../home/business_add_screen.dart';
import '../home/module_config.dart';
import '../home/worker_categories_screen.dart';
import '../blood/blood_home_screen.dart';
import '../jobs/jobs_home_screen.dart';
import '../property/property_home_screen.dart';
import '../doctor/doctor_category_screen.dart';
import '../hospital/hospital_category_screen.dart';
import '../hotel/hotel_category_screen.dart';
import '../restaurant/restaurant_category_screen.dart';
import '../education/education_category_screen.dart';
import '../food/food_home_screen.dart';
import '../medicine/medicine_home_screen.dart';
import '../car_rental/car_rental_category_screen.dart';
import '../launch_service/launch_list_screen.dart';
import '../courier/courier_company_screen.dart';
import '../electricity/electricity_office_list_screen.dart';
import '../teacher/teacher_category_screen.dart';
import 'api_list_screen.dart';
import 'module_layout.dart';

void openReadModule(BuildContext context, ReadModule module) {
  if (module.useCategoryView) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WorkerCategoriesScreen()));
    return;
  }

  if (module.layout == ModuleLayout.blood) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BloodHomeScreen()));
    return;
  }
  if (module.layout == ModuleLayout.jobs) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const JobsHomeScreen()));
    return;
  }
  if (module.layout == ModuleLayout.food) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodHomeScreen()));
    return;
  }
  if (module.layout == ModuleLayout.medicine) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MedicineHomeScreen()));
    return;
  }
  if (module.layout == ModuleLayout.property) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PropertyHomeScreen()));
    return;
  }
  if (module.layout == ModuleLayout.doctor) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DoctorCategoryScreen()));
    return;
  }
  if (module.layout == ModuleLayout.hospital) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HospitalCategoryScreen()));
    return;
  }
  if (module.layout == ModuleLayout.hotel) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HotelCategoryScreen()));
    return;
  }
  if (module.layout == ModuleLayout.restaurant) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RestaurantCategoryScreen()));
    return;
  }
  if (module.layout == ModuleLayout.education) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EducationCategoryScreen()));
    return;
  }
  if (module.layout == ModuleLayout.carRental) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CarRentalCategoryScreen()));
    return;
  }
  if (module.layout == ModuleLayout.launchService) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LaunchListScreen()));
    return;
  }
  if (module.layout == ModuleLayout.courier) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CourierCompanyScreen()));
    return;
  }
  if (module.layout == ModuleLayout.electricity) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ElectricityOfficeListScreen()),
    );
    return;
  }
  if (module.layout == ModuleLayout.teacher) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TeacherCategoryScreen()));
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
