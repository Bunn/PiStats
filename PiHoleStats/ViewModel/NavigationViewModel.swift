//
//  ViewNavigationModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 10/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import Combine

enum NavigationItem {
    case summary
    case settings
}

class NavigationViewModel: ObservableObject {
    private var didChange = PassthroughSubject<Void, Never>()
    
    @Published var currentNavigationItem: NavigationItem = .summary {
        didSet {
            didChange.send()
        }
    }
}
