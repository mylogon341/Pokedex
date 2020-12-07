//
//  String+Extension.swift
//  Pokedex
//
//  Created by Luke Sadler on 28/08/2020.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    var apiNameFixed: String {
        components(separatedBy: "-")
            .compactMap({ $0.capitalizingFirstLetter() })
            .joined(separator: " ")
    }
}
