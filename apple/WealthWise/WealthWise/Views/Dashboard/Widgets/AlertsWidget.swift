//
//  AlertsWidget.swift
//  WealthWise
//
//  Alerts and notifications widget
//

import SwiftUI

@available(iOS 18.6, macOS 15.6, *)
struct AlertsWidget: View {
    let alerts: [DashboardAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Alerts List
            if alerts.isEmpty {
                emptyStateView
            } else {
                alertsListView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("dashboard.alerts", comment: "Alerts & Notifications"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !alerts.isEmpty {
                    Text(String(format: NSLocalizedString("dashboard.alerts_count", comment: "%d active alerts"), alerts.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if alerts.filter({ $0.actionRequired }).count > 0 {
                Text(String(format: NSLocalizedString("dashboard.action_required", comment: "%d action required"), alerts.filter({ $0.actionRequired }).count))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
    }
    
    private var alertsListView: some View {
        VStack(spacing: 12) {
            ForEach(alerts.prefix(3)) { alert in
                alertRow(alert)
            }
        }
    }
    
    private func alertRow(_ alert: DashboardAlert) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(alert.severity.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: alert.severity.icon)
                    .font(.system(size: 16))
                    .foregroundColor(alert.severity.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if alert.actionRequired {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(formatDate(alert.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                // Handle alert action
            }) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text(NSLocalizedString("dashboard.no_alerts", comment: "No alerts"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("dashboard.all_clear", comment: "Everything looks good!"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    AlertsWidget(alerts: [
        DashboardAlert(
            title: "Tax Payment Due",
            message: "Advance tax payment due in 15 days",
            severity: .warning,
            actionRequired: true
        ),
        DashboardAlert(
            title: "Goal Milestone Reached",
            message: "You've reached 75% of your retirement goal",
            severity: .info,
            date: Date().addingTimeInterval(-86400)
        ),
        DashboardAlert(
            title: "Portfolio Rebalance Needed",
            message: "Your portfolio has drifted from target allocation",
            severity: .info
        )
    ])
    .frame(maxWidth: 400)
    .padding()
}
