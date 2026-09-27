// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GarageMate';

  @override
  String get tagline => 'Manage Your Garage Easily';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी (Hindi)';

  @override
  String get chooseLanguage => 'Choose Your Language';

  @override
  String get chooseLanguageSubtitle =>
      'You can change this anytime in Settings';

  @override
  String get continueButton => 'Continue';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get customers => 'Customers';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get services => 'Services';

  @override
  String get more => 'More';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get customer => 'Customer';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get service => 'Service';

  @override
  String get reminder => 'Reminder';

  @override
  String get todayTasks => 'Today\'s Tasks';

  @override
  String get servicesDueToday => 'Services Due Today';

  @override
  String get paymentsPending => 'Payments Pending';

  @override
  String get remindersDueToday => 'Reminders Due Today';

  @override
  String get noTasksToday => 'No tasks for today';

  @override
  String get viewAll => 'View All';

  @override
  String get upcomingReminders => 'Upcoming Reminders';

  @override
  String get recentServices => 'Recent Services';

  @override
  String get noUpcomingReminders => 'No upcoming reminders';

  @override
  String get noRecentServices => 'No recent services';

  @override
  String get moreTitle => 'More';

  @override
  String get messageAutomation => 'Message Automation';

  @override
  String get messageAutomationSubtitle =>
      'Automatically manage service reminders and special offers.';

  @override
  String get sendOnWhatsApp => 'Send on WhatsApp';

  @override
  String get sendOnWhatsAppSubtitle =>
      'Send invoices, offers and payment reminders to customers.';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionSubtitle => 'Manage your plan and usage';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get notProvided => 'Not provided';

  @override
  String get notSet => 'Not set';

  @override
  String get ownerInformation => 'Owner Information';

  @override
  String get garageInformation => 'Garage Information';

  @override
  String get account => 'Account';

  @override
  String get garageName => 'Garage Name';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get garagePhone => 'Garage Phone';

  @override
  String get garageEmail => 'Garage Email';

  @override
  String get garageStatus => 'Garage Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get subscriptionPlan => 'Subscription Plan';

  @override
  String get subscriptionExpiry => 'Subscription Expiry';

  @override
  String get upgradeYourPlan => 'Upgrade Your Plan';

  @override
  String get upgradeSubtitle =>
      'Get more WhatsApp messages, custom invoices, and advanced features.';

  @override
  String get viewPlans => 'View Plans';

  @override
  String get choosePlan => 'Choose Plan';

  @override
  String get upgradeBeforeTrialEnds => 'Upgrade Before Trial Ends';

  @override
  String trialEndsOn(Object date) {
    return 'Trial ends on $date';
  }

  @override
  String get upgradeToBusiness => 'Upgrade to Business';

  @override
  String get upgradeToBusinessSubtitle =>
      'Get 2000 WhatsApp messages, 10 staff users, and more.';

  @override
  String get free => 'Free';

  @override
  String get pro => 'Pro';

  @override
  String get business => 'Business';

  @override
  String get foundersPlan => 'Founder\'s Plan';

  @override
  String get proTrial => 'Pro (Trial)';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get whatsAppMessages => 'WhatsApp Messages';

  @override
  String messagesRemaining(Object count) {
    return '$count messages remaining this month';
  }

  @override
  String get messagesLimitReached => 'Limit reached! Upgrade to send more.';

  @override
  String get limitReached => 'Limit Reached';

  @override
  String limitReachedMessage(Object limit) {
    return 'You have used all $limit WhatsApp messages this month. Upgrade your plan to send more.';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get markAsCompleted => 'Mark as Completed';

  @override
  String get markAsCompletedSuccess => 'Reminder marked as completed.';

  @override
  String get deleteReminderConfirm =>
      'Are you sure you want to delete this reminder? This action cannot be undone.';

  @override
  String get reminderDeleted => 'Reminder deleted successfully';

  @override
  String get selectMultiple => 'Select Multiple';

  @override
  String get deleteCompleted => 'Delete Completed';

  @override
  String get selectAll => 'Select All';

  @override
  String get clear => 'Clear';

  @override
  String selected(Object count) {
    return '$count selected';
  }

  @override
  String deleteXReminders(Object count) {
    return 'Delete $count Reminders';
  }

  @override
  String deleteXReminder(Object count) {
    return 'Delete $count Reminder';
  }

  @override
  String get selectRemindersToDelete => 'Select reminders to delete';

  @override
  String get saveService => 'Save Service';

  @override
  String get updateService => 'Update Service';

  @override
  String get addService => 'Add Service';

  @override
  String get editService => 'Edit Service';

  @override
  String get serviceSaved => 'Service saved successfully';

  @override
  String get serviceUpdated => 'Service updated successfully';

  @override
  String get serviceDeleted => 'Service deleted successfully';

  @override
  String get serviceSavedWhatsApp =>
      'Service saved • Invoice generated • Sent on WhatsApp';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get customerSaved => 'Customer saved successfully';

  @override
  String get customerUpdated => 'Customer updated successfully';

  @override
  String get customerDeleted => 'Customer deleted successfully';

  @override
  String get addVehicle => 'Add Vehicle';

  @override
  String get editVehicle => 'Edit Vehicle';

  @override
  String get vehicleSaved => 'Vehicle saved successfully';

  @override
  String get vehicleUpdated => 'Vehicle updated successfully';

  @override
  String get vehicleDeleted => 'Vehicle deleted successfully';

  @override
  String get error => 'Error';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get unableToLoad => 'Unable to load data';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get upgradeRequestSubmitted =>
      'Upgrade request submitted. Our team will contact you soon.';

  @override
  String get openingWhatsApp => 'Opening WhatsApp...';

  @override
  String get todayTasksTitle => 'Today\'s Tasks';

  @override
  String get allCaughtUp => 'All caught up! 🎉';

  @override
  String get upcomingThisWeek => 'Upcoming This Week';

  @override
  String get viewDetails => 'View Details';

  @override
  String get markDone => 'Mark Done';

  @override
  String get sendWhatsApp => 'Send WhatsApp';

  @override
  String get callCustomer => 'Call Customer';
}
