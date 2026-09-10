import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const _ActivityHeader(title: 'আমার কার্যক্রম'),
          const SizedBox(height: 16),
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
          const Text(
            'উপরের তালিকা থেকে যেকোনো সেকশন খুলে আপনার পোস্ট বা আবেদনগুলো ম্যানেজ করতে পারবেন।',
            style: TextStyle(color: Color(0xff4b5563), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 72, color: Color(0xffe5e7eb)),
          ],
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xffe6f1ee),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xff006a4e), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xff1f2937),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xff9ca3af),
      ),
      onTap: onTap,
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xff1f2937),
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff1f2937),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
