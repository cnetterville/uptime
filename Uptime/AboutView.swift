//
//  AboutView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .padding(.top, 20)
                
                // App Info
                VStack(spacing: 12) {
                    Text("Uptime")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                
                // Description
                VStack(spacing: 16) {
                    Text("A beautiful menubar app for tracking your Mac's uptime")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Features include uptime history, milestone notifications, and customizable display formats.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Credits
                VStack(spacing: 12) {
                    Text("© 2025 Curtis Netterville")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        Text("Made with")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("❤️")
                            .font(.subheadline)
                        
                        Text("using SwiftUI")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // System Info
                VStack(spacing: 8) {
                    Text("System: \(getSystemVersion())")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                    
                    Text("Architecture: \(getArchitecture())")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                
                // Close Button
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 10)
        }
        .frame(width: 420, height: 580)
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
    
    private func getSystemVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

#Preview {
    AboutView()
}