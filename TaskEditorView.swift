import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    private let task: TaskItem?

    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var validationMessage: String?
    @State private var isSaving = false

    init(viewModel: TaskListViewModel, task: TaskItem? = nil) {
        self.viewModel = viewModel
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _description = State(initialValue: task?.description ?? "")
        _dueDate = State(initialValue: task?.dueDate ?? .now.addingTimeInterval(3_600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("task.title")
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker(
                        "Due date",
                        selection: $dueDate,
                        in: minimumDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving)
                }
            }
            .onChange(of: viewModel.errorMessage) { _, error in
                if let error { validationMessage = error }
            }
        }
    }

    private var minimumDate: Date {
        guard let task else { return .now }
        return min(.now, task.dueDate)
    }

    private func save() {
        do {
            try TaskListViewModel.validate(title: title, dueDate: dueDate)
        } catch {
            validationMessage = error.localizedDescription
            return
        }

        isSaving = true
        Task {
            await viewModel.save(title: title, description: description, dueDate: dueDate, existingTask: task)
            isSaving = false
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                validationMessage = viewModel.errorMessage
            }
        }
    }
}
