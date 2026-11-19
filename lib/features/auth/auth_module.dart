// Export Domain Models & Repositories
export 'domain/models/auth_session.dart';
export 'domain/models/logout_result.dart';
export 'domain/models/user.dart';
export 'domain/repositories/account_local_data_gateway.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/token_provider.dart';

// Export Data Layer
export 'data/datasources/auth_local_data_source.dart';
export 'data/datasources/auth_remote_data_source.dart';
export 'data/datasources/composite_account_local_data_gateway.dart';
export 'data/datasources/mock_auth_remote_data_source.dart';
export 'data/repositories/auth_repository_impl.dart';
export 'data/services/profile_cache_service.dart';
export 'data/services/secure_storage_service.dart';

// Export Presentation / Controller
export 'presentation/auth_scope.dart';
export 'presentation/controllers/auth_controller.dart';

import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/composite_account_local_data_gateway.dart';
import 'data/datasources/mock_auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/services/profile_cache_service.dart';
import 'data/services/secure_storage_service.dart';
import 'domain/repositories/account_local_data_gateway.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/controllers/auth_controller.dart';

/// Container dan inisialisasi dependensi modul autentikasi ASPAL.
class AuthModule {
  AuthModule._();

  static AuthRepository? _repository;
  static AuthController? _controller;
  static final CompositeAccountLocalDataGateway gateway =
      CompositeAccountLocalDataGateway();

  static AuthRepository get repository {
    if (_repository == null) {
      init();
    }
    return _repository!;
  }

  static AuthController get controller {
    if (_controller == null) {
      init();
    }
    return _controller!;
  }

  static void init({
    AuthRepository? customRepository,
    AuthController? customController,
    AccountLocalDataGateway? customGateway,
  }) {
    if (customGateway != null) {
      gateway.clearGateways();
      gateway.registerGateway(customGateway);
    }

    if (customRepository != null && customController != null) {
      _repository = customRepository;
      _controller = customController;
      return;
    }

    final secureStorage = SecureStorageService();
    final profileCache = ProfileCacheService();
    final localDataSource = AuthLocalDataSourceImpl(
      secureStorageService: secureStorage,
      profileCacheService: profileCache,
    );
    final remoteDataSource = MockAuthRemoteDataSource();

    _repository = customRepository ??
        AuthRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: remoteDataSource,
        );

    _controller = customController ??
        AuthController(
          authRepository: _repository!,
          accountLocalDataGateway: customGateway ?? gateway,
        );
  }

  static void reset() {
    _repository = null;
    _controller = null;
    gateway.clearGateways();
  }
}

