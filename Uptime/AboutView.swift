//
//  AboutView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            // App Info
            VStack(spacing: 8) {
                Text("Uptime")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Description
            VStack(spacing: 12) {
                Text("A beautiful menubar app for tracking your Mac's uptime")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Text("Features include uptime history, milestone notifications, and customizable display formats.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
                .padding(.vertical)
            
            // Credits
            VStack(spacing: 8) {
                Text("© 2025 Curtis Netterville")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Text("Made with ❤️ using SwiftUI")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // System Info
            VStack(spacing: 4) {
                Text("System: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                
                Text("Architecture: \(getArchitecture())")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            
            Spacer()
            
            // Close Button
            Button("Close") {
                NSApplication.shared.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .frame(width: 350, height: 450)
        .background(.ultraThinMaterial)
    }
    
    private func getArchitecture() -> String {
        #if arch(arm64)
        return "Apple Silicon"
        #elseif arch(x86_64)
        return "Intel"
        #else
        return "Unknown"
        #endif
    }
}

#Preview {
    AboutView()
}