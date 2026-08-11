import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';
import '../jobs/my_job_posts_screen.dart';
import '../jobs/my_job_applications_screen.dart';
import '../property/my_properties_screen.dart';
import '../restaurant/my_restaurants_screen.dart';
import '../hotel/my_hotels_screen.dart';
import '../hospital/my_hospitals_screen.dart';
import '../education/my_education_screen.dart';
import '../car_rental/my_car_rentals_screen.dart';
import '../car_rental/my_car_rental_bookings_screen.dart';
import '../courier/my_courier_offices_screen.dart';
import '../electricity/my_electricity_offices_screen.dart';
import '../doctor/my_doctor_appointments_screen.dart';
import '../teacher/my_teacher_requests_screen.dart';
import '../teacher/my_student_requests_screen.dart';

class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'আমার কার্যক্রম',
        subtitle: 'পোস্ট, আবেদন, বুকিং',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            context,
            children: [
              _navTile(
                context,
                Icons.work_outline,
                'আমার চাকরি পোস্ট',
                () => _open(context, const MyJobPostsScreen()),
              ),
              _navTile(
                context,
                Icons.assignment_turned_in_outlined,
                'আমার জব আবেদন',
                () => _open(context, const MyJobApplicationsScreen()),
              ),
              _navTile(
                context,
                Icons.home_work_outlined,
                'আমার প্রোপার্টি',
                () => _open(context, const MyPropertiesScreen()),
              ),
              _navTile(
                context,
                Icons.restaurant_outlined,
                'আমার রেস্টুরেন্ট',
                () => _open(context, const MyRestaurantsScreen()),
              ),
              _navTile(
                context,
                Icons.hotel_outlined,
                'আমার হোটেল',
                () => _open(context, const MyHotelsScreen()),
              ),
              _navTile(
                context,
                Icons.local_hospital_outlined,
                'আমার হাসপাতাল',
                () => _open(context, const MyHospitalsScreen()),
              ),
              _navTile(
                context,
                Icons.school_outlined,
                'আমার শিক্ষা প্রতিষ্ঠান',
                () => _open(context, const MyEducationScreen()),
              ),
              _navTile(
                context,
                Icons.directions_car_outlined,
                'আমার গাড়ি ভাড়া পোস্ট',
                () => _open(context, const MyCarRentalsScreen()),
              ),
              _navTile(
                context,
                Icons.event_available_outlined,
                'আমার গাড়ি ভাড়া বুকিং',
                () => _open(context, const MyCarRentalBookingsScreen()),
              ),
              _navTile(
                context,
                Icons.local_shipping_outlined,
                'আমার কুরিয়ার অফিস',
                () => _open(context, const MyCourierOfficesScreen()),
              ),
              _navTile(
                context,
                Icons.electrical_services_outlined,
                'আমার বিদ্যুৎ অফিস',
                () => _open(context, const MyElectricityOfficesScreen()),
              ),
              _navTile(
                context,
                Icons.medical_services_outlined,
                'আমার ডাক্তারের অ্যাপয়েন্টমেন্ট',
                () => _open(context, const MyDoctorAppointmentsScreen()),
              ),
              _navTile(
                context,
                Icons.school,
                'আমার টিচার রিকোয়েস্ট',
                () => _open(context, const MyTeacherRequestsScreen()),
              ),
              _navTile(
                context,
                Icons.class_outlined,
                'আমার স্টুডেন্ট রিকোয়েস্ট',
                () => _open(context, const MyStudentRequestsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'উপরের তালিকা থেকে যেকোনো সেকশন খুলে আপনার পোস্ট বা আবেদনগুলো ম্যানেজ করতে পারবেন।',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _navTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: scheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
