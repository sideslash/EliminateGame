//
//  Swap.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/26.
//
//

import Foundation

struct Swap : CustomStringConvertible, Hashable {
    
    var cookieA : Cookie
    var cookieB : Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    // MARK:CustomStringConvertible
    var description: String {
        return "swap \(cookieA) with \(cookieB)"
    }
    
    // MARK:Hashable
    var hashValue: Int {
        return cookieA.hashValue ^ cookieB.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB) ||
           (lhs.cookieB == rhs.cookieA && lhs.cookieA == rhs.cookieB)
}
