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
    private let alignmentZoneRange: Double = 5.0    // ±5° alignment zone for timing buildup
    private let precisionZoneRange: Double = 2.0    // ±2° precision zone for final click
    private let approachZoneRange: Double = 15.0    // 6°-15° approach zone with variable feedback
    
    // Timing constants
    private let requiredHoldTime: TimeInterval = 1.5  // Total time to hold for culmination click
    private let precisionHoldTime: TimeInterval = 0.3  // Final time that must be in precision zone
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
    private var precisionStartTime: Date?
    private var isInDeadZone = false
    private var hasTriggeredCulmination = false
    private var feedbackTimer: Timer?
    private var currentTimeProgress: Double = 0.0
    
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
    
    // MARK: - Main Feedback Method
    
    /// Main haptic feedback method based on compass alignment
    func updateAlignmentFeedback(degreesOffTarget: Double) {
        let absAlignment = abs(degreesOffTarget)
        
        // Check if we're in dead zone (already clicked and staying aligned)
        if (isInDeadZone) {
            // Exit dead zone if we've moved out
            if (absAlignment > approachZoneRange) {
                exitDeadZone()
            } else {    // no feedback in dead zone
                return;
            }
        }
        
        // Determine which zone we're in
        if absAlignment <= approachZoneRange {
            handleFeedbackZone(degreesOffTarget: absAlignment)
        } else {
            handleOutOfRange()
        }
    }
    
    // MARK: - Zone Handling
    
    /// Handles all feedback zones with unified distance + timing logic
    private func handleFeedbackZone(degreesOffTarget: Double) {
        // Calculate base intensity from distance (15° → 0°) - ALWAYS
        let distanceIntensity = calculateDistanceIntensity(degreesOffTarget: degreesOffTarget)
        
        if degreesOffTarget <= alignmentZoneRange { // 0°-5°
            // Start timing if we just entered alignment zone
            if alignmentStartTime == nil {
                alignmentStartTime = Date()
                startAlignmentFeedback()
            }
            
            // Add alignment timing component
            let alignmentTimeMultiplier = calculateAlignmentTimeMultiplier(degreesOffTarget: degreesOffTarget)
            let finalIntensity = distanceIntensity * alignmentTimeMultiplier
            provideFeedback(intensity: finalIntensity)
            
            // Check for culmination
            checkForCulmination(degreesOffTarget: degreesOffTarget)
        } else { // 6°-15°
            // Reset alignment timing
            resetAlignmentTiming()
            
            // Just use base distance intensity
            provideFeedback(intensity: distanceIntensity)
        }
    }
    
    /// Handles when user is out of feedback range (>15°)
    private func handleOutOfRange() {
        resetAlignmentState()
        stopAllFeedback()
    }
    
    // MARK: - Feedback Calculations
    
    /// Calculates base intensity from distance (consistent 15° → 0° curve)
    private func calculateDistanceIntensity(degreesOffTarget: Double) -> Float {
        // Linear from 15° (min) to 0° (max)
        let normalizedDistance = min(1.0, degreesOffTarget / approachZoneRange)
        return minApproachIntensity + Float(1.0 - normalizedDistance) * (maxApproachIntensity - minApproachIntensity)
    }
    
    /// Calculates timing multiplier for alignment zone (handles 80% cap + precision zone)
    private func calculateAlignmentTimeMultiplier(degreesOffTarget: Double) -> Float {
        let holdDuration = Date().timeIntervalSince(alignmentStartTime!)
        let inPrecisionZone = degreesOffTarget <= precisionZoneRange
        
        // Calculate time progress with 80% cap logic
        let baseHoldTime = requiredHoldTime - precisionHoldTime // 1.2 seconds
        
        if inPrecisionZone {
            // In precision zone - can build beyond 80%
            if precisionStartTime == nil {
                precisionStartTime = Date()
            }
            let precisionDuration = Date().timeIntervalSince(precisionStartTime!)
            let totalProgress = min(1.0, (baseHoldTime + precisionDuration) / requiredHoldTime)
            currentTimeProgress = totalProgress     //**currentTimeProgress should be set to 0 when we exitAlignmentZone
        } else {
            // Not in precision zone - cap at 80% (1.2s / 1.5s)
            let cappedProgress = min(0.8, holdDuration / requiredHoldTime)
            
            currentTimeProgress = cappedProgress
            
            precisionStartTime = nil
        }
        
        // Convert progress to multiplier (1.0 = base, up to 2.0 = max buildup)
        return Float(1.0 + currentTimeProgress)
    }
    
    /// Checks if culmination click should happen
    private func checkForCulmination(degreesOffTarget: Double) {
        let inPrecisionZone = degreesOffTarget <= precisionZoneRange
        
        if inPrecisionZone && precisionStartTime != nil && !hasTriggeredCulmination {
            let precisionDuration = Date().timeIntervalSince(precisionStartTime!)
            if precisionDuration >= precisionHoldTime {
                triggerCulminationClick()
            }
        }
    }
    
    /// Resets alignment timing but preserves some state
    private func resetAlignmentTiming() {
        alignmentStartTime = nil
        precisionStartTime = nil
        currentTimeProgress = 0.0
        hasTriggeredCulmination = false
        stopAllFeedback()
    }
    
    // MARK: - Haptic Feedback Generation
    
    /// Provides unified haptic feedback for all zones
    private func provideFeedback(intensity: Float) {
        guard let engine = hapticEngine else { return }
        
        let clampedIntensity = min(culminationIntensity, max(minApproachIntensity, intensity))
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: alignmentSharpness)
            ],
            relativeTime: 0
        )
        
        playHapticEvent(event)
    }
    

    
    /// Starts timer for continuous alignment feedback
    private func startAlignmentFeedback() {
        // Start continuous feedback timer for alignment buildup
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: feedbackUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.alignmentStartTime else { return }
            
            let holdDuration = Date().timeIntervalSince(startTime)
            if holdDuration < self.requiredHoldTime {
                let intensityDiff = culminationIntensity - minAlignmentIntensity
                let intensity = minAlignmentIntensity + intensityDiff * Float((holdDuration / self.requiredHoldTime))
                self.provideContinuousFeedback(intensity: intensity)
            }
        }
    }
    
    /// Provides buildup feedback during alignment zone
    private func provideBuildupFeedback(intensity: Float) {
        guard let engine = hapticEngine else { return }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: alignmentSharpness)
            ],
            relativeTime: 0
        )
        
        playHapticEvent(event)
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
    
    /// Triggers the satisfying culmination click
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
        precisionStartTime = nil
        currentTimeProgress = 0.0
        hasTriggeredCulmination = false
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
    
    /// Resets all haptic state for new destination
    func resetAllState() {
        exitDeadZone()
        resetAlignmentState()
    }
    
    deinit {
        stopAllFeedback()
    }
}
