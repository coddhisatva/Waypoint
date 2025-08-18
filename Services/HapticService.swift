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
    
    // MARK: - Configurable Constants (edit these for testing)
    
    // Alignment zones (degrees)
    private let deadZoneRange: Double = 15.0        // ±15° no feedback zone after successful click
    private let alignmentZoneRange: Double = 5.0    // ±5° precision zone for buildup
    private let approachZoneRange: Double = 15.0    // 6°-15° approach zone with variable feedback
    
    // Timing constants
    private let requiredHoldTime: TimeInterval = 1.5  // Time to hold alignment for culmination click
    private let feedbackUpdateInterval: TimeInterval = 0.1  // How often to update during buildup
    
    // Intensity ranges
    private let minApproachIntensity: Float = 0.1    // Weakest feedback when far from target
    private let maxApproachIntensity: Float = 0.3    // Strongest approach feedback at 5° boundary
    private let minAlignmentIntensity: Float = 0.3   // Starting intensity when entering alignment zone
    private let culminationIntensity: Float = 0.6    // Final satisfying click intensity
    
    // Haptic characteristics
    private let approachSharpness: Float = 0.2       // Soft, gentle approach feedback
    private let alignmentSharpness: Float = 0.3      // Slightly crisper during buildup
    private let culminationSharpness: Float = 0.4    // Satisfying click sharpness
    
    // MARK: - State Management
    
    private var hapticEngine: CHHapticEngine?
    private var alignmentStartTime: Date?
    private var isInDeadZone = false
    private var hasTriggeredCulmination = false
    private var feedbackTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupHapticEngine()
    }
    
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
    
    // MARK: - Main Feedback Method
    
    func updateAlignmentFeedback(degreesOffTarget: Double) {
        let absAlignment = abs(degreesOffTarget)
        
        // Check if we're in dead zone (already clicked and staying aligned)
        if isInDeadZone && absAlignment <= deadZoneRange {
            return // No feedback while in dead zone
        }
        
        // Exit dead zone if we've moved too far
        if isInDeadZone && absAlignment > deadZoneRange {
            exitDeadZone()
        }
        
        // Determine which zone we're in
        if absAlignment <= alignmentZoneRange {
            handleAlignmentZone(degreesOffTarget: absAlignment)
        } else if absAlignment <= approachZoneRange {
            handleApproachZone(degreesOffTarget: absAlignment)
        } else {
            handleOutOfRange()
        }
    }
    
    // MARK: - Zone Handling
    
    private func handleAlignmentZone(degreesOffTarget: Double) {
        // Start timing if we just entered alignment zone
        if alignmentStartTime == nil {
            alignmentStartTime = Date()
            startAlignmentFeedback()
        }
        
        let holdDuration = Date().timeIntervalSince(alignmentStartTime!)
        
        // Check if we've held long enough for culmination
        if holdDuration >= requiredHoldTime && !hasTriggeredCulmination {
            triggerCulminationClick()
        } else {
            // Provide buildup feedback based on accuracy and hold time
            let buildupIntensity = calculateAlignmentBuildup(
                degreesOffTarget: degreesOffTarget,
                holdDuration: holdDuration
            )
            provideBuildupFeedback(intensity: buildupIntensity)
        }
    }
    
    private func handleApproachZone(degreesOffTarget: Double) {
        // Reset alignment timing since we're not precisely aligned
        resetAlignmentState()
        
        // Provide variable approach feedback
        let approachIntensity = calculateApproachIntensity(degreesOffTarget: degreesOffTarget)
        provideApproachFeedback(intensity: approachIntensity)
    }
    
    private func handleOutOfRange() {
        resetAlignmentState()
        stopAllFeedback()
    }
    
    // MARK: - Feedback Calculations
    
    private func calculateApproachIntensity(degreesOffTarget: Double) -> Float {
        // Linear interpolation: 15° = min intensity, 5° = max intensity
        let normalizedDistance = (degreesOffTarget - alignmentZoneRange) / (approachZoneRange - alignmentZoneRange)
        let clampedDistance = max(0.0, min(1.0, normalizedDistance))
        
        return minApproachIntensity + Float(1.0 - clampedDistance) * (maxApproachIntensity - minApproachIntensity)
    }
    
    private func calculateAlignmentBuildup(degreesOffTarget: Double, holdDuration: TimeInterval) -> Float {
        // Combine accuracy and hold time for buildup intensity
        let accuracyFactor = Float(1.0 - (degreesOffTarget / alignmentZoneRange)) // Better accuracy = higher intensity
        let timeFactor = Float(min(1.0, holdDuration / requiredHoldTime)) // Longer hold = higher intensity
        
        let baseIntensity = minAlignmentIntensity + (culminationIntensity - minAlignmentIntensity) * timeFactor
        return baseIntensity * (0.7 + 0.3 * accuracyFactor) // Accuracy fine-tunes the base
    }
    
    // MARK: - Haptic Feedback Generation
    
    private func provideApproachFeedback(intensity: Float) {
        guard let engine = hapticEngine else { return }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: approachSharpness)
            ],
            relativeTime: 0
        )
        
        playHapticEvent(event)
    }
    
    private func startAlignmentFeedback() {
        // Start continuous feedback timer for alignment buildup
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: feedbackUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.alignmentStartTime else { return }
            
            let holdDuration = Date().timeIntervalSince(startTime)
            if holdDuration < self.requiredHoldTime {
                let intensity = Float(0.3 + 0.3 * (holdDuration / self.requiredHoldTime))
                self.provideContinuousFeedback(intensity: intensity)
            }
        }
    }
    
    private func provideBuildupFeedback(intensity: Float) {
        // This is called during the buildup phase - could enhance with specific patterns
    }
    
    private func provideContinuousFeedback(intensity: Float) {
        guard let engine = hapticEngine else { return }
        
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: alignmentSharpness)
            ],
            relativeTime: 0,
            duration: feedbackUpdateInterval
        )
        
        playHapticEvent(event)
    }
    
    private func triggerCulminationClick() {
        guard let engine = hapticEngine else { return }
        
        hasTriggeredCulmination = true
        stopAllFeedback()
        
        // Create satisfying culmination click
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: culminationIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: culminationSharpness)
            ],
            relativeTime: 0
        )
        
        playHapticEvent(event)
        enterDeadZone()
    }
    
    private func playHapticEvent(_ event: CHHapticEvent) {
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic event: \(error)")
        }
    }
    
    // MARK: - State Management Methods
    
    private func resetAlignmentState() {
        alignmentStartTime = nil
        stopAllFeedback()
    }
    
    private func enterDeadZone() {
        isInDeadZone = true
        resetAlignmentState()
    }
    
    private func exitDeadZone() {
        isInDeadZone = false
        hasTriggeredCulmination = false
    }
    
    private func stopAllFeedback() {
        feedbackTimer?.invalidate()
        feedbackTimer = nil
    }
    
    // MARK: - Public Methods
    
    func resetAllState() {
        exitDeadZone()
        resetAlignmentState()
    }
    
    deinit {
        stopAllFeedback()
    }
}
