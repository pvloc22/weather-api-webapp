import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_event.dart';
import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_state.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../data/repositories/email_subscription_repository.dart';
import '../../../../data/repositories/home_repository.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final EmailSubscriptionRepository _repository = EmailSubscriptionRepository();
  final HomeRepository _homeRepository = HomeRepository();
  
  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<CheckSubscriptionStatusEvent>(_onCheckSubscriptionStatus);
    on<SubmitEmailEvent>(_onSubmitEmail);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SaveLocationEvent>(_onSaveLocation);
    on<UseCurrentLocationEvent>(_onUseCurrentLocation);
    on<UnsubscribeEvent>(_onUnsubscribe);
    on<ResendOtpEvent>(_onResendOtp);
  }

  void _onCheckSubscriptionStatus(
    CheckSubscriptionStatusEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    try {
      final isSubscribed = await _repository.isSubscribed();
      
      if (isSubscribed) {
        final details = await _repository.getSubscriptionDetails();
        emit(SubscriptionCompletedState(details['email'] ?? '', details['location'] ?? ''));
      } else {
        emit(SubscriptionInitial());
      }
    } catch (e) {
      emit(SubscriptionInitial());
    }
  }

  void _onSubmitEmail(
    SubmitEmailEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    emit(EmailSubmittingState());
    
    try {
      final result = await _repository.sendVerificationEmail(event.email);
      
      if (result) {
        emit(EmailSubmittedState(event.email));
      } else {
        emit(EmailErrorState("Failed to send verification code. Please check your email address and try again."));
      }
    } catch (e) {
      emit(EmailErrorState("An error occurred while sending the verification code."));
    }
  }

  void _onVerifyOtp(
    VerifyOtpEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    emit(OtpVerifyingState(event.email));
    
    try {
      final isValid = await _repository.verifyOtp(event.email, event.otp);
      
      if (isValid) {
        emit(OtpVerifiedState(event.email));
      } else {
        emit(OtpErrorState("Invalid verification code. Please try again.", event.email));
      }
    } catch (e) {
      emit(OtpErrorState("An error occurred while verifying the code.", event.email));
    }
  }

  void _onSaveLocation(
    SaveLocationEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    emit(LocationSavingState(event.email));
    
    try {
      // Check city name validity using search API
      try {
        final searchResult = await _homeRepository.getSearchCityName(event.location);
        
        // If search successful, use official city name from API
        final officialCityName = "${searchResult.name}, ${searchResult.country}";
        
        // Save subscription with official city name
        await _repository.saveSubscription(event.email, officialCityName);
        await _repository.sendSubscriptionConfirmation(event.email, officialCityName);
        
        emit(SubscriptionCompletedState(event.email, officialCityName));
      } catch (searchError) {
        // If city not found, return error asking for re-entry
        emit(LocationErrorState("City not found. Please enter a valid city name.", event.email));
      }
    } catch (e) {
      emit(LocationErrorState("Failed to add location to your profile.", event.email));
    }
  }

  void _onUseCurrentLocation(
    UseCurrentLocationEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    emit(LocationSavingState(event.email));
    
    try {
      // Get current location using geolocator package
      if (kIsWeb) {
        // For web, prompt for location permission
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final requestResult = await Geolocator.requestPermission();
          if (requestResult == LocationPermission.denied) {
            emit(LocationErrorState("Location permission denied.", event.email));
            return;
          }
        }
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      
      try {
        // Try to convert coordinates to city name via weather API
        final weatherResponse = await _homeRepository.getCurrentAndForecastsUseGPSWeather(
          position.latitude, 
          position.longitude
        );
        
        final cityName = weatherResponse.currentWeather.cityName ?? 
          "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
        
        // Save subscription with city name from coordinates
        await _repository.saveSubscription(event.email, cityName);
        await _repository.sendSubscriptionConfirmation(event.email, cityName);
        
        emit(SubscriptionCompletedState(event.email, cityName));
      } catch (weatherError) {
        // If city name can't be retrieved, use coordinates
        final locationName = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
        
        await _repository.saveSubscription(event.email, locationName);
        await _repository.sendSubscriptionConfirmation(event.email, locationName);
        
        emit(SubscriptionCompletedState(event.email, locationName));
      }
    } catch (e) {
      emit(LocationErrorState("Failed to get your current location. Please try again.", event.email));
    }
  }

  void _onUnsubscribe(
    UnsubscribeEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    emit(UnsubscribingState());
    
    try {
      await _repository.unsubscribe();
      emit(UnsubscribedState());
    } catch (e) {
      // If there's an error, we still consider the user unsubscribed
      emit(UnsubscribedState());
    }
  }
  
  void _onResendOtp(
    ResendOtpEvent event, 
    Emitter<SubscriptionState> emit
  ) async {
    emit(EmailSubmittingState());
    
    try {
      final result = await _repository.sendVerificationEmail(event.email);
      
      if (result) {
        emit(EmailSubmittedState(event.email));
      } else {
        emit(EmailErrorState("Failed to resend verification code. Please try again."));
      }
    } catch (e) {
      emit(EmailErrorState("An error occurred while resending the verification code."));
    }
  }
} 