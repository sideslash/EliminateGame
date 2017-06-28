//
//  Chain.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/27.
//
//

import Foundation


class Chain: Hashable, CustomStringConvertible {
  
  var cookies = [Cookie]()

  var score = 0
  
  enum ChainType: CustomStringConvertible {
    case horizontal
    case vertical
    var description: String {
      switch self {
      case .horizontal:  return "Horizontal"
      case .vertical:  return "Vertical"
      }
    }
  }
  
  var chainType: ChainType
  
  init(chainType: ChainType) {
    self.chainType = chainType
  }
  
  func add(cookie: Cookie) {
    cookies.append(cookie)
  }
  
  func firstCookie() -> Cookie {
    return cookies[0]
  }
  
  func lastCookie() -> Cookie {
    return cookies[cookies.count - 1]
  }
  
  func length() -> Int {
    return cookies.count
  }
  
  // MARK:CustomStringConvertible
  var description: String {
    return "chainType:\(chainType), cookies:\(cookies)"
  }
  
  // MARK:Hashable
  var hashValue: Int {
    return cookies.reduce(0){ return $0.hashValue ^ $1.hashValue}
  }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
  return lhs.cookies == rhs.cookies
}

