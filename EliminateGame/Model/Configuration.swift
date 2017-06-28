//
//  Configuration.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/28.
//
//

import Foundation

enum ThemeType {
  case dessert, band, pets
}

class Configuration {
  static let shared = Configuration()
  
  
  var themeType : ThemeType = .dessert
  
  init() {
    //从userdefault读取上次的主题,如果没有则使用默认的
    if let cachedTheme = UserDefaults.standard.object(forKey: "userDefaultKeyThemeType") as? ThemeType {
      themeType = cachedTheme
    }
    
  }
  
  func cacheCurrentTheme() {
    UserDefaults.standard.set(themeType, forKey: "userDefaultKeyThemeType")
    UserDefaults.standard.synchronize()
  }
  
}
