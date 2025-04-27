//
//  Entity + Extension.swift
//  Visiolingo
//
//  Created by Syrine Aidani on 26.04.25.
//

//from: https://github.com/sarangborude/Dinopedia


import RealityKit

extension Entity {
    func enumerateHierarchy(_ body: (Entity, UnsafeMutablePointer<Bool>) -> Void) {
        var stop = false

        func enumerate(_ body: (Entity, UnsafeMutablePointer<Bool>) -> Void) {
            guard !stop else {
                return
            }

            body(self, &stop)
            
            for child in children {
                guard !stop else {
                    break
                }
                child.enumerateHierarchy(body)
            }
        }
        
        enumerate(body)
    }
}
