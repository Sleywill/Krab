import SwiftUI

struct CalendarWidgetView: View {
    @StateObject private var calendarService = CalendarService.shared
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "Calendar", icon: "calendar", color: .red) {
            if !calendarService.isAuthorized {
                UnauthorizedView(
                    icon: "calendar.badge.exclamationmark",
                    message: "Calendar access required",
                    action: {
                        Task {
                            await calendarService.requestAccess()
                        }
                    }
                )
            } else if calendarService.events.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    message: "No upcoming events"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(calendarService.events.prefix(5)) { event in
                        CalendarEventRow(event: event)
                    }
                    
                    if calendarService.events.count > 5 {
                        Text("+\(calendarService.events.count - 5) more events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .onAppear {
            calendarService.startUpdating()
        }
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: event.isNow ? .semibold : .regular))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(event.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let location = event.location, !location.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if event.isNow {
                Text("NOW")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(event.isNow ? Color.green.opacity(0.1) : Color.clear)
        )
    }
}

struct RemindersWidgetView: View {
    @StateObject private var calendarService = CalendarService.shared
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "Reminders", icon: "checklist", color: .blue) {
            if !calendarService.isAuthorized {
                UnauthorizedView(
                    icon: "checklist.unchecked",
                    message: "Reminders access required",
                    action: {
                        Task {
                            await calendarService.requestAccess()
                        }
                    }
                )
            } else if calendarService.reminders.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    message: "All caught up!"
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(calendarService.reminders.prefix(6)) { reminder in
                        ReminderRow(reminder: reminder)
                    }
                    
                    if calendarService.reminders.count > 6 {
                        Text("+\(calendarService.reminders.count - 6) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct ReminderRow: View {
    let reminder: ReminderItem
    @StateObject private var calendarService = CalendarService.shared
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                calendarService.toggleReminderCompletion(reminder)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(reminder.isCompleted ? .green : reminder.priorityColor)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.system(size: 12))
                    .strikethrough(reminder.isCompleted)
                    .lineLimit(1)
                
                if let dueDate = reminder.dueDate {
                    Text(dueDate.relativeString + " " + dueDate.timeString)
                        .font(.caption2)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views
struct UnauthorizedView: View {
    let icon: String
    let message: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Grant Access", action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    VStack {
        CalendarWidgetView()
        RemindersWidgetView()
    }
    .environmentObject(SettingsManager.shared)
    .frame(width: 300)
    .padding()
    .preferredColorScheme(.dark)
}
