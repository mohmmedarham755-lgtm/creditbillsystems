import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/card_model.dart';
import '../domain/card_repository.dart';

/// State controller for a user's credit cards.
class CardProvider extends ChangeNotifier {
  final CardRepository? _cardRepository;
  final List<CardModel> _cards = [];

  AuthProvider? _authProvider;
  StreamSubscription<List<CardModel>>? _cardsSubscription;
  String? _authenticatedUserId;
  int _userGeneration = 0;
  int _streamGeneration = 0;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _updatingCardId;
  String? _deletingCardId;
  bool _isPortfolioLoading = false;
  double _totalCreditLimit = 0.0;
  double _totalCurrentBalance = 0.0;
  String? _errorMessage;
  String? _updateErrorMessage;
  String? _deleteErrorMessage;
  String? _portfolioErrorMessage;
  bool _disposed = false;

  CardProvider({required CardRepository cardRepository, AuthProvider? authProvider})
    : _cardRepository = cardRepository {
    bindAuthProvider(authProvider);
  }

  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get updatingCardId => _updatingCardId;
  String? get deletingCardId => _deletingCardId;
  bool get isPortfolioLoading => _isPortfolioLoading;
  bool get hasAuthenticatedUser =>
      _authenticatedUserId != null && _authenticatedUserId!.isNotEmpty;
  double get totalCreditLimit => _totalCreditLimit;
  double get totalCurrentBalance => _totalCurrentBalance;
  String? get errorMessage => _errorMessage;
  String? get updateErrorMessage => _updateErrorMessage;
  String? get deleteErrorMessage => _deleteErrorMessage;
  String? get portfolioErrorMessage => _portfolioErrorMessage;
  List<CardModel> get cards => List.unmodifiable(_cards);

  void bindAuthProvider(AuthProvider? authProvider) {
    if (identical(_authProvider, authProvider)) return;
    _authProvider?.removeListener(_handleAuthChange);
    _authProvider = authProvider;
    _setAuthenticatedUserId(authProvider?.userId);
    authProvider?.addListener(_handleAuthChange);
    if (authProvider?.userId == _authenticatedUserId &&
        hasAuthenticatedUser &&
        _cardsSubscription == null &&
        _cardRepository != null) {
      _subscribeToCards();
    }
  }

  void _handleAuthChange() {
    _setAuthenticatedUserId(_authProvider?.userId);
  }

  void _setAuthenticatedUserId(String? userId) {
    if (_authenticatedUserId == userId) return;
    _authenticatedUserId = userId;
    _userGeneration++;
    _streamGeneration++;
    _cardsSubscription?.cancel();
    _cardsSubscription = null;
    _cards.clear();
    _totalCreditLimit = 0;
    _totalCurrentBalance = 0;
    _errorMessage = null;
    _updateErrorMessage = null;
    _deleteErrorMessage = null;
    _portfolioErrorMessage = null;
    _isLoading = false;
    _isUpdating = false;
    _isDeleting = false;
    _updatingCardId = null;
    _deletingCardId = null;
    _isPortfolioLoading = false;
    if (hasAuthenticatedUser) {
      _subscribeToCards();
      return;
    }
    notifyListeners();
  }

