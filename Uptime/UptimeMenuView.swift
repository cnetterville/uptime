//
//  UptimeMenuView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI

struct UptimeMenuView: View {
    @ObservedObject var uptimeManager: UptimeManager
    @State private var isVisible = false
    @State private var refreshRotation = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with liquid glass effect
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .rotationEffect(.degrees(isVisible ? 0 : -180))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isVisible)
                    
                    Text("System Uptime")
                        .font(.headline)
                        .fontWeight(.medium)
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)
                    
                    Spacer()
                }
                
                Divider()
                    .opacity(0.3)
                    .scaleEffect(x: isVisible ? 1 : 0, anchor: .leading)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
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
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.5), value: isVisible)
                        
                        Text(uptimeManager.formattedUptime)
                            .font(.title)
                            .fontWeight(.semibold)
                            .fontDesign(.monospaced)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: isVisible)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Longest Session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.7), value: isVisible)
                        
                        Text(uptimeManager.longestUptimeSession)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                            .multilineTextAlignment(.trailing)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.8), value: isVisible)
                    }
                    .frame(minWidth: 100)
                }
                
                // Progress indicator with animation
                ProgressView(value: uptimeManager.uptimeProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
                    .opacity(0.8)
                    .scaleEffect(x: isVisible ? 1 : 0, anchor: .leading)
                    .animation(.easeOut(duration: 0.8).delay(0.9), value: isVisible)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    }
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4), value: isVisible)
            }
            .padding(.horizontal, 16)
            
            // Action buttons with liquid glass effect and hover animations
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        refreshRotation += 360
                    }
                    uptimeManager.refresh()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .rotationEffect(.degrees(refreshRotation))
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
                .buttonStyle(AnimatedButtonStyle())
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : -20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: isVisible)
                
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
                .buttonStyle(AnimatedButtonStyle())
                .foregroundStyle(.red)
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.1), value: isVisible)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 340, height: 200)
        .background {
            // Liquid glass background with entrance animation
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.primary.opacity(0.05), lineWidth: 1)
                }
                .scaleEffect(isVisible ? 1 : 0.8)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isVisible)
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// Custom button style with hover animations
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    UptimeMenuView(uptimeManager: UptimeManager())
        .frame(width: 340, height: 200)
}