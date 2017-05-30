//
//  ComplicationController.swift
//  Watch Extension
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import ClockKit
import TheGreatKit
import Shallows

extension ComplicationDataSource {
    
    public static let main = ComplicationDataSource(provider: ExtensionDelegate.watchExtension.apiCache.matches.allFull
        .asReadOnlyCache()
        .mapValues({ $0.content.matches }))

    public static let dev_macbook = ComplicationDataSource(provider: API.macBookSteve().matches.allFull
        .mapValues({ $0.content.matches }))
    
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let dataSource = ComplicationDataSource.dev_macbook
    let producer = TemplateProducer()
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        printWithContext()
        handler([.forward, .backward])
    }
    
    func getTimelineAnimationBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineAnimationBehavior) -> Void) {
        handler(.grouped)
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        printWithContext()
        dataSource.timelineStartDate(completion: handler)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        printWithContext()
        dataSource.timelineEndDate(completion: handler)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        printWithContext()
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        printWithContext()
        dataSource.currentMatch { (snapshot) in
            if let snapshot = snapshot {
                handler(self.entry(with: snapshot, for: complication))
            } else {
                handler(nil)
            }
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        printWithContext()
        dataSource.matches(before: date, limit: limit) { (matches) in
            if let matches = matches {
                handler(matches.flatMap({ self.entry(with: $0, for: complication) }))
            } else {
                handler(nil)
            }
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        printWithContext()
        dataSource.matches(after: date, limit: limit) { (matches) in
            if let matches = matches {
                handler(matches.flatMap({ self.entry(with: $0, for: complication) }))
            } else {
                handler(nil)
            }
        }
    }
    
    func entry(with match: ComplicationDataSource.MatchSnapshot, for complication: CLKComplication) -> CLKComplicationTimelineEntry? {
        if let template = producer.template(for: match.match, family: complication.family) {
            return CLKComplicationTimelineEntry(date: match.timelineDate,
                                                complicationTemplate: template,
                                                timelineAnimationGroup: printed(String(match.match.id.rawID)))
        }
        return nil
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        printWithContext()
        let sample = dataSource.placeholderMatch
        let template = producer.template(for: sample, family: complication.family)
        handler(template)
    }
    
}
