import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/rating/domain/rating_repository.dart';
import 'package:rijiki/features/rating/domain/testimonial.dart';

class MockRatingRepository implements RatingRepository {
  const MockRatingRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  @override
  Future<List<Testimonial>> fetchFeaturedTestimonials() {
    final now = DateTime.now();
    return scenario.resolve<List<Testimonial>>(
      empty: const [],
      data: [
        Testimonial(
          id: 'rt-1',
          customerName: 'Rina A.',
          ratingValue: 5,
          serviceName: 'Deep Clean',
          comment:
              'Sneakers putihku balik kayak baru, sole yang menguning juga ilang. Dijemput tepat waktu.',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        Testimonial(
          id: 'rt-2',
          customerName: 'Dimas P.',
          ratingValue: 5,
          serviceName: 'Fast Clean',
          comment: 'Pagi dijemput, besok sore udah sampai rumah. Mantap buat yang buru-buru.',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        Testimonial(
          id: 'rt-3',
          customerName: 'Salsa M.',
          ratingValue: 4,
          serviceName: 'Glue Repair Plus',
          comment: 'Sol sepatu yang lepas udah rapi lagi dan sekalian dicuci. Harganya masuk akal.',
          createdAt: now.subtract(const Duration(days: 9)),
        ),
        Testimonial(
          id: 'rt-4',
          customerName: 'Fajar R.',
          ratingValue: 5,
          serviceName: 'Sepatu Gunung',
          comment: 'Sepatu trekking penuh lumpur beres bersih, tali dan insole juga diurus.',
          createdAt: now.subtract(const Duration(days: 12)),
        ),
      ],
    );
  }
}
