//
//  ContentView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))
            
            Text("Uptime Menubar App")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("This app runs in your menubar")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open Menubar") {
                // This view shouldn't normally be shown
                NSApp.setActivationPolicy(.accessory)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(8)
        }
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.primary.opacity(0.1), lineWidth: 1)
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}