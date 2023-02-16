//
//  Version+Revision.swift
//  Harmony-Drive
//
//  Created by Riley Testut on 11/20/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

import Harmony

import GoogleAPIClientForREST_Drive
import GoogleAPIClientForRESTCore

extension Version {
    init?(revision: GTLRDrive_Revision) {
        guard
            let identifier = revision.identifier,
            let date = revision.modifiedTime?.date
        else { return nil }

        self.init(identifier: identifier, date: date)
    }
}
