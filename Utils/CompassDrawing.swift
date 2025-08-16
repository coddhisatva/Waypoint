//
//  CompassDrawing.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI

struct CompassRing: View {
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
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(degree)))
                    .rotationEffect(.degrees(Double(-degree))) // Counter-rotate text
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
        .frame(width: 300, height: 300)
    }
}

struct CompassNeedle: View {
    let heading: Double
    
    var body: some View {
        // North indicator (red triangle)
        Triangle()
            .fill(Color.red)
            .frame(width: 8, height: 15)
            .offset(y: -142)
            .rotationEffect(.degrees(-heading))
    }
}

struct DestinationPin: View {
    let bearing: Double
    
    var body: some View {
        // Google Maps style pin
        ZStack {
            // Pin body (teardrop shape)
            Circle()
                .fill(Color.red)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                )
            
            // Pin point
            Triangle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(y: 6)
        }
        .offset(y: -155)
        .rotationEffect(.degrees(bearing))
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
