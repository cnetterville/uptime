//
//  UptimeHistoryView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI

struct UptimeHistoryView: View {
    @ObservedObject var historyManager: UptimeHistoryManager
    @State private var showingExportSheet = false
    @State private var exportedData = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(.primary)
                
                Text("Uptime History")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button("Export") {
                        exportedData = historyManager.exportHistory()
                        showingExportSheet = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear") {
                        historyManager.clearHistory()
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
            }
            
            Divider()
            
            // Statistics section
            if !historyManager.sessions.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        StatCard(
                            title: "Longest Session",
                            value: historyManager.longestSession?.formattedDuration ?? "N/A",
                            icon: "trophy.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Average Session",
                            value: formatDuration(historyManager.averageSessionDuration),
                            icon: "chart.bar.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Uptime",
                            value: formatDuration(historyManager.totalUptime),
                            icon: "sum",
                            color: .green
                        )
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Sessions list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(historyManager.sessions.sorted(by: { $0.bootDate > $1.bootDate })) { session in
                        SessionRow(session: session, isLongest: session.id == historyManager.longestSession?.id)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if historyManager.sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No uptime history yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("History will be recorded automatically as you use your system")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
        .frame(width: 600, height: 500)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(data: exportedData)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let days = Int(duration) / 86400
        let hours = (Int(duration) % 86400) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if days > 0 {
            return String(format: "%dd %02dh", days, hours)
        } else if hours > 0 {
            return String(format: "%02dh %02dm", hours, minutes)
        } else {
            return String(format: "%02dm", minutes)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .fontDesign(.monospaced)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.primary.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

struct SessionRow: View {
    let session: UptimeSession
    let isLongest: Bool
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.formattedDuration)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .fontDesign(.monospaced)
                    
                    if session.isCurrentSession {
                        Text("CURRENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    if isLongest && !session.isCurrentSession {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Text("Booted: \(session.formattedBootDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !session.isCurrentSession {
                    Text("Ended: \(session.formattedEndDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if session.isCurrentSession {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .opacity(isPulsing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear {
                            isPulsing = true
                        }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(session.isCurrentSession ? .blue.opacity(0.1) : .clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(session.isCurrentSession ? .blue.opacity(0.3) : .primary.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

struct ExportSheet: View {
    let data: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Export Uptime History")
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            
            ScrollView {
                Text(data.isEmpty ? "No data to export" : data)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Copy to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(data.isEmpty ? "No data to export" : data, forType: .string)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

#Preview {
    UptimeHistoryView(historyManager: UptimeHistoryManager())
}