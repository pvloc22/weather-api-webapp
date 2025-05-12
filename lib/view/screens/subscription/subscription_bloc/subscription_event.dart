abstract class SubscriptionEvent {}

class CheckSubscriptionStatusEvent extends SubscriptionEvent {}

class SubmitEmailEvent extends SubscriptionEvent {
  final String email;
  
  SubmitEmailEvent(this.email);
}

class VerifyOtpEvent extends SubscriptionEvent {
  final String otp;
  final String email;
  
  VerifyOtpEvent(this.otp, this.email);
}

class SaveLocationEvent extends SubscriptionEvent {
  final String location;
  final String email;
  
  SaveLocationEvent(this.location, this.email);
}

class UseCurrentLocationEvent extends SubscriptionEvent {
  final String email;
  
  UseCurrentLocationEvent(this.email);
}

class UnsubscribeEvent extends SubscriptionEvent {}

class ResendOtpEvent extends SubscriptionEvent {
  final String email;
  
  ResendOtpEvent(this.email);
} 