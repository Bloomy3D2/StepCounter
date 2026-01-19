//
//  StepComplication.swift
//  StepCounter Watch App
//
//  Complications для циферблата Apple Watch
//

import ClockKit
import SwiftUI
import HealthKit

// MARK: - Complication Controller

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "stepCounter",
                displayName: "Шагомер",
                supportedFamilies: [
                    .circularSmall,
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianSmallFlat,
                    .utilitarianLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicExtraLarge
                ]
            )
        ]
        handler(descriptors)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Обновляем до конца дня
        let endOfDay = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        handler(endOfDay)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        fetchStepData { steps, goal in
            let template = self.createTemplate(for: complication.family, steps: steps, goal: goal)
            if let template = template {
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                handler(entry)
            } else {
                handler(nil)
            }
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createTemplate(for: complication.family, steps: 7500, goal: 10000)
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(for family: CLKComplicationFamily, steps: Int, goal: Int) -> CLKComplicationTemplate? {
        let progress = Double(steps) / Double(goal)
        let accentGreen = UIColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1.0)
        
        switch family {
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "\(steps / 1000)k"),
                fillFraction: Float(progress),
                ringStyle: .closed
            )
            
        case .modularSmall:
            return CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "\(steps / 1000)k"),
                fillFraction: Float(progress),
                ringStyle: .closed
            )
            
        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Шагомер"),
                body1TextProvider: CLKSimpleTextProvider(text: "\(steps) шагов"),
                body2TextProvider: CLKSimpleTextProvider(text: "Цель: \(goal)")
            )
            
        case .utilitarianSmall:
            return CLKComplicationTemplateUtilitarianSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "\(steps / 1000)k"),
                fillFraction: Float(progress),
                ringStyle: .closed
            )
            
        case .utilitarianSmallFlat:
            return CLKComplicationTemplateUtilitarianSmallFlat(
                textProvider: CLKSimpleTextProvider(text: "🚶 \(steps)")
            )
            
        case .utilitarianLarge:
            return CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "🚶 \(steps) / \(goal)")
            )
            
        case .graphicCorner:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: accentGreen,
                fillFraction: Float(progress)
            )
            return CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: gaugeProvider,
                outerTextProvider: CLKSimpleTextProvider(text: "\(steps)")
            )
            
        case .graphicCircular:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .ring,
                gaugeColor: accentGreen,
                fillFraction: Float(progress)
            )
            return CLKComplicationTemplateGraphicCircularClosedGaugeText(
                gaugeProvider: gaugeProvider,
                centerTextProvider: CLKSimpleTextProvider(text: "\(steps / 1000)k")
            )
            
        case .graphicRectangular:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: accentGreen,
                fillFraction: Float(progress)
            )
            return CLKComplicationTemplateGraphicRectangularTextGauge(
                headerTextProvider: CLKSimpleTextProvider(text: "Шагомер"),
                body1TextProvider: CLKSimpleTextProvider(text: "\(steps) из \(goal)"),
                gaugeProvider: gaugeProvider
            )
            
        case .graphicExtraLarge:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .ring,
                gaugeColor: accentGreen,
                fillFraction: Float(progress)
            )
            return CLKComplicationTemplateGraphicExtraLargeCircularClosedGaugeText(
                gaugeProvider: gaugeProvider,
                centerTextProvider: CLKSimpleTextProvider(text: "\(steps)")
            )
            
        default:
            return nil
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchStepData(completion: @escaping (Int, Int) -> Void) {
        let healthStore = HKHealthStore()
        
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0, 10000)
            return
        }
        
        let goal = UserDefaults.standard.integer(forKey: "stepGoal")
        let finalGoal = goal > 0 ? goal : 10000
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let steps: Int
            if let sum = result?.sumQuantity() {
                steps = Int(sum.doubleValue(for: .count()))
            } else {
                steps = 0
            }
            completion(steps, finalGoal)
        }
        
        healthStore.execute(query)
    }
}

// MARK: - SwiftUI Complication Views (for watchOS 9+)

struct CircularComplicationView: View {
    let steps: Int
    let goal: Int
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(goal))
    }
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        Gauge(value: progress) {
            Text("\(steps / 1000)k")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(accentGreen)
    }
}

struct RectangularComplicationView: View {
    let steps: Int
    let goal: Int
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(goal))
    }
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(accentGreen)
                Text("Шагомер")
                    .font(.system(size: 12, weight: .bold))
            }
            
            Text("\(steps) из \(goal)")
                .font(.system(size: 14, weight: .medium))
            
            Gauge(value: progress) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            .tint(accentGreen)
        }
    }
}

struct CornerComplicationView: View {
    let steps: Int
    let goal: Int
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(goal))
    }
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        VStack {
            Text("\(steps)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            Gauge(value: progress) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            .tint(accentGreen)
        }
    }
}

// MARK: - Preview

#Preview("Circular") {
    CircularComplicationView(steps: 7500, goal: 10000)
}

#Preview("Rectangular") {
    RectangularComplicationView(steps: 7500, goal: 10000)
}
