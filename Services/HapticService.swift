//
//  HapticService.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation
import CoreHaptics
import UIKit

class HapticService: ObservableObject {
    
    // MARK: - Constants
    
    private let zoneRange: Double = 15.0        // ±15° zone
    private let minIntensity: Float = 0.2       // Intensity at 15° boundary
    private let maxIntensity: Float = 0.8       // Intensity at center (0°)
    private let feedbackInterval: TimeInterval = 0.1  // Feedback every 0.1 seconds
    private let minSharpness: Float = 0.1    // Haptic feedback sharpness
    private let maxSharpness: Float = 1.0
    
    // MARK: - State
    
    private var hapticEngine: CHHapticEngine?
    private var feedbackTimer: Timer?
    private var isInZone = false
    
    // MARK: - Initialization
    
    init() {
        setupHapticEngine()
    }
    
    /// Initializes the Core Haptics engine
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptic engine not supported on this device")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    // MARK: - Main Method
    
    /// Updates haptic feedback based on compass alignment
    func updateAlignmentFeedback(degreesOffTarget: Double) {
        let absAlignment = abs(degreesOffTarget)
        
        // Check if we're in the haptic zone
        if absAlignment <= zoneRange {
            if !isInZone {
                // Just entered zone - start continuous feedback
                isInZone = true
                //startContinuousFeedback()   //enhance this if we want continuous, which we don't rn
            }
            
            // Calculate intensity based on distance from center
            let normalizedDistance = Float(absAlignment / zoneRange)  // 0.0 to 1.0
            let intensityDiff = maxIntensity - minIntensity
            let sharpnessDiff = maxSharpness - minSharpness
            let intensity = maxIntensity - Float(normalizedDistance) * intensityDiff
            let sharpness = maxSharpness - Float(normalizedDistance) * sharpnessDiff
            
            // Provide immediate feedback
            provideFeedback(intensity: intensity, sharpness: sharpness)
            
            // Debug output
            if degreesOffTarget > 0 {
                print("R")  // Right of target
            } else if degreesOffTarget < 0 {
                print("L")  // Left of target
            } else {
                print("")   // No letter at 0
            }
            
        } else {
            if isInZone {
                // Left zone - stop continuous feedback
                isInZone = false
                stopContinuousFeedback()
            }
        }
    }
    
    // MARK: - Timer Management
    
    /// Starts continuous haptic feedback timer
    private func startContinuousFeedback() {
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: feedbackInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Timer will provide continuous feedback while in zone
            // The main feedback is handled in updateAlignmentFeedback
        }
    }
    
    /// Stops continuous haptic feedback timer
    private func stopContinuousFeedback() {
        feedbackTimer?.invalidate()
        feedbackTimer = nil
    }
    
    // MARK: - Haptic Feedback
    
    /// Provides haptic feedback at specified intensity
    private func provideFeedback(intensity: Float, sharpness: Float) {
        guard let engine = hapticEngine else { return }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        
        playHapticEvent(event)
    }
    
    /// Plays the haptic event
    private func playHapticEvent(_ event: CHHapticEvent) {
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic event: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    /// Resets all haptic state for new destination
    func resetAllState() {
        stopContinuousFeedback()
        isInZone = false
    }
    
    deinit {
        stopContinuousFeedback()
    }
}
