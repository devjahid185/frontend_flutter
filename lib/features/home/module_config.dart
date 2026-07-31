import 'package:flutter/material.dart';

import '../common/form_field_config.dart';
import '../common/module_layout.dart';

class ReadModule {
  const ReadModule({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.icon,
    required this.section,
    required this.layout,
    this.useCategoryView = false,
  });

  final String title;
  final String subtitle;
  final String endpoint;
  final IconData icon;
  final String section;
  final ModuleLayout layout;
  final bool useCategoryView;
}

class ActionModule {
  const ActionModule({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.icon,
    required this.fields,
    this.useDelete = false,
    this.allowImages = false,
    this.mediaTargetType,
    this.mediaSection,
    this.mediaResponseKey,
  });

  final String title;
  final String subtitle;
  final String endpoint;
  final IconData icon;
  final List<FormFieldConfig> fields;
  final bool useDelete;
  final bool allowImages;
  final String? mediaTargetType;
  final String? mediaSection;
  final String? mediaResponseKey;
}

const _foodModule = ReadModule(
  title: 'ফুড ডেলিভারি',
  subtitle: 'রেস্টুরেন্ট থেকে খাবার অর্ডার',
  endpoint: '/food/home',
  icon: Icons.delivery_dining,
  section: 'মার্কেট',
  layout: ModuleLayout.food,
);

const homeServiceModules = <ReadModule>[
  _foodModule,
  ReadModule(title: 'কর্মী খুঁজুন', subtitle: 'ইলেকট্রিশিয়ান, প্লাম্বার ইত্যাদি', endpoint: '/workers', icon: Icons.engineering, section: 'সেবা', layout: ModuleLayout.directory, useCategoryView: true),
  ReadModule(title: 'ব্যবসা ডিরেক্টরি', subtitle: 'লোকাল দোকান ও সেবা', endpoint: '/businesses', icon: Icons.business, section: 'মার্কেট', layout: ModuleLayout.business),
  ReadModule(title: 'মার্কেটপ্লেস', subtitle: 'বাই-সেল পণ্য', endpoint: '/items', icon: Icons.storefront, section: 'মার্কেট', layout: ModuleLayout.marketplace),
  ReadModule(title: 'চাকরি', subtitle: 'লোকাল জব পোস্ট', endpoint: '/jobs', icon: Icons.work, section: 'ক্যারিয়ার', layout: ModuleLayout.jobs),
  ReadModule(title: 'প্রোপার্টি', subtitle: 'ভাড়া ও বিক্রয়', endpoint: '/properties', icon: Icons.home_work, section: 'মার্কেট', layout: ModuleLayout.property),
  ReadModule(title: 'রক্তদাতা', subtitle: 'জরুরি ডোনার', endpoint: '/blood-donors', icon: Icons.bloodtype, section: 'জরুরি', layout: ModuleLayout.blood),
  ReadModule(title: 'ডাক্তার', subtitle: 'ডাক্তার খুঁজুন', endpoint: '/doctors', icon: Icons.medical_services, section: 'সেবা', layout: ModuleLayout.doctor),
  ReadModule(title: 'হাসপাতাল', subtitle: 'হাসপাতাল ও ক্লিনিক', endpoint: '/hospitals', icon: Icons.local_hospital, section: 'সেবা', layout: ModuleLayout.hospital),
  ReadModule(title: 'হোটেল', subtitle: 'হোটেল ও গেস্ট হাউস', endpoint: '/hotels', icon: Icons.hotel, section: 'সেবা', layout: ModuleLayout.hotel),
  ReadModule(title: 'রেস্টুরেন্ট', subtitle: 'খাবার ও রেস্টুরেন্ট', endpoint: '/restaurants', icon: Icons.restaurant, section: 'সেবা', layout: ModuleLayout.restaurant),
  ReadModule(title: 'শিক্ষা প্রতিষ্ঠান', subtitle: 'স্কুল, কলেজ, মাদ্রাসা', endpoint: '/education', icon: Icons.school, section: 'সেবা', layout: ModuleLayout.education),
  ReadModule(title: 'শিক্ষক/টিউটর', subtitle: 'টিউশন ও কোচিং', endpoint: '/teachers', icon: Icons.school, section: 'সেবা', layout: ModuleLayout.teacher),
  ReadModule(title: 'বিদ্যুৎ অফিস', subtitle: 'পল্লী বিদ্যুৎ অফিস', endpoint: '/electricity/offices', icon: Icons.electrical_services, section: 'সেবা', layout: ModuleLayout.electricity),
  ReadModule(title: 'গাড়ি ভাড়া', subtitle: 'যাত্রী/পণ্য পরিবহন', endpoint: '/car-rentals', icon: Icons.directions_car, section: 'মার্কেট', layout: ModuleLayout.carRental),
  ReadModule(title: 'লঞ্চ সার্ভিস', subtitle: 'সময়, রুট, ভাড়া ও হটলাইন', endpoint: '/launches', icon: Icons.directions_boat_filled, section: 'সেবা', layout: ModuleLayout.launchService),
  ReadModule(title: 'কুরিয়ার', subtitle: 'কুরিয়ার সার্ভিস তালিকা', endpoint: '/couriers/companies', icon: Icons.local_shipping, section: 'সেবা', layout: ModuleLayout.courier),
  ReadModule(title: 'জরুরি নম্বর', subtitle: 'পুলিশ, ফায়ার, অ্যাম্বুলেন্স', endpoint: '/emergency', icon: Icons.local_hospital, section: 'জরুরি', layout: ModuleLayout.emergency),
  ReadModule(title: 'সংবাদ', subtitle: 'জেলার আপডেট', endpoint: '/news', icon: Icons.newspaper, section: 'কমিউনিটি', layout: ModuleLayout.news),
  ReadModule(title: 'নোটিশ', subtitle: 'গুরুত্বপূর্ণ ঘোষণা', endpoint: '/notices', icon: Icons.campaign, section: 'কমিউনিটি', layout: ModuleLayout.notices),
  ReadModule(title: 'কর্মী ক্যাটাগরি', subtitle: 'পেশাভিত্তিক তালিকা', endpoint: '/worker/categories', icon: Icons.category, section: 'সেবা', layout: ModuleLayout.categories),
  ReadModule(title: 'হেল্প সেন্টার', subtitle: 'সহায়তা ও নির্দেশনা', endpoint: '/emergency', icon: Icons.support_agent, section: 'কমিউনিটি', layout: ModuleLayout.emergency),
];

