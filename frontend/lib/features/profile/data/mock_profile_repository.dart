import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/features/profile/domain/profile_history.dart';
import 'package:rijiki/features/profile/domain/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  static const Duration _latency = Duration(milliseconds: 700);

  @override
  Future<AppUser> saveCustomerProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(_latency);
    return currentUser.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      defaultAddress: address,
      defaultLat: latitude,
      defaultLng: longitude,
      profileCompleted: true,
    );
  }

  @override
  Future<AppUser> saveProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
  }) async {
    await Future<void>.delayed(_latency);
    return currentUser.copyWith(fullName: fullName, phoneNumber: phoneNumber);
  }

  @override
  Future<MyShoePage> fetchMyShoes({
    required int page,
    required int limit,
  }) async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return MyShoePage(
      items: [
        MyShoe(
          id: 'mock-shoe-1',
          orderId: 'mock-order-1',
          orderNumber: 'RJK-1001-001',
          orderStatus: 'completed',
          serviceName: 'Deep Cleaning',
          shoeBrand: 'Nike Air Force 1',
          quantity: 1,
          orderDate: now.subtract(const Duration(days: 12)),
        ),
        MyShoe(
          id: 'mock-shoe-2',
          orderId: 'mock-order-2',
          orderNumber: 'RJK-1002-001',
          orderStatus: 'completed',
          serviceName: 'Fast Cleaning',
          shoeBrand: 'Adidas Samba',
          quantity: 1,
          orderDate: now.subtract(const Duration(days: 40)),
        ),
      ],
      total: 2,
    );
  }

  @override
  Future<CustomerRatingPage> fetchMyRatings({
    required int page,
    required int limit,
  }) async {
    await Future<void>.delayed(_latency);
    return CustomerRatingPage(
      items: [
        CustomerRating(
          id: 'mock-rating-1',
          orderId: 'mock-order-1',
          orderNumber: 'RJK-1001-001',
          workerName: 'Siti Worker',
          ratingValue: 5,
          comment: 'Bersih banget, wanginya enak.',
          isFeatured: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
      total: 1,
      average: 5,
    );
  }

  @override
  Future<AppUser> uploadAvatar({
    required AppUser currentUser,
    required String filePath,
  }) async {
    await Future<void>.delayed(_latency);
    // Mock: pakai path lokal sebagai "URL" supaya fotonya langsung tampil.
    return currentUser.copyWith(avatarUrl: filePath);
  }
}
