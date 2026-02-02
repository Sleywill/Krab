import SwiftUI

struct NotesWidgetView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager
    @State private var newNoteText = ""
    @State private var isAddingNote = false
    @AppStorage("quickNotes") private var notesData: Data = Data()
    
    private var notes: [QuickNote] {
        get {
            (try? JSONDecoder().decode([QuickNote].self, from: notesData)) ?? []
        }
    }
    
    private func saveNotes(_ notes: [QuickNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            notesData = data
        }
    }
    
    var body: some View {
        WidgetCard(title: "Quick Notes", icon: "note.text", color: .yellow) {
            VStack(spacing: 12) {
                if isAddingNote {
                    // Add note input
                    HStack(spacing: 8) {
                        TextField("Quick note...", text: $newNoteText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .onSubmit {
                                addNote()
                            }
                        
                        Button {
                            addNote()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newNoteText.isEmpty)
                        
                        Button {
                            isAddingNote = false
                            newNoteText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button {
                        withAnimation(.krabSpring) {
                            isAddingNote = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                            Text("Add note")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if notes.isEmpty {
                    EmptyStateView(
                        icon: "note.text",
                        message: "No notes yet"
                    )
                } else {
                    VStack(spacing: 6) {
                        ForEach(notes.prefix(5)) { note in
                            NoteRow(note: note, onDelete: {
                                deleteNote(note)
                            }, onTogglePin: {
                                togglePin(note)
                            })
                        }
                        
                        if notes.count > 5 {
                            Text("+\(notes.count - 5) more notes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func addNote() {
        guard !newNoteText.isEmpty else { return }
        
        var updatedNotes = notes
        let note = QuickNote(content: newNoteText)
        updatedNotes.insert(note, at: 0)
        saveNotes(updatedNotes)
        
        newNoteText = ""
        isAddingNote = false
    }
    
    private func deleteNote(_ note: QuickNote) {
        var updatedNotes = notes
        updatedNotes.removeAll { $0.id == note.id }
        saveNotes(updatedNotes)
    }
    
    private func togglePin(_ note: QuickNote) {
        var updatedNotes = notes
        if let index = updatedNotes.firstIndex(where: { $0.id == note.id }) {
            updatedNotes[index].isPinned.toggle()
            
            // Sort: pinned first
            updatedNotes.sort { $0.isPinned && !$1.isPinned }
            saveNotes(updatedNotes)
        }
    }
}

struct NoteRow: View {
    let note: QuickNote
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
            
            Text(note.content)
                .font(.system(size: 12))
                .lineLimit(2)
            
            Spacer()
            
            if isHovering {
                HStack(spacing: 4) {
                    Button(action: onTogglePin) {
                        Image(systemName: note.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            } else {
                Text(note.createdAt.timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    NotesWidgetView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsManager.shared)
        .frame(width: 250)
        .padding()
        .preferredColorScheme(.dark)
}
