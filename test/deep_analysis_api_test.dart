import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kriptoanaliz/data/deep_analysis_api.dart';
import 'package:kriptoanaliz/data/plan_errors.dart';
import 'package:kriptoanaliz/models/deep_analysis_job.dart';

void main() {
  test('202 start response parses the queued job', () {
    final job = DeepAnalysisApi.parseStartResponse(
      http.Response(
        '{"job":{"id":12,"status":"queued","coin_id":3,"symbol":"BTCUSDT",'
        '"timeframe":"4h","credit_cost":20,"credit_balance":80,'
        '"created_at":"2026-10-19T10:00:00Z"}}',
        202,
      ),
    );
    expect(job.id, 12);
    expect(job.status, DeepAnalysisJobStatus.queued);
    expect(job.creditBalance, 80);
    expect(job.creditCost, 20);
    expect(job.analysis, isNull);
  });

  test('error statuses map to distinct exceptions', () {
    expect(
      () => DeepAnalysisApi.parseStartResponse(
        http.Response('{"message":"already running"}', 409),
      ),
      throwsA(
        isA<DeepAnalysisInProgressException>().having(
          (e) => e.message,
          'message',
          'already running',
        ),
      ),
    );
    expect(
      () => DeepAnalysisApi.parseStartResponse(http.Response('{}', 402)),
      throwsA(isA<InsufficientCreditException>()),
    );
    expect(
      () => DeepAnalysisApi.parseStartResponse(
        http.Response('{"code":"pro_required"}', 403),
      ),
      throwsA(isA<ProRequiredException>()),
    );
    expect(
      () => DeepAnalysisApi.parseStartResponse(http.Response('{}', 502)),
      throwsA(isA<DeepAnalysisException>()),
    );
  });

  test('completed job response carries the analysis', () {
    final job = DeepAnalysisApi.parseJobResponse(
      http.Response(
        '{"id":12,"status":"completed","symbol":"BTCUSDT","timeframe":"4h",'
        '"credit_cost":20,"credit_balance":80,'
        '"analysis":{"id":5,"result":"text","structured":null,"credit_cost":20,'
        '"created_at":"2026-10-19T10:01:00Z"},"error_code":null}',
        200,
      ),
    );
    expect(job.status, DeepAnalysisJobStatus.completed);
    expect(job.analysis!.id, 5);
    expect(job.analysis!.result, 'text');
    expect(job.errorCode, isNull);
  });

  test('failed job exposes error_code; unknown status counts as failed', () {
    final job = DeepAnalysisApi.parseJobResponse(
      http.Response(
        '{"id":1,"status":"failed","credit_balance":100,"analysis":null,'
        '"error_code":"timeout"}',
        200,
      ),
    );
    expect(job.status, DeepAnalysisJobStatus.failed);
    expect(job.errorCode, 'timeout');
    expect(job.creditBalance, 100);
    expect(DeepAnalysisJobStatus.parse('weird'), DeepAnalysisJobStatus.failed);
  });

  test('404 on status maps to not-found', () {
    expect(
      () => DeepAnalysisApi.parseJobResponse(http.Response('', 404)),
      throwsA(isA<DeepAnalysisJobNotFoundException>()),
    );
  });
}
