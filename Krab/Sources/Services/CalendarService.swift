import Foundation
import EventKit
import Combine

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()
    
    @Published var events: [CalendarEvent] = []
    @Published var reminders: [ReminderItem] = []
    @Published var isAuthorized = false
    @Published var error: Error?
    
    private let eventStore = EKEventStore()
    private var updateTimer: Timer?
    
    init() {
        checkAuthorization()
    }
    
    func startUpdating() {
        fetchEvents()
        fetchReminders()
        scheduleUpdates()
        
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.fetchEvents()
            self?.fetchReminders()
        }
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func scheduleUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchEvents()
            self?.fetchReminders()
        }
    }
    
    func checkAuthorization() {
        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        isAuthorized = (calendarStatus == .fullAccess || calendarStatus == .authorized) &&
                       (reminderStatus == .fullAccess || reminderStatus == .authorized)
    }
    
    func requestAccess() async {
        do {
            if #available(macOS 14.0, *) {
                let eventGranted = try await eventStore.requestFullAccessToEvents()
                let reminderGranted = try await eventStore.requestFullAccessToReminders()
                isAuthorized = eventGranted && reminderGranted
            } else {
                let eventGranted = try await eventStore.requestAccess(to: .event)
                let reminderGranted = try await eventStore.requestAccess(to: .reminder)
                isAuthorized = eventGranted && reminderGranted
            }
            
            if isAuthorized {
                fetchEvents()
                fetchReminders()
            }
        } catch {
            self.error = error
        }
    }
    
    func fetchEvents() {
        guard isAuthorized else { return }
        
        let settings = SettingsManager.shared
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: settings.calendarDaysAhead, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        events = ekEvents
            .filter { settings.showAllDayEvents || !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEvent(
                    id: event.eventIdentifier,
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    location: event.location,
                    isAllDay: event.isAllDay,
                    calendarColor: event.calendar.cgColor?.toHex() ?? "#007AFF"
                )
            }
    }
    
    func fetchReminders() {
        guard isAuthorized else { return }
        
        let calendars = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForReminders(in: calendars)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
            let reminders = (ekReminders ?? [])
                .filter { !$0.isCompleted }
                .sorted { 
                    ($0.dueDateComponents?.date ?? Date.distantFuture) < 
                    ($1.dueDateComponents?.date ?? Date.distantFuture)
                }
                .prefix(20)
                .map { reminder in
                    ReminderItem(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "Untitled",
                        notes: reminder.notes,
                        dueDate: reminder.dueDateComponents?.date,
                        isCompleted: reminder.isCompleted,
                        priority: Int(reminder.priority),
                        listName: reminder.calendar.title
                    )
                }
            
            Task { @MainActor in
                self?.reminders = Array(reminders)
            }
        }
    }
    
    func toggleReminderCompletion(_ reminder: ReminderItem) {
        guard isAuthorized else { return }
        
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
            guard let ekReminder = ekReminders?.first(where: { $0.calendarItemIdentifier == reminder.id }) else {
                return
            }
            
            ekReminder.isCompleted = !reminder.isCompleted
            
            do {
                try self?.eventStore.save(ekReminder, commit: true)
                Task { @MainActor in
                    self?.fetchReminders()
                }
            } catch {
                Task { @MainActor in
                    self?.error = error
                }
            }
        }
    }
    
    func createReminder(title: String, dueDate: Date? = nil, notes: String? = nil) {
        guard isAuthorized else { return }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            fetchReminders()
        } catch {
            self.error = error
        }
    }
    
    func getUpcomingEvent() -> CalendarEvent? {
        let now = Date()
        return events.first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }
    }
    
    func getEventsForToday() -> [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return events.filter { event in
            event.startDate >= today && event.startDate < tomorrow
        }
    }
}

// MARK: - CGColor Extension
extension CGColor {
    func toHex() -> String {
        guard let components = components, components.count >= 3 else {
            return "#007AFF"
        }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
