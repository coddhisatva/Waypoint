//
//  CompassDrawing.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI

struct CompassRing: View {
    let heading: Double
    
    // Compass size and positioning constants
    private let compassSize: CGFloat = 300
    private let numberRadius: CGFloat = 175
    
    var body: some View {
        ZStack {
            // Main circle
            Circle()
                .stroke(Color.white, lineWidth: 2)
            
            // Degree markings
            ForEach(0..<360, id: \.self) { degree in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: degree % 30 == 0 ? 2 : 1,
                           height: degree % 30 == 0 ? 20 : (degree % 10 == 0 ? 15 : 8))
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(degree)))
            }
            
            // Cardinal directions
            VStack {
                Text("N").font(.title).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Text("S").font(.title).fontWeight(.bold).foregroundColor(.white)
            }
            .frame(height: 240)
            
            HStack {
                Text("W").font(.title).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Text("E").font(.title).fontWeight(.bold).foregroundColor(.white)
            }
            .frame(width: 240)
            
            // Degree numbers
            ForEach([30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330], id: \.self) { degree in
                Text("\(degree)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .position(
                        x: compassSize/2 + numberRadius * cos(Double(degree - 90) * .pi / 180),
                        y: compassSize/2 + numberRadius * sin(Double(degree - 90) * .pi / 180)
                    )
            }
            
            // Center crosshairs
            Rectangle()
                .fill(Color.gray)
                .frame(width: 1, height: 80)
            Rectangle()
                .fill(Color.gray)
                .frame(width: 80, height: 1)
            
            Circle()
                .fill(Color.gray)
                .frame(width: 40, height: 40)
        }
        .frame(width: compassSize, height: compassSize)
        .rotationEffect(.degrees(-heading)) // Rotate entire compass opposite to heading
    }
}

struct CompassNeedle: View {
    let heading: Double
    
    // Needle positioning constants
    private let redArrowDistance: CGFloat = 166
    private let whiteLineLength: CGFloat = 68
    private let whiteLineOffset: CGFloat = -30
    
    var body: some View {
        ZStack {
            // Red north indicator triangle (points to magnetic north)
            Triangle()
                .fill(Color.red)
                .frame(width: 8, height: 16)
                .offset(y: -redArrowDistance)
                .rotationEffect(.degrees(-heading))  // Add back rotation to point north
            
            // White heading indicator line (shows current device direction)
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: whiteLineLength)
                .offset(y: whiteLineOffset)
            // No rotation - points "up" relative to device
        }
    }
}

struct DestinationPin: View {
    let bearing: Double
    let currentHeading: Double
    
    // Pin positioning constants
    private let pinDistance: CGFloat = 180
    
    var body: some View {
        // Google Maps style pin
        ZStack {
            // Pin body (teardrop shape)
            Circle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 15, height: 15)
                )
            /*
            // Pin point
            Triangle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(y: 6)*/
        }
        .offset(y: -pinDistance)
        .rotationEffect(.degrees(bearing - currentHeading)) // Position relative to magnetic north
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}