  void _subscribeToCards() {
    final userId = _authenticatedUserId;
    if (userId == null || userId.isEmpty) return;
    final repository = _cardRepository;
    final generation = ++_streamGeneration;
    _cardsSubscription?.cancel();
    _cardsSubscription = null;
    _portfolioErrorMessage = null;
    _isPortfolioLoading = repository != null;
    if (repository == null) {
      _portfolioErrorMessage = 'Card storage is unavailable.';
      notifyListeners();
      return;
    }
    notifyListeners();
    try {
      _cardsSubscription = repository
          .watchCards(userId: userId)
          .listen(
            (cards) {
              if (!_isCurrentStream(generation, userId)) return;
              _cards
                ..clear()
                ..addAll(cards);
              _recalculateTotals();
              _isPortfolioLoading = false;
              _portfolioErrorMessage = null;
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!_isCurrentStream(generation, userId)) return;
              _isPortfolioLoading = false;
              _portfolioErrorMessage = error is AppException
                  ? error.message
                  : 'Something went wrong while loading cards.';
              notifyListeners();
            },
            onDone: () {
              if (!_isCurrentStream(generation, userId)) return;
              _isPortfolioLoading = false;
              notifyListeners();
            },
          );
    } catch (error) {
      if (_isCurrentStream(generation, userId)) {
        _isPortfolioLoading = false;
        _portfolioErrorMessage = error is AppException
            ? error.message
            : 'Something went wrong while loading cards.';
        notifyListeners();
      }
    }
  }

  bool _isCurrentStream(int generation, String userId) =>
      !_disposed &&
      generation == _streamGeneration &&
      userId == _authenticatedUserId;

  void _recalculateTotals() {
    _totalCreditLimit = _cards.fold(
      0,
      (total, card) => total + card.creditLimit,
    );
    _totalCurrentBalance = _cards.fold(
      0,
      (total, card) => total + card.currentBalance,
    );
  }

  /// Re-subscribes to the current authenticated user's card stream.
  void retryPortfolio() {
    if (!hasAuthenticatedUser) return;
    _subscribeToCards();
  }

  void updateTotals({required double limit, required double balance}) {
    _totalCreditLimit = limit;
    _totalCurrentBalance = balance;
    notifyListeners();
  }

  /// Persists a card for the authenticated user and tracks the returned model.
  Future<bool> addCard({
    required String? userId,
    required CardModel card,
  }) async {
    if (_disposed) return false;
    _errorMessage = null;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'You must be signed in to add a card.';
      notifyListeners();
      return false;
    }
    if (_authProvider == null) {
      if (_authenticatedUserId == null) {
        _authenticatedUserId = userId;
      } else if (_authenticatedUserId != userId) {
        _setAuthenticatedUserId(userId);
      }
    } else if (_authenticatedUserId != userId) {
      _errorMessage = 'You must be signed in to add a card.';
      notifyListeners();
      return false;
    }
    final repository = _cardRepository;
    if (repository == null) {
      _errorMessage = 'Card storage is unavailable.';
      notifyListeners();
      return false;
    }

    final requestGeneration = _userGeneration;
    _isLoading = true;
    notifyListeners();
    try {
      final savedCard = await repository.createCard(userId: userId, card: card);
      if (_disposed ||
          requestGeneration != _userGeneration ||
          userId != _authenticatedUserId) {
        return false;
      }
      final existingIndex = _cards.indexWhere(
        (item) => item.id == savedCard.id,
      );
      final previousCard = existingIndex == -1 ? null : _cards[existingIndex];
      if (existingIndex == -1) {
        _cards.add(savedCard);
      } else {
        _cards[existingIndex] = savedCard;
      }
      _totalCreditLimit +=
          savedCard.creditLimit - (previousCard?.creditLimit ?? 0);
      _totalCurrentBalance +=
          savedCard.currentBalance - (previousCard?.currentBalance ?? 0);
      return true;
    } on AppException catch (error) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = 'Something went wrong while saving the card.';
      }
      return false;
    } finally {
      if (!_disposed && requestGeneration == _userGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Updates editable card details for the currently authenticated user.
  ///
  /// The repository preserves the latest persisted balance atomically; the
  /// portfolio stream remains the source of refreshed card data and totals.
  Future<bool> updateCard({required CardModel card}) async {
    if (_disposed || _isUpdating || _isDeleting) return false;
    _updateErrorMessage = null;
    final userId = _currentAuthenticatedUserId;
    if (userId == null) {
      _updateErrorMessage = 'You must be signed in to update a card.';
      notifyListeners();
      return false;
    }
    if (card.id.isEmpty) {
      _updateErrorMessage = 'The selected card could not be found.';
      notifyListeners();
      return false;
    }
    final repository = _cardRepository;
    if (repository == null) {
      _updateErrorMessage = 'Card storage is unavailable.';
      notifyListeners();
      return false;
    }

    final requestGeneration = _userGeneration;
    _isUpdating = true;
    _updatingCardId = card.id;
    notifyListeners();
    try {
      await repository.updateCard(userId: userId, card: card);
      return _isCurrentOperation(requestGeneration, userId);
    } on AppException catch (error) {
      if (_isCurrentOperation(requestGeneration, userId)) {
        _updateErrorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (_isCurrentOperation(requestGeneration, userId)) {
        _updateErrorMessage = 'Something went wrong while updating the card.';
      }
      return false;
    } finally {
      if (_isCurrentOperation(requestGeneration, userId)) {
        _isUpdating = false;
        _updatingCardId = null;
        notifyListeners();
      }
    }
  }

  /// Deletes a card for the currently authenticated user after UI confirmation.
  Future<bool> deleteCard({required String cardId}) async {
    if (_disposed || _isUpdating || _isDeleting) return false;
    _deleteErrorMessage = null;
    final userId = _currentAuthenticatedUserId;
    if (userId == null) {
      _deleteErrorMessage = 'You must be signed in to delete a card.';
      notifyListeners();
      return false;
    }
    if (cardId.isEmpty) {
      _deleteErrorMessage = 'The selected card could not be found.';
      notifyListeners();
      return false;
    }
    final repository = _cardRepository;
    if (repository == null) {
      _deleteErrorMessage = 'Card storage is unavailable.';
      notifyListeners();
      return false;
    }

    final requestGeneration = _userGeneration;
    _isDeleting = true;
    _deletingCardId = cardId;
    notifyListeners();
    try {
      await repository.deleteCard(userId: userId, cardId: cardId);
      return _isCurrentOperation(requestGeneration, userId);
    } on AppException catch (error) {
      if (_isCurrentOperation(requestGeneration, userId)) {
        _deleteErrorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (_isCurrentOperation(requestGeneration, userId)) {
        _deleteErrorMessage = 'Something went wrong while deleting the card.';
      }
      return false;
    } finally {
      if (_isCurrentOperation(requestGeneration, userId)) {
        _isDeleting = false;
        _deletingCardId = null;
        notifyListeners();
      }
    }
  }

  String? get _currentAuthenticatedUserId {
    final authProvider = _authProvider;
    if (authProvider == null ||
        authProvider.userId == null ||
        authProvider.userId!.isEmpty ||
        authProvider.userId != _authenticatedUserId) {
      return null;
    }
    return authProvider.userId;
  }

  bool _isCurrentOperation(int generation, String userId) =>
      !_disposed &&
      generation == _userGeneration &&
      userId == _authenticatedUserId &&
      userId == _authProvider?.userId;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearUpdateError() {
    if (_updateErrorMessage == null || _disposed) return;
    _updateErrorMessage = null;
    notifyListeners();
  }

  void clearDeleteError() {
    if (_deleteErrorMessage == null || _disposed) return;
    _deleteErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _userGeneration++;
    _streamGeneration++;
    _isLoading = false;
    _isPortfolioLoading = false;
    _cardsSubscription?.cancel();
    _cardsSubscription = null;
    _authProvider?.removeListener(_handleAuthChange);
    super.dispose();
  }
}
