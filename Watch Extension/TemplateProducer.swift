//
//  TemplateProducer.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import WatchKit
import ClockKit
import TheGreatKit

final class TemplateProducer {
    
    func template(for match: Match.Compact, family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        return producer(for: family)(match)
    }
    
    private func producer(for family: CLKComplicationFamily) -> (Match.Compact) -> CLKComplicationTemplate? {
        switch family {
        case .modularSmall:
            return modularSmallTemplate(for:)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return utilitarianSmallTemplate(for:)
        default:
            return nope(match:)
        }
    }
    
    private func nope(match: Match.Compact) -> CLKComplicationTemplate? {
        return nil
    }
    
    private func utilitarianSmallTemplate(for match: Match.Compact) -> CLKComplicationTemplate? {
        if let score = match.score {
            let text = "\(match.home.shortName) \(score.demo_string) \(match.away.shortName)"
            let shortText = "\(match.home.shortName.firstTwoChars()) \(score.demo_string) \(match.away.shortName.firstTwoChars())"
            return CLKComplicationTemplateUtilitarianSmallFlat() <- {
                $0.textProvider = CLKSimpleTextProvider(text: text, shortText: shortText)
            }
        } else {
            let oneline = shortestOneLineMatchTextProvider(match: match)
            let date = textProvider(for: match.date)
            return CLKComplicationTemplateUtilitarianSmallFlat() <- {
                $0.textProvider = CLKTextProvider(byJoining: oneline, andProvider: date, with: " ")
            }
        }
    }
    
    private func modularSmallTemplate(for match: Match.Compact) -> CLKComplicationTemplate? {
        if let score = match.score {
            return CLKComplicationTemplateModularSmallColumnsText() <- {
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.shortName)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.shortName)
                $0.row1Column2TextProvider = CLKSimpleTextProvider(text: String(score.home))
                $0.row2Column2TextProvider = CLKSimpleTextProvider(text: String(score.away))
            }
        } else {
            return CLKComplicationTemplateModularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date)
            }
        }
    }
    
    private func shortestOneLineMatchTextProvider(match: Match.Compact) -> CLKSimpleTextProvider {
        let text = "\(match.home.shortName.firstTwoChars()):\(match.away.shortName.firstTwoChars())"
        return CLKSimpleTextProvider(text: text)
    }
    
    private func textProvider(for date: Date) -> CLKTextProvider {
        if Calendar.current.isDateInToday(date) {
            return CLKTimeTextProvider(date: date)
        } else {
            return CLKDateTextProvider(date: date, units: [.month, .day])
        }
    }
    
}

extension String {
    
    fileprivate func firstTwoChars() -> String {
        return substring(to: index(startIndex, offsetBy: 2))
    }
    
}

