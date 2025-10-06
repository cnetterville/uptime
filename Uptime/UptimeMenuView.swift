//
//  UptimeMenuView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI

struct UptimeMenuView: View {
    @StateObject private var uptimeManager = UptimeManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with liquid glass effect
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    
                    Text("System Uptime")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                
                Divider()
                    .opacity(0.3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Uptime display with liquid glass card
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Uptime")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(uptimeManager.formattedUptime)
                            .font(.title)
                            .fontWeight(.semibold)
                            .fontDesign(.monospaced)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Boot Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(uptimeManager.bootTime)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(minWidth: 100)
                }
                
                // Progress indicator
                ProgressView(value: uptimeManager.uptimeProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
                    .opacity(0.8)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 16)
            
            // Action buttons with liquid glass effect
            HStack(spacing: 12) {
                Button(action: {
                    uptimeManager.refresh()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Refresh")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.caption)
                        Text("Quit")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundStyle(.red)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 340, height: 200)
        .background {
            // Liquid glass background
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.primary.opacity(0.05), lineWidth: 1)
                }
        }
        .onAppear {
            uptimeManager.startUpdating()
        }
        .onDisappear {
            uptimeManager.stopUpdating()
        }
    }
}

#Preview {
    UptimeMenuView()
        .frame(width: 340, height: 200)
}