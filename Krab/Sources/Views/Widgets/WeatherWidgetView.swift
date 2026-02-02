import SwiftUI

struct WeatherWidgetView: View {
    @StateObject private var weatherService = WeatherService.shared
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "Weather", icon: "cloud.sun.fill", color: .orange) {
            if let weather = weatherService.currentWeather {
                VStack(spacing: 16) {
                    // Main temperature display
                    HStack(alignment: .top, spacing: 4) {
                        Text(weather.temperatureString)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Image(systemName: weather.icon)
                                .font(.system(size: 32))
                                .foregroundColor(weather.condition.color)
                                .symbolRenderingMode(.multicolor)
                            
                            Text(weather.condition.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Details
                    HStack(spacing: 20) {
                        WeatherDetailItem(
                            icon: "thermometer",
                            value: "H: \(String(format: "%.0f°", weather.high))",
                            label: "L: \(String(format: "%.0f°", weather.low))"
                        )
                        
                        WeatherDetailItem(
                            icon: "humidity.fill",
                            value: "\(weather.humidity)%",
                            label: "Humidity"
                        )
                        
                        WeatherDetailItem(
                            icon: "wind",
                            value: "\(String(format: "%.0f", weather.windSpeed))",
                            label: "km/h"
                        )
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(weather.location)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("Updated \(weather.updatedAt.timeString)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.secondary)
                }
            } else if weatherService.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading weather...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("Unable to load weather")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Retry") {
                        Task {
                            await weatherService.fetchWeather()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            if weatherService.currentWeather == nil {
                weatherService.startUpdating()
            }
        }
    }
}

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WeatherWidgetView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 250)
        .padding()
        .preferredColorScheme(.dark)
}
