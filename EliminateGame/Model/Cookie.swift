//
//  Cookie.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/23.
//
//

import SpriteKit


enum CookieType: Int, CustomStringConvertible {
  
  case unknown = 0, one, two, three, four, five, six
  
  var spriteName: String {
    
    var spriteNames : [String]
    
    switch Configuration.shared.themeType {
    case .dessert:    //羊角面包     杯子蛋糕    丹麦面包    甜甜圈     马卡龙        糖果饼干
      spriteNames = ["Croissant", "Cupcake", "Danish", "Donut", "Macaroon", "SugarCookie"]
      
    case .band:
      spriteNames = ["Drums", "ElectricGuitar", "Microphone", "Piano", "Saxophone", "Violin"]
      
    case .pets:
      spriteNames = ["unknown", "unknown", "unknown", "unknown", "unknown", "unknown"]
    }
    
    return spriteNames[rawValue - 1]
  }
  
  var highlightedSpriteName: String {
      return spriteName + "-Highlighted"
  }
  
  var description: String {
      return spriteName
  }
  
  static func random() -> CookieType {
      return CookieType(rawValue: Int(arc4random_uniform(5) + 1))!
  }
}



class Cookie : CustomStringConvertible, Hashable {
    
  var column : Int
  var row : Int
  var cookieType : CookieType
  var sprite : SKSpriteNode?
  
//  deinit {
//    print("<deinit> - Cookie - \(self)")
//  }
  init(column: Int, row: Int, cookieType: CookieType) {
      self.column = column
      self.row = row
      self.cookieType = cookieType
  }
  
  // MARK:CustomStringConvertible
  var description: String {
      return "type:\(cookieType) square:(\(column),\(row))"
  }
  
  // MARK:Hashable
  var hashValue: Int {
      return row * 10 + column
  }
    
}

// MARK:Equatable
func ==(lhs: Cookie, rhs: Cookie) -> Bool {
  return lhs.column == rhs.column && lhs.row == rhs.row
}








