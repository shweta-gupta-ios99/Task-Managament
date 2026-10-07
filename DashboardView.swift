import Charts
import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: TaskListViewModel

    private var chartData: [StatusChartItem] {
        [
            StatusChartItem(status: "Completed", count: viewModel.completedCount, color: .green),
            StatusChartItem(status: "Pending", count: viewModel.pendingCount, color: .red)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                        MetricCard(title: "Total", value: viewModel.totalCount, color: .accentColor)
                        MetricCard(title: "Completed", value: viewModel.completedCount, color: .green)
                        MetricCard(title: "Pending", value: viewModel.pendingCount, color: .red)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tasks by status")
                            .font(.headline)
                        if viewModel.totalCount == 0 {
                            ContentUnavailableView(
                                "No task data yet",
                                systemImage: "chart.bar",
                                description: Text("Your task statistics will appear here.")
                            )
                            .frame(height: 200)
                        } else {
                            Chart(chartData) { item in
                                BarMark(
                                    x: .value("Status", item.status),
                                    y: .value("Tasks", item.count)
                                )
                                .foregroundStyle(item.color.gradient)
                                .annotation(position: .top) {
                                    Text("\(item.count)")
                                        .font(.caption.weight(.semibold))
                                }
                            }
                            .chartYScale(domain: 0...(max(viewModel.totalCount, 1) + 1))
                            .frame(height: 240)
                            .accessibilityLabel("Bar chart showing completed and pending tasks")
                        }
                    }
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Overview")
        }
    }
}

private struct StatusChartItem: Identifiable {
    let status: String
    let count: Int
    let color: Color

    var id: String { status }
}

private struct MetricCard: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
