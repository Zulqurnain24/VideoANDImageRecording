//
//  UtilityFunctions.swift
//  YouVRAssignment
//
//  Created by Mohammad Zulqarnain on 09/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import UIKit

class UtilityFunctions {
    
    static var shared = UtilityFunctions()
    
    func applicationDocumentDirectory() -> NSURL? {
        return NSFileProviderManager.default.documentStorageURL as NSURL
    }
    
    func getNowDateString() -> String {
        let date :NSDate = NSDate()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MM YYYY'_'HH_mm_ss"
        
        dateFormatter.timeZone = NSTimeZone(name: "GMT") as TimeZone?
        return dateFormatter.string(from: date as Date)
    }
    
}
