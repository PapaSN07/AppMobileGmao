import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/ot_service.dart';

/// OTService sans réseau : les tests d'écran ne doivent pas appeler Coswin.
class FakeOTService extends OTService {
  FakeOTService() : super(ApiService());

  @override
  Future<OTReferentials> getReferentials() async => OTReferentials.empty;

  @override
  Future<OTPageResult> getOrdersPage({
    String scope = 'mine',
    String? supervisorCode,
    String? requestEntity,
    bool excludeClosed = true,
    int? upToCode,
    int? targetYear,
  }) async => const OTPageResult(workorders: [], hasMore: false);
}
