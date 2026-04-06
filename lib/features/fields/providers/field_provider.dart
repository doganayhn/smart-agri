import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import 'field_model.dart';
import '../../auth/providers/auth_provider.dart';

class FieldState {
  final bool isLoading;
  final List<FieldModel> fields;
  final String? error;

  FieldState({this.isLoading = false, this.fields = const [], this.error});

  FieldState copyWith({bool? isLoading, List<FieldModel>? fields, String? error}) {
    return FieldState(
      isLoading: isLoading ?? this.isLoading,
      fields: fields ?? this.fields,
      error: error, // Reset error on new state
    );
  }
}

class FieldNotifier extends Notifier<FieldState> {
  @override
  FieldState build() {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      final wasAuth = previous?.asData?.value.isAuthenticated ?? false;
      final isAuth = next.asData?.value.isAuthenticated ?? false;
      if (!wasAuth && isAuth) {
        Future.microtask(() => loadFields());
      }
    });

    return FieldState();
  }

  Future<void> loadFields() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/v1/fields');
      final data = response.data as List;
      final fields = data.map((json) => FieldModel.fromJson(json)).toList();
      state = state.copyWith(isLoading: false, fields: fields);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message ?? 'Failed to load fields';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error occurred');
    }
  }

  Future<void> logIrrigation(String fieldId, double amountLiters) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/v1/fields/$fieldId/irrigation-logs',
        data: {
          'amountLiters': amountLiters,
        },
      );
      // Reload fields to get updated recommendation status
      await loadFields();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message ?? 'Failed to log irrigation';
      state = state.copyWith(error: msg);
      // Re-throw if a caller wants to catch and show a snackbar
      throw Exception(msg);
    } catch (e) {
      state = state.copyWith(error: 'Unexpected error occurred');
      throw Exception('Unexpected error occurred');
    }
  }
}

final fieldNotifierProvider = NotifierProvider<FieldNotifier, FieldState>(() {
  return FieldNotifier();
});
