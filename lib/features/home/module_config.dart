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

const homeServiceModules = <ReadModule>[
  ReadModule(title: 'কর্মী খুঁজুন', subtitle: 'ইলেকট্রিশিয়ান, প্লাম্বার ইত্যাদি', endpoint: '/workers', icon: Icons.engineering, section: 'সেবা', layout: ModuleLayout.directory, useCategoryView: true),
  ReadModule(title: 'ব্যবসা ডিরেক্টরি', subtitle: 'লোকাল দোকান ও সেবা', endpoint: '/businesses', icon: Icons.business, section: 'মার্কেট', layout: ModuleLayout.business),
  ReadModule(title: 'মার্কেটপ্লেস', subtitle: 'বাই-সেল পণ্য', endpoint: '/items', icon: Icons.storefront, section: 'মার্কেট', layout: ModuleLayout.marketplace),
  ReadModule(title: 'চাকরি', subtitle: 'লোকাল জব পোস্ট', endpoint: '/jobs', icon: Icons.work, section: 'ক্যারিয়ার', layout: ModuleLayout.jobs),
  ReadModule(title: 'প্রোপার্টি', subtitle: 'ভাড়া ও বিক্রয়', endpoint: '/properties', icon: Icons.home_work, section: 'মার্কেট', layout: ModuleLayout.property),
  ReadModule(title: 'রক্তদাতা', subtitle: 'জরুরি ডোনার', endpoint: '/blood-donors', icon: Icons.bloodtype, section: 'জরুরি', layout: ModuleLayout.blood),
  ReadModule(title: 'জরুরি নম্বর', subtitle: 'পুলিশ, ফায়ার, অ্যাম্বুলেন্স', endpoint: '/emergency', icon: Icons.local_hospital, section: 'জরুরি', layout: ModuleLayout.emergency),
  ReadModule(title: 'সংবাদ', subtitle: 'জেলার আপডেট', endpoint: '/news', icon: Icons.newspaper, section: 'কমিউনিটি', layout: ModuleLayout.news),
  ReadModule(title: 'নোটিশ', subtitle: 'গুরুত্বপূর্ণ ঘোষণা', endpoint: '/notices', icon: Icons.campaign, section: 'কমিউনিটি', layout: ModuleLayout.notices),
  ReadModule(title: 'কর্মী ক্যাটাগরি', subtitle: 'পেশাভিত্তিক তালিকা', endpoint: '/worker/categories', icon: Icons.category, section: 'সেবা', layout: ModuleLayout.categories),
  ReadModule(title: 'হেল্প সেন্টার', subtitle: 'সহায়তা ও নির্দেশনা', endpoint: '/emergency', icon: Icons.support_agent, section: 'কমিউনিটি', layout: ModuleLayout.emergency),
];

const serviceModules = <ReadModule>[
  ReadModule(title: 'কর্মী তালিকা', subtitle: 'লোকাল স্কিলড ওয়ার্কার', endpoint: '/workers', icon: Icons.engineering, section: 'সেবা', layout: ModuleLayout.directory, useCategoryView: true),
  ReadModule(title: 'রক্তদাতা', subtitle: 'জরুরি রক্তদাতা খুঁজুন', endpoint: '/blood-donors', icon: Icons.bloodtype, section: 'জরুরি', layout: ModuleLayout.blood),
  ReadModule(title: 'জরুরি নম্বর', subtitle: 'পুলিশ, ফায়ার, অ্যাম্বুলেন্স', endpoint: '/emergency', icon: Icons.local_hospital, section: 'জরুরি', layout: ModuleLayout.emergency),
];

const marketplaceModules = <ReadModule>[
  ReadModule(title: 'মার্কেটপ্লেস', subtitle: 'বাই-সেল তালিকা', endpoint: '/items', icon: Icons.storefront, section: 'মার্কেট', layout: ModuleLayout.marketplace),
  ReadModule(title: 'ব্যবসা ডিরেক্টরি', subtitle: 'লোকাল ব্যবসা', endpoint: '/businesses', icon: Icons.business, section: 'মার্কেট', layout: ModuleLayout.business),
  ReadModule(title: 'প্রোপার্টি', subtitle: 'ভাড়া/বিক্রয় সম্পত্তি', endpoint: '/properties', icon: Icons.home_work, section: 'মার্কেট', layout: ModuleLayout.property),
  ReadModule(title: 'চাকরি', subtitle: 'লোকাল জব পোস্ট', endpoint: '/jobs', icon: Icons.work, section: 'ক্যারিয়ার', layout: ModuleLayout.jobs),
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
    subtitle: 'ভাড়া/বিক্রয় সম্পত্তি পোস্ট',
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
];
