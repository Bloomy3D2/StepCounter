//
//  AnalyticsManager.swift
//  ChallengeApp
//
//  Minimal internal analytics (Supabase table: public.analytics_events)
//

import Foundation

actor AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private let sessionId = UUID()
    private var didTrackSessionStart = false
    
    private init() { }
    
    /// Tracks a session start exactly once per app launch.
    func trackSessionStartIfNeeded() async {
        guard !didTrackSessionStart else { return }
        
        // If there is no Supabase session yet, don't burn the "once" attempt.
        // We'll retry later on the next call.
        do {
            _ = try await SupabaseManager.shared.supabase.auth.session
        } catch {
            return
        }
        
        didTrackSessionStart = true
        await track("session_start")
    }
    
    /// Best-effort event tracking. Never throws, never blocks UI.
    func track(
        _ eventName: String,
        challengeId: Int64? = nil,
        amount: Double? = nil,
        props: [String: String] = [:]
    ) async {
        guard AppConfig.isConfigured else { return }
        
        var merged = props
        for (k, v) in Self.baseProps() where merged[k] == nil {
            merged[k] = v
        }
        
        await SupabaseManager.shared.trackEvent(
            eventName: eventName,
            sessionId: sessionId,
            challengeId: challengeId,
            amount: amount,
            props: merged
        )
    }
    
    private static func baseProps() -> [String: String] {
        var props: [String: String] = [:]
        
        let info = Bundle.main.infoDictionary
        if let version = info?["CFBundleShortVersionString"] as? String {
            props["app_version"] = version
        }
        if let build = info?["CFBundleVersion"] as? String {
            props["app_build"] = build
        }
        
        props["platform"] = "ios"
        props["os_version"] = ProcessInfo.processInfo.operatingSystemVersionString
        props["locale"] = Locale.current.identifier
        props["tz"] = TimeZone.current.identifier
        
        return props
    }
}

