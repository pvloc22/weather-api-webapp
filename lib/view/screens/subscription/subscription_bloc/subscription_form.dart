import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/core/style/colors.dart';
import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_bloc.dart';
import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_event.dart';
import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_state.dart';

class SubscriptionForm extends StatefulWidget {
  const SubscriptionForm({super.key});

  @override
  State<SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<SubscriptionForm> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget is fully built before accessing the Bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionBloc>().add(CheckSubscriptionStatusEvent());
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Subscription'),
        backgroundColor: blueColor,
        foregroundColor: whiteColor,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is EmailErrorState || 
              state is OtpErrorState || 
              state is LocationErrorState) {
            String errorMessage = "";
            
            if (state is EmailErrorState) {
              errorMessage = state.error;
            } else if (state is OtpErrorState) {
              errorMessage = state.error;
            } else if (state is LocationErrorState) {
              errorMessage = state.error;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EmailSubmittingState || 
              state is OtpVerifyingState || 
              state is LocationSavingState ||
              state is UnsubscribingState) {
            return _buildLoadingScreen();
          } else if (state is SubscriptionInitial) {
            return _buildEmailSubscriptionScreen(context);
          } else if (state is EmailSubmittedState) {
            return _buildOtpVerificationScreen(context, state.email);
          } else if (state is OtpVerifiedState) {
            return _buildLocationSelectionScreen(context, state.email);
          } else if (state is OtpErrorState) {
            return _buildOtpVerificationScreen(context, state.email);
          } else if (state is SubscriptionCompletedState) {
            return _buildSuccessScreen(context, state.email, state.location);
          } else if (state is UnsubscribedState) {
            return _buildUnsubscribedScreen(context);
          } else if (state is EmailErrorState) {
            return _buildEmailSubscriptionScreen(context);
          } else if (state is LocationErrorState) {
            return _buildLocationSelectionScreen(context, state.email);
          }
          return _buildEmailSubscriptionScreen(context);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: blueColor),
          const SizedBox(height: 24),
          Text(
            'Processing...',
            style: TextStyle(fontSize: 18, color: blueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSubscriptionScreen(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud,
                size: 80,
                color: blueColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Subscribe to Weather Forecast',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: blueColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Get daily weather forecasts directly to your email',
                style: TextStyle(
                  fontSize: 16,
                  color: grayColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: whiteColor,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<SubscriptionBloc>().add(
                          SubmitEmailEvent(_emailController.text),
                        );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Subscribe',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpVerificationScreen(BuildContext context, String email) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 80,
              color: blueColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: blueColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification code to $email',
              style: const TextStyle(
                fontSize: 16,
                color: grayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                hintText: 'Enter 6-digit code',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: whiteColor,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_otpController.text.length == 6) {
                  context.read<SubscriptionBloc>().add(
                        VerifyOtpEvent(_otpController.text, email),
                      );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid 6-digit OTP code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                foregroundColor: whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<SubscriptionBloc>().add(
                      ResendOtpEvent(email),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification code resent'),
                  ),
                );
              },
              child: const Text(
                'Resend Code',
                style: TextStyle(color: blueColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelectionScreen(BuildContext context, String email) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 80,
              color: blueColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Set Your Location',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: blueColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your location for personalized weather forecasts',
              style: TextStyle(
                fontSize: 16,
                color: grayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a valid city name (e.g. "Paris", "New York", "Tokyo")',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: grayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Enter city name',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: whiteColor,
                helperText: 'We will verify if this city exists in our database',
              ),
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              enableSuggestions: true,
            ),
            const SizedBox(height: 24),
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, state) {
                final isLoading = state is LocationSavingState;
                
                return ElevatedButton(
                  onPressed: isLoading 
                    ? null 
                    : () {
                        if (_locationController.text.isNotEmpty) {
                          context.read<SubscriptionBloc>().add(
                                SaveLocationEvent(_locationController.text, email),
                              );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a location'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Verifying city...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text(
                        'Save Location',
                        style: TextStyle(fontSize: 16),
                      ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Or',
              style: TextStyle(color: grayColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, state) {
                final isLoading = state is LocationSavingState;
                
                return OutlinedButton.icon(
                  onPressed: isLoading 
                    ? null 
                    : () {
                        context.read<SubscriptionBloc>().add(
                              UseCurrentLocationEvent(email),
                            );
                      },
                  icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: blueColor,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location),
                  label: Text(isLoading ? 'Detecting location...' : 'Use Current Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blueColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: blueColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, String email, String location) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Successfully Subscribed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: blueColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You will receive daily weather forecasts for $location at $email',
              style: const TextStyle(
                fontSize: 16,
                color: grayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                final bloc = context.read<SubscriptionBloc>();
                showDialog(
                  context: context,
                  builder: (dialogContext) => BlocProvider<SubscriptionBloc>.value(
                    value: bloc,
                    child: AlertDialog(
                      title: const Text('Unsubscribe'),
                      content: const Text('Are you sure you want to unsubscribe from weather forecast emails?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            bloc.add(UnsubscribeEvent());
                          },
                          child: const Text('Unsubscribe', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.unsubscribe_outlined, color: Colors.red),
              label: const Text(
                'Unsubscribe',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsubscribedScreen(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.unsubscribe_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Unsubscribed Successfully',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: blueColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You have been unsubscribed from weather forecast emails',
              style: TextStyle(
                fontSize: 16,
                color: grayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _emailController.clear();
                _otpController.clear();
                _locationController.clear();
                context.read<SubscriptionBloc>().add(CheckSubscriptionStatusEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                foregroundColor: whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Subscribe Again',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 