abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

// Email states
class EmailSubmittingState extends SubscriptionState {}

class EmailSubmittedState extends SubscriptionState {
  final String email;
  
  EmailSubmittedState(this.email);
}

class EmailErrorState extends SubscriptionState {
  final String error;
  
  EmailErrorState(this.error);
}

// OTP states
class OtpVerifyingState extends SubscriptionState {
  final String email;
  
  OtpVerifyingState(this.email);
}

class OtpErrorState extends SubscriptionState {
  final String error;
  final String email;
  
  OtpErrorState(this.error, this.email);
}

class OtpVerifiedState extends SubscriptionState {
  final String email;
  
  OtpVerifiedState(this.email);
}

// Location states
class LocationSavingState extends SubscriptionState {
  final String email;
  
  LocationSavingState(this.email);
}

class LocationErrorState extends SubscriptionState {
  final String error;
  final String email;
  
  LocationErrorState(this.error, this.email);
}

class SubscriptionCompletedState extends SubscriptionState {
  final String email;
  final String location;
  
  SubscriptionCompletedState(this.email, this.location);
}

// Unsubscribe states
class UnsubscribingState extends SubscriptionState {}

class UnsubscribedState extends SubscriptionState {} 