const serviceModules = <ReadModule>[
  _foodModule,
  ReadModule(title: 'কর্মী তালিকা', subtitle: 'লোকাল স্কিলড ওয়ার্কার', endpoint: '/workers', icon: Icons.engineering, section: 'সেবা', layout: ModuleLayout.directory, useCategoryView: true),
  ReadModule(title: 'রক্তদাতা', subtitle: 'জরুরি রক্তদাতা খুঁজুন', endpoint: '/blood-donors', icon: Icons.bloodtype, section: 'জরুরি', layout: ModuleLayout.blood),
  ReadModule(title: 'ডাক্তার', subtitle: 'ডাক্তার খুঁজুন', endpoint: '/doctors', icon: Icons.medical_services, section: 'সেবা', layout: ModuleLayout.doctor),
  ReadModule(title: 'হাসপাতাল', subtitle: 'হাসপাতাল খুঁজুন', endpoint: '/hospitals', icon: Icons.local_hospital, section: 'সেবা', layout: ModuleLayout.hospital),
  ReadModule(title: 'হোটেল', subtitle: 'হোটেল খুঁজুন', endpoint: '/hotels', icon: Icons.hotel, section: 'সেবা', layout: ModuleLayout.hotel),
  ReadModule(title: 'রেস্টুরেন্ট', subtitle: 'রেস্টুরেন্ট খুঁজুন', endpoint: '/restaurants', icon: Icons.restaurant, section: 'সেবা', layout: ModuleLayout.restaurant),
  ReadModule(title: 'শিক্ষা প্রতিষ্ঠান', subtitle: 'স্কুল, কলেজ, মাদ্রাসা', endpoint: '/education', icon: Icons.school, section: 'সেবা', layout: ModuleLayout.education),
  ReadModule(title: 'শিক্ষক/টিউটর', subtitle: 'টিউটর খুঁজুন', endpoint: '/teachers', icon: Icons.school, section: 'সেবা', layout: ModuleLayout.teacher),
  ReadModule(title: 'বিদ্যুৎ অফিস', subtitle: 'বিদ্যুৎ অফিস খুঁজুন', endpoint: '/electricity/offices', icon: Icons.electrical_services, section: 'সেবা', layout: ModuleLayout.electricity),
  ReadModule(title: 'লঞ্চ সার্ভিস', subtitle: 'লঞ্চের সময় ও হটলাইন', endpoint: '/launches', icon: Icons.directions_boat_filled, section: 'সেবা', layout: ModuleLayout.launchService),
  ReadModule(title: 'জরুরি নম্বর', subtitle: 'পুলিশ, ফায়ার, অ্যাম্বুলেন্স', endpoint: '/emergency', icon: Icons.local_hospital, section: 'জরুরি', layout: ModuleLayout.emergency),
];

