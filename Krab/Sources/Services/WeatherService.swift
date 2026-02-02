import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var updateTimer: Timer?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func startUpdating() {
        requestLocation()
        scheduleUpdates()
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func scheduleUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: SettingsManager.shared.weatherRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchWeather()
            }
        }
    }
    
    func requestLocation() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            // Use default location or saved location
            Task {
                await fetchWeatherForLocation(SettingsManager.shared.weatherLocation)
            }
        }
    }
    
    func fetchWeather() async {
        if let location = currentLocation {
            await fetchWeatherForCoordinates(location.coordinate)
        } else {
            await fetchWeatherForLocation(SettingsManager.shared.weatherLocation)
        }
    }
    
    private func fetchWeatherForLocation(_ location: String) async {
        guard location != "auto" else {
            // Try to get location again
            requestLocation()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Using Open-Meteo API (free, no API key required)
        // First geocode the location
        guard let geocodeURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&count=1") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: geocodeURL)
            let geocodeResponse = try JSONDecoder().decode(GeocodeResponse.self, from: data)
            
            if let result = geocodeResponse.results?.first {
                let coordinate = CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
                await fetchWeatherForCoordinates(coordinate, locationName: result.name)
            }
        } catch {
            self.error = error
        }
    }
    
    private func fetchWeatherForCoordinates(_ coordinate: CLLocationCoordinate2D, locationName: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,uv_index_max&timezone=auto"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            
            let location = locationName ?? await reverseGeocode(coordinate)
            
            let weather = WeatherData(
                temperature: convertTemperature(response.current.temperature_2m),
                condition: mapWeatherCode(response.current.weather_code),
                humidity: Int(response.current.relative_humidity_2m),
                windSpeed: response.current.wind_speed_10m,
                location: location,
                high: convertTemperature(response.daily.temperature_2m_max.first ?? 0),
                low: convertTemperature(response.daily.temperature_2m_min.first ?? 0),
                feelsLike: convertTemperature(response.current.apparent_temperature),
                uvIndex: Int(response.daily.uv_index_max.first ?? 0),
                updatedAt: Date()
            )
            
            currentWeather = weather
            error = nil
        } catch {
            self.error = error
        }
    }
    
    private func convertTemperature(_ celsius: Double) -> Double {
        if SettingsManager.shared.weatherUnit == .fahrenheit {
            return celsius * 9/5 + 32
        }
        return celsius
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return placemark.locality ?? placemark.administrativeArea ?? "Unknown"
            }
        } catch {
            // Ignore geocoding errors
        }
        
        return "Unknown"
    }
    
    private func mapWeatherCode(_ code: Int) -> WeatherCondition {
        switch code {
        case 0: return .sunny
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .foggy
        case 51...67: return .rainy
        case 71...77: return .snowy
        case 80...82: return .rainy
        case 85, 86: return .snowy
        case 95...99: return .stormy
        default: return .cloudy
        }
    }
}

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            await self.fetchWeatherForCoordinates(location.coordinate)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - API Response Models
private struct GeocodeResponse: Codable {
    let results: [GeocodeResult]?
}

private struct GeocodeResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
}

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
}

private struct CurrentWeather: Codable {
    let temperature_2m: Double
    let relative_humidity_2m: Double
    let apparent_temperature: Double
    let weather_code: Int
    let wind_speed_10m: Double
}

private struct DailyWeather: Codable {
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let uv_index_max: [Double]
}
