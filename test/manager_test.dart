import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clash_forge/managers/subscription_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionManager Tests', () {
    late SubscriptionManager manager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      manager = SubscriptionManager();
      return manager.init();
    });

    test('Initial state is empty', () {
      expect(manager.subscriptions, isEmpty);
    });

    test('Add subscription', () async {
      await manager.addSubscription('https://example.com');
      expect(manager.subscriptions.length, 1);
      expect(manager.subscriptions.first, 'https://example.com');
    });

    test('Add duplicate subscription (allowed by current logic)', () async {
      await manager.addSubscription('https://example.com');
      await manager.addSubscription('https://example.com');
      expect(manager.subscriptions.length, 2);
    });

    test('Remove subscription', () async {
      await manager.addSubscription('https://example.com');
      await manager.deleteSubscription(0);
      expect(manager.subscriptions, isEmpty);
    });

    test('Edit subscription', () async {
      await manager.addSubscription('https://example.com');
      await manager.editSubscription(0, 'https://new.com');
      expect(manager.subscriptions.first, 'https://new.com');
    });

    test('Clear all subscriptions', () async {
      await manager.addSubscription('https://example.com');
      await manager.addSubscription('https://example2.com');
      await manager.deleteAllSubscriptions();
      expect(manager.subscriptions, isEmpty);
    });
  });
}
