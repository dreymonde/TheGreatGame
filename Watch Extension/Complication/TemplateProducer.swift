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
    
    let tintColor = UIColor.init(named: .navigationBackground)
    
    func template(for match: Match.Full, aforetime: Bool, family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        return producer(for: family)(match, aforetime)
    }
    
    private func producer(for family: CLKComplicationFamily) -> (Match.Full, Bool) -> CLKComplicationTemplate? {
        switch family {
        case .modularSmall:
            return modularSmallTemplate(for:aforetime:)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return utilitarianSmallTemplate(for:aforetime:)
        case .utilitarianLarge:
            return utilitarianLargeTemplate(for:aforetime:)
        case .circularSmall:
            return circularSmallTemplate(for:aforetime:)
        case .extraLarge:
            return extraLargeTemplate(for:aforetime:)
        case .modularLarge:
            return modularLargeTemplate(for:aforetime:)
        }
    }
    
    private func nope(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        return nil
    }
    
    private func utilitarianSmallTemplate(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        if match.score != nil {
            let appendPenalty: (inout String) -> () = {
                if match.isPenaltiesAppointed {
                    $0.append(" P")
                }
            }
            var text = "\(match.home.shortName) \(match.scoreOrPenaltyString()) \(match.away.shortName)"
            appendPenalty(&text)
            var shortText = "\(match.home.shortestName) \(match.scoreOrPenaltyString()) \(match.away.shortestName)"
            appendPenalty(&shortText)
            return CLKComplicationTemplateUtilitarianSmallFlat() <- {
                $0.textProvider = CLKSimpleTextProvider(text: text, shortText: shortText)
                //$0.imageProvider = imageProvider(forSize: ._18)
                $0.tintColor = tintColor
            }
        } else {
            let oneline = shortestOneLineMatchTextProvider(match: match)
            let date = textProvider(for: match.date, aforetime: aforetime)
            return CLKComplicationTemplateUtilitarianSmallFlat() <- {
                $0.textProvider = CLKTextProvider(byJoining: oneline, andProvider: date, with: " ")
                //$0.imageProvider = imageProvider(forSize: ._18)
                $0.tintColor = tintColor
            }
        }
    }
    
    private func utilitarianLargeTemplate(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        if match.score != nil {
            var s = "\(match.home.shortName) \(match.scoreOrPenaltyString()) \(match.away.shortName)"
            if match.isEnded {
                if match.isPenaltiesAppointed {
                    s.append(" P (FT)")
                } else {
                    s.append(" (FT)")
                }
            }
            if match.isInHalfTime {
                s.append(" (HT)")
            }
            if match.isExtraTime {
                s.append(" ET")
            }
            if match.isPenalties {
                s.append(" PEN")
            }
            let text = s
            var shs = "\(match.home.shortestName) \(match.scoreOrPenaltyString()) \(match.away.shortestName)"
            if match.isPenalties {
                shs.append(" P")
            }
            let shortText = shs
            return CLKComplicationTemplateUtilitarianLargeFlat() <- {
                $0.textProvider = CLKSimpleTextProvider(text: text, shortText: shortText)
                $0.imageProvider = imageProvider(forSize: ._18)
                $0.tintColor = tintColor
            }
        } else {
            let oneline = oneLineMatchTextProvider(match: match)
            let date = textProvider(for: match.date, aforetime: aforetime)
            return CLKComplicationTemplateUtilitarianLargeFlat() <- {
                $0.textProvider = CLKTextProvider(byJoining: oneline, andProvider: date, with: " ")
                $0.imageProvider = imageProvider(forSize: ._18)
                $0.tintColor = tintColor
            }
        }
    }
    
    private func circularSmallTemplate(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        if match.score != nil {
            return CLKComplicationTemplateCircularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = scoreTextProvider(in: match)
                $0.tintColor = tintColor
            }
        } else {
            return CLKComplicationTemplateCircularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date, aforetime: aforetime)
                $0.tintColor = tintColor
            }
        }
    }
    
    private func extraLargeTemplate(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        if let score = match.score {
            var displayScore: Match.Score = score
            if match.isPenaltiesAppointed {
                displayScore = match.penalties ?? score
            }
            return CLKComplicationTemplateExtraLargeColumnsText() <- {
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.shortName)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.shortName)
                $0.row1Column2TextProvider = scoreTextProvider(displayScore.home)
                $0.row2Column2TextProvider = scoreTextProvider(displayScore.away)
                $0.tintColor = tintColor
            }
        } else {
            return CLKComplicationTemplateExtraLargeStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date, aforetime: aforetime)
                $0.tintColor = tintColor
            }
        }
    }
    
    private func modularSmallTemplate(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        if let score = match.score {
            var displayScore: Match.Score = score
            if match.isPenaltiesAppointed {
                displayScore = match.penalties ?? score
            }
            return CLKComplicationTemplateModularSmallColumnsText() <- {
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.shortName)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.shortName)
                $0.row1Column2TextProvider = scoreTextProvider(displayScore.home)
                $0.row2Column2TextProvider = scoreTextProvider(displayScore.away)
                $0.tintColor = tintColor
            }
        } else {
            return CLKComplicationTemplateModularSmallStackText() <- {
                $0.line1TextProvider = shortestOneLineMatchTextProvider(match: match)
                $0.line2TextProvider = textProvider(for: match.date, aforetime: aforetime)
                $0.tintColor = tintColor
            }
        }
    }
    
    private func modularLargeTemplate(for match: Match.Full, aforetime: Bool) -> CLKComplicationTemplate? {
        if let score = match.score {
            var displayScore: Match.Score = score
            if match.isPenaltiesAppointed {
                displayScore = match.penalties ?? score
            }
            return CLKComplicationTemplateModularLargeTable() <- {
                $0.headerTextProvider = CLKSimpleTextProvider(text: matchState(match))
                $0.row1Column1TextProvider = CLKSimpleTextProvider(text: match.home.name)
                $0.row2Column1TextProvider = CLKSimpleTextProvider(text: match.away.name)
                $0.row1Column2TextProvider = scoreTextProvider(displayScore.home)
                $0.row2Column2TextProvider = scoreTextProvider(displayScore.away)
                $0.column2Alignment = .trailing
                $0.tintColor = tintColor
            }
        } else {
            return CLKComplicationTemplateModularLargeStandardBody() <- {
                $0.headerTextProvider = longestOneLineMatchTextProvider(match: match)
                $0.body1TextProvider = CLKSimpleTextProvider(text: match.stageTitle)
                $0.body2TextProvider = textProvider(for: match.date, aforetime: aforetime)
                $0.tintColor = tintColor
            }
        }
    }
    
    private func matchState(_ match: Match.Full) -> String {
        if match.isInHalfTime {
            return "Half-time"
        }
        if match.isExtraTime {
            return "Extra time"
        }
        if match.isPenalties {
            return "PEN " + (match.events.last?.text ?? "Penalties")
        }
        if match.isEnded {
            return "(FT) " + (match.events.last?.text ?? "")
        }
        return match.events.last?.text ?? "Live"
    }
    
    private func scoreTextProvider(in match: Match.Full) -> CLKSimpleTextProvider {
        var scoreString = match.scoreOrPenaltyString()
        if match.isPenaltiesAppointed {
            scoreString.append(" P")
        }
        return CLKSimpleTextProvider(text: scoreString)
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
        let shortText = "\(match.home.shortestName):\(match.away.shortestName)"
        return CLKSimpleTextProvider(text: text, shortText: shortText)
    }
    
    private func shortestOneLineMatchTextProvider(match: Match.Full) -> CLKSimpleTextProvider {
        let text = "\(match.home.shortestName):\(match.away.shortestName)"
        let homeOnly = "\(match.home.shortName)"
        return CLKSimpleTextProvider(text: text, shortText: homeOnly)
    }
    
    private enum ImageSize38 {
        case _18
    }
    
    private func imageProvider(forSize size: ImageSize38) -> CLKImageProvider {
        switch size {
        case ._18:
            let bound = WKInterfaceDevice.current().screenBounds
            if bound.width > 136.0 {
                return CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "compicon40"))
            } else {
                return CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "compicon36"))
            }
        }
    }
    
    private func textProvider(for date: Date, aforetime: Bool) -> CLKTextProvider {
        if !aforetime {
            return CLKTimeTextProvider(date: date)
        } else {
            print("Aforetime template!")
            return CLKDateTextProvider(date: date, units: [.month, .day])
        }
    }
    
}
