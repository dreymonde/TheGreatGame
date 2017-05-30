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
    
    func template(for match: Match.Full, family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        return producer(for: family)(match)
    }
    
    private func producer(for family: CLKComplicationFamily) -> (Match.Full) -> CLKComplicationTemplate? {
        switch family {
        case .modularSmall:
            return modularSmallTemplate(for:)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return utilitarianSmallTemplate(for:)
        case .utilitarianLarge:
            return utilitarianLargeTemplate(for:)
        case .circularSmall:
            return circularSmallTemplate(for:)
        case .extraLarge:
            return extraLargeTemplate(for:)
        case .modularLarge:
            return modularLargeTemplate(for:)
        }
    }
    
    private func nope(match: Match.Full) -> CLKComplicationTemplate? {
        return nil
    }
    
    private func utilitarianSmallTemplate(for match: Match.Full) -> CLKComplicationTemplate? {
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
    
    private func utilitarianLargeTemplate(for match: Match.Full) -> CLKComplicationTemplate? {
        if let score = match.score {
            var text = "\(match.home.shortName) \(score.demo_string) \(match.away.shortName)"
            if match.isEnded {
                text.append(" (FT)")
            }
            let shortText = "\(match.home.shortName.firstTwoChars()) \(score.demo_string) \(match.away.shortName.firstTwoChars())"
            return CLKComplicationTemplateUtilitarianLargeFlat() <- {
                $0.textProvider = CLKSimpleTextProvider(text: text, shortText: shortText)
            }
        } else {
            let oneline = oneLineMatchTextProvider(match: match)
            let date = textProvider(for: match.date)
            return CLKComplicationTemplateUtilitarianLargeFlat() <- {
                $0.textProvider = CLKTextProvider(byJoining: oneline, andProvider: date, with: " ")
            }
        }
    }
    
    private func circularSmallTemplate(for match: Match.Full) -> CLKComplicationTemplate? {
        if let score = match.score {
            return CLKComplicationTemplateCircularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = scoreTextProvider(score)
            }
        } else {
            return CLKComplicationTemplateCircularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date)
            }
        }
    }
    
    private func extraLargeTemplate(for match: Match.Full) -> CLKComplicationTemplate? {
        if let score = match.score {
            return CLKComplicationTemplateExtraLargeColumnsText() <- {
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.shortName)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.shortName)
                $0.row1Column2TextProvider = scoreTextProvider(score.home)
                $0.row2Column2TextProvider = scoreTextProvider(score.away)
            }
        } else {
            return CLKComplicationTemplateExtraLargeStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date)
            }
        }
    }
    
    private func modularSmallTemplate(for match: Match.Full) -> CLKComplicationTemplate? {
        if let score = match.score {
            return CLKComplicationTemplateModularSmallColumnsText() <- {
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.shortName)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.shortName)
                $0.row1Column2TextProvider = scoreTextProvider(score.home)
                $0.row2Column2TextProvider = scoreTextProvider(score.away)
            }
        } else {
            return CLKComplicationTemplateModularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date)
            }
        }
    }
    
    private func modularLargeTemplate(for match: Match.Full) -> CLKComplicationTemplate? {
        if let score = match.score {
            return CLKComplicationTemplateModularLargeTable() <- {
                $0.headerTextProvider = CLKSimpleTextProvider(text: match.events.last?.text ?? match.stageTitle)
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.name)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.name)
                $0.row1Column2TextProvider = scoreTextProvider(score.home)
                $0.row2Column2TextProvider = scoreTextProvider(score.away)
            }
        } else {
            return CLKComplicationTemplateModularLargeStandardBody() <- {
                $0.headerTextProvider = longestOneLineMatchTextProvider(match: match)
                $0.body1TextProvider = CLKSimpleTextProvider(text: match.stageTitle)
                $0.body2TextProvider = textProvider(for: match.date)
            }
        }
    }
    
    private func scoreTextProvider(_ score: Match.Score) -> CLKSimpleTextProvider {
        return CLKSimpleTextProvider(text: score.demo_string)
    }
    
    private func scoreTextProvider(_ score: Int) -> CLKSimpleTextProvider {
        return CLKSimpleTextProvider(text: score < 0 ? "?" : String(score))
    }
    
    private func longestOneLineMatchTextProvider(match: Match.Full) -> CLKSimpleTextProvider {
        let text = "\(match.home.name) vs \(match.away.name)"
        let shortText = "\(match.home.shortName) vs \(match.away.shortName)"
        return CLKSimpleTextProvider(text: text, shortText: shortText)
    }
    
    private func oneLineMatchTextProvider(match: Match.Full) -> CLKSimpleTextProvider {
        let text = "\(match.home.shortName):\(match.away.shortName)"
        let shortText = "\(match.home.shortName.firstTwoChars()):\(match.away.shortName.firstTwoChars())"
        return CLKSimpleTextProvider(text: text, shortText: shortText)
    }
    
    private func shortestOneLineMatchTextProvider(match: Match.Full) -> CLKSimpleTextProvider {
        let text = "\(match.home.shortName.firstTwoChars()):\(match.away.shortName.firstTwoChars())"
        let homeOnly = "\(match.home.shortName)"
        return CLKSimpleTextProvider(text: text, shortText: homeOnly)
    }
    
    private func textProvider(for date: Date) -> CLKTextProvider {
        return CLKTimeTextProvider(date: date)
//        if Calendar.current.isDateInToday(date) {
//            return CLKTimeTextProvider(date: date)
//        } else {
//            return CLKDateTextProvider(date: date, units: [.month, .day])
//        }
    }
    
}

extension String {
    
    fileprivate func firstTwoChars() -> String {
        return substring(to: index(startIndex, offsetBy: 2))
    }
    
}

