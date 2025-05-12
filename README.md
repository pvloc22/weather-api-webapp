# 🌤️ Flutter Weather App (Web & Mobile)

A cross-platform Flutter application (Web & Mobile) to search and track weather forecasts for cities or countries using the [WeatherAPI](https://www.weatherapi.com/). It supports real-time weather, 4-day forecasts, and optional email subscriptions for daily weather updates.

## ✨ Features

- 🔍 **Search Weather by Location**  
  - Search for any **city or country** to view current weather.
  
- 🌡️ **Display Today's Weather**  
  - Shows **temperature**, **humidity**, **wind speed**, and more.

- 📆 **Forecast Feature**  
  - Displays **4-day forecast**, with **"load more"** to see further days.

- 🕒 **Temporary History**  
  - Weather data is **temporarily saved** for each day using `shared_preferences`.  
  - Users can **re-display** weather info for cities searched during the same day.

- 📧 **Email Subscription**  
  - Users can **subscribe/unsubscribe** to receive daily weather updates via email.  
  - **Email confirmation** is required to activate the subscription.  
  - Built-in **Node.js Express server** handles **SMTP email sending** with secure confirmation link.  
  - 🔗 [Server Source Code](https://github.com/pvloc22/weather-email-express-deployment)

- ☁️ **Flutter Web Deployment**  
  - **Deployed using Firebase Hosting.**  
  - 🔗 [WebApp](https://weather-api-165ec.web.app)
---


### 📱 Mobile UI  
![CleanShot 2025-05-13 at 03 53 15@2x](https://github.com/user-attachments/assets/9a29d0e3-e73e-4b1e-906c-fc4251071ad4)


### 💻 Web UI  
![CleanShot 2025-05-13 at 03 51 51@2x](https://github.com/user-attachments/assets/aa817082-9f9e-4281-a49e-6ca66cffaeb6)


---

## 🚀 Technologies & Packages Used

### 🧩 Main Technologies

- **Flutter** – For cross-platform development
- **BLoC** – State management using `flutter_bloc`
- **Shared Preferences** – To store weather history locally
- **SMTP (mailer)** – For email communication
- **Firebase Cloud Functions** – For secure email sending on the web
- **WeatherAPI** – To fetch weather data: [https://www.weatherapi.com/](https://www.weatherapi.com/)

### 📦 Dependencies

```yaml
dependencies:
  cupertino_icons: ^1.0.8
  mailer: ^6.0.1
  http: ^1.4.0
  shared_preferences: ^2.5.3
  geolocator: ^14.0.0
  flutter_bloc: ^9.1.1