const marketplaceModules = <ReadModule>[
  _foodModule,
  ReadModule(title: 'মার্কেটপ্লেস', subtitle: 'বাই-সেল তালিকা', endpoint: '/items', icon: Icons.storefront, section: 'মার্কেট', layout: ModuleLayout.marketplace),
  ReadModule(title: 'ব্যবসা ডিরেক্টরি', subtitle: 'লোকাল ব্যবসা', endpoint: '/businesses', icon: Icons.business, section: 'মার্কেট', layout: ModuleLayout.business),
  ReadModule(title: 'প্রোপার্টি', subtitle: 'ভাড়া/বিক্রয় সম্পত্তি', endpoint: '/properties', icon: Icons.home_work, section: 'মার্কেট', layout: ModuleLayout.property),
  ReadModule(title: 'চাকরি', subtitle: 'লোকাল জব পোস্ট', endpoint: '/jobs', icon: Icons.work, section: 'ক্যারিয়ার', layout: ModuleLayout.jobs),
  ReadModule(title: 'গাড়ি ভাড়া', subtitle: 'ভাড়া ও চালক সার্ভিস', endpoint: '/car-rentals', icon: Icons.directions_car, section: 'মার্কেট', layout: ModuleLayout.carRental),
  ReadModule(title: 'লঞ্চ সার্ভিস', subtitle: 'যাতায়াত সময়সূচি', endpoint: '/launches', icon: Icons.directions_boat_filled, section: 'মার্কেট', layout: ModuleLayout.launchService),
  ReadModule(title: 'কুরিয়ার', subtitle: 'ডেলিভারি সার্ভিস', endpoint: '/couriers/companies', icon: Icons.local_shipping, section: 'মার্কেট', layout: ModuleLayout.courier),
  ReadModule(title: 'হোটেল', subtitle: 'হোটেল তালিকা', endpoint: '/hotels', icon: Icons.hotel, section: 'মার্কেট', layout: ModuleLayout.hotel),
  ReadModule(title: 'রেস্টুরেন্ট', subtitle: 'রেস্টুরেন্ট তালিকা', endpoint: '/restaurants', icon: Icons.restaurant, section: 'মার্কেট', layout: ModuleLayout.restaurant),
];

const communityModules = <ReadModule>[
  ReadModule(title: 'সংবাদ', subtitle: 'জেলার সর্বশেষ খবর', endpoint: '/news', icon: Icons.newspaper, section: 'কমিউনিটি', layout: ModuleLayout.news),
  ReadModule(title: 'নোটিশ', subtitle: 'গুরুত্বপূর্ণ ঘোষণা', endpoint: '/notices', icon: Icons.campaign, section: 'কমিউনিটি', layout: ModuleLayout.notices),
];

const quickActions = <ActionModule>[
  ActionModule(
    title: 'আইটেম পোস্ট করুন',
    subtitle: 'মার্কেটপ্লেসে নতুন বিজ্ঞাপন',
    endpoint: '/items/add',
    icon: Icons.add_box,
    allowImages: true,
    mediaTargetType: 'marketplace_item',
    mediaSection: 'marketplace',
    mediaResponseKey: 'item',
    fields: [
      FormFieldConfig(key: 'category_id', label: 'ক্যাটাগরি আইডি', numeric: true),
      FormFieldConfig(key: 'title', label: 'শিরোনাম'),
      FormFieldConfig(key: 'price', label: 'মূল্য', numeric: true),
      FormFieldConfig(key: 'description', label: 'বিবরণ', required: false),
      FormFieldConfig(key: 'location', label: 'লোকেশন', required: false),
    ],
  ),
  ActionModule(
    title: 'প্রোপার্টি যোগ করুন',
    subtitle: 'ভাড়া/বিক্রয় সম্পত্তি পোস্ট',
    endpoint: '/properties/add',
    icon: Icons.home_work_outlined,
    allowImages: true,
    mediaTargetType: 'property',
    mediaSection: 'property',
    mediaResponseKey: 'property',
    fields: [
      FormFieldConfig(key: 'title', label: 'শিরোনাম'),
      FormFieldConfig(key: 'type', label: 'টাইপ'),
      FormFieldConfig(key: 'price', label: 'মূল্য', numeric: true),
      FormFieldConfig(key: 'location', label: 'লোকেশন', required: false),
      FormFieldConfig(key: 'description', label: 'বিবরণ', required: false),
      FormFieldConfig(key: 'contact', label: 'যোগাযোগ', required: false),
    ],
  ),
  ActionModule(
    title: 'চাকরি পোস্ট করুন',
    subtitle: 'লোকাল জব সার্কুলার',
    endpoint: '/jobs/post',
    icon: Icons.work_outline,
    allowImages: true,
    mediaTargetType: 'job_post',
    mediaSection: 'jobs',
    mediaResponseKey: 'job',
    fields: [
      FormFieldConfig(key: 'title', label: 'পদের নাম'),
      FormFieldConfig(key: 'company', label: 'কোম্পানি'),
      FormFieldConfig(key: 'description', label: 'বিবরণ'),
      FormFieldConfig(key: 'salary', label: 'বেতন', required: false),
      FormFieldConfig(key: 'location', label: 'লোকেশন', required: false),
      FormFieldConfig(key: 'type', label: 'টাইপ', required: false),
      FormFieldConfig(key: 'contact', label: 'যোগাযোগ', required: false),
    ],
  ),
  ActionModule(
    title: 'রক্তদাতা রেজিস্ট্রেশন',
    subtitle: 'ডোনার প্রোফাইল আপডেট',
    endpoint: '/blood-donor/register',
    icon: Icons.volunteer_activism,
    fields: [
      FormFieldConfig(key: 'blood_group', label: 'রক্তের গ্রুপ'),
      FormFieldConfig(key: 'last_donation', label: 'শেষ ডোনেশন তারিখ', required: false, hint: 'YYYY-MM-DD'),
      FormFieldConfig(key: 'available', label: 'এভেইলেবল (1/0)', required: false, numeric: true),
      FormFieldConfig(key: 'location', label: 'লোকেশন', required: false),
    ],
  ),
  ActionModule(title: 'ব্যবসা যোগ করুন', subtitle: 'দোকান, অফিস বা সার্ভিস তালিকাভুক্ত করুন', endpoint: '/businesses/add', icon: Icons.add_business_outlined, fields: []),
  ActionModule(title: 'কর্মী প্রোফাইল', subtitle: 'নিজের কাজ ও যোগাযোগ তথ্য যোগ করুন', endpoint: '/workers/add', icon: Icons.engineering_outlined, fields: []),
  ActionModule(title: 'রক্তের অনুরোধ', subtitle: 'জরুরি রক্তের প্রয়োজন জানিয়ে দিন', endpoint: '/blood-requests/add', icon: Icons.bloodtype_outlined, fields: []),
  ActionModule(title: 'কাজ খুঁজছি', subtitle: 'নিজের অভিজ্ঞতা দিয়ে চাকরির পোস্ট দিন', endpoint: '/jobs/seeking', icon: Icons.person_search_outlined, fields: []),
  ActionModule(title: 'ডাক্তার প্রোফাইল', subtitle: 'চেম্বার, ফি ও সময়সূচি যোগ করুন', endpoint: '/doctors/register', icon: Icons.medical_services_outlined, fields: []),
  ActionModule(title: 'হাসপাতাল যোগ', subtitle: 'হাসপাতাল, ক্লিনিক বা ডায়াগনস্টিক সেন্টার', endpoint: '/hospitals/register', icon: Icons.local_hospital_outlined, fields: []),
  ActionModule(title: 'রেস্টুরেন্ট যোগ', subtitle: 'খাবারের দোকান বা রেস্টুরেন্ট তালিকাভুক্ত করুন', endpoint: '/restaurants/register', icon: Icons.restaurant_outlined, fields: []),
  ActionModule(title: 'হোটেল যোগ', subtitle: 'হোটেল, রিসোর্ট বা গেস্ট হাউস', endpoint: '/hotels/register', icon: Icons.hotel_outlined, fields: []),
  ActionModule(title: 'শিক্ষা প্রতিষ্ঠান', subtitle: 'স্কুল, কলেজ, মাদ্রাসা বা কোচিং যোগ করুন', endpoint: '/education/register', icon: Icons.school_outlined, fields: []),
  ActionModule(title: 'গাড়ি ভাড়া যোগ', subtitle: 'কার, সিএনজি, অটো, ভ্যান বা বাইক সার্ভিস', endpoint: '/car-rentals/register', icon: Icons.directions_car_outlined, fields: []),
  ActionModule(title: 'লঞ্চ তথ্য যোগ', subtitle: 'রুট, ছাড়ার সময়, ভাড়া ও হটলাইন যোগ করুন', endpoint: '/launches/register', icon: Icons.directions_boat_filled_outlined, fields: []),
  ActionModule(title: 'কুরিয়ার যোগ', subtitle: 'কুরিয়ার অফিস ও ডেলিভারি তথ্য যোগ করুন', endpoint: '/couriers/register', icon: Icons.local_shipping_outlined, fields: []),
  ActionModule(title: 'শিক্ষক/টিউটর', subtitle: 'টিউশন প্রোফাইল বা শিক্ষক তথ্য যোগ করুন', endpoint: '/teachers/register', icon: Icons.co_present_outlined, fields: []),
];
