import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @State private var editingTask: TaskItem?
    @State private var isCreatingTask = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.visibleTasks.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No tasks found",
                        systemImage: "checkmark.circle",
                        description: Text(viewModel.tasks.isEmpty
                                           ? "Create a task to get started."
                                           : "Try changing your search or filters.")
                    )
                } else {
                    List {
                        filterControls
                        ForEach(viewModel.visibleTasks) { task in
                            TaskRow(
                                task: task,
                                onToggle: { Task { await viewModel.toggleCompletion(for: task) } },
                                onEdit: { editingTask = task }
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(task) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingTask = task
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView("Syncing tasks…")
                }
            }
            .navigationTitle("My Tasks")
            .searchable(text: $viewModel.searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingTask = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .alert("Task error", isPresented: errorPresented) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Reminder", isPresented: reminderPresented) {
                Button("OK", role: .cancel) { viewModel.reminderMessage = nil }
            } message: {
                Text(viewModel.reminderMessage ?? "")
            }
            .sheet(isPresented: $isCreatingTask) {
                TaskEditorView(viewModel: viewModel)
            }
            .sheet(item: $editingTask) { task in
                TaskEditorView(viewModel: viewModel, task: task)
            }
        }
    }

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Status", selection: $viewModel.statusFilter) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            Picker("Due date", selection: $viewModel.dueDateFilter) {
                ForEach(DueDateFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && !isCreatingTask && editingTask == nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var reminderPresented: Binding<Bool> {
        Binding(
            get: { viewModel.reminderMessage != nil },
            set: { if !$0 { viewModel.reminderMessage = nil } }
        )
    }
}

private struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.status == .completed ? .green : .red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.status == .completed ? "Mark pending" : "Mark completed")

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.status == .completed)
                    .foregroundStyle(task.status == .completed ? .secondary : .primary)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Label(task.dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(task.status == .pending && task.dueDate < .now ? .red : .secondary)
                Text(task.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(task.status == .completed ? .green : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
