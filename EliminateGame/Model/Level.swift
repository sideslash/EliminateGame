//
//  Level.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/23.
//
//

import Foundation

let NumColumns = 9
let NumRows = 9
let NumLevels = 5

class Level {
  
  var targetScore = 0
  var maximumMoves = 0
  
  private var comboMultiplier = 0 
  private var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
  private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
  private var possibleSwaps = Set<Swap>()
  
  // MARK:init
  init(filename: String) {
    guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
    guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
    guard let targetScore = dictionary["targetScore"] as? Int else { return }
    guard let maximumMoves = dictionary["moves"] as? Int else { return }
    
    self.targetScore = targetScore
    self.maximumMoves = maximumMoves
  
    for (row, rowArray) in tilesArray.enumerated() {
        let tileRow = NumRows - row - 1
        for (column, value) in rowArray.enumerated() {
            if value == 1 {
                tiles[column, tileRow] = Tile()
            }
        }
    }
  }
  
  // MARK:public methods
  func cookieAt(column: Int, row: Int) -> Cookie? {
      assert(NumColumns >= 0 && column < NumColumns)
      assert(NumRows >= 0 && row < NumRows)
      return cookies[column, row]
  }
  
  func tileAt(column: Int, row: Int) -> Tile? {
      assert(column >= 0 && column < NumColumns)
      assert(row >= 0 && row < NumRows)
      return tiles[column, row]
  }
  
  func resetComboMultiplier() {
    comboMultiplier = 1
  }
  
  func shuffle() -> Set<Cookie> {
    var set: Set<Cookie>
    repeat {
      set = createInitialCookies()
      _ = detectPossibleSwaps()
      //          print("possible swaps: \(possibleSwaps)")
    } while possibleSwaps.count == 0
    
    return set
  }
  
  func isPossibleSwap(_ swap: Swap) -> Bool {
    return possibleSwaps.contains(swap)
  }
  
  func firstPossibleSwap() -> Swap? {
    return possibleSwaps.first
  }
  
  func detectPossibleSwaps() -> Int {
    var set = Set<Swap>()
  
    //从左下角0,0开始，所以每个cookie只要考虑与它右边和上面的互换情况
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if let cookie = cookies[column, row] {
          
          // right
          if column < NumColumns - 1 {
            if let other = cookies[column + 1, row] {
              // Swap them
              cookies[column, row] = other
              cookies[column + 1, row] = cookie
              
              // Is either cookie now part of a chain?
              if hasChainAt(column: column + 1, row: row) ||
                hasChainAt(column: column, row: row) {
                set.insert(Swap(cookieA: cookie, cookieB: other))
              }
              
              // Swap them back
              cookies[column, row] = cookie
              cookies[column + 1, row] = other
            }
          }
          
          //above
          if row < NumRows - 1 {
            if let other = cookies[column, row + 1] {
              cookies[column, row] = other
              cookies[column, row + 1] = cookie
              
              // Is either cookie now part of a chain?
              if hasChainAt(column: column, row: row + 1) ||
                hasChainAt(column: column, row: row) {
                set.insert(Swap(cookieA: cookie, cookieB: other))
              }
              
              // Swap them back
              cookies[column, row] = cookie
              cookies[column, row + 1] = other
            }
          }
          
        }
      }
    }
    
    possibleSwaps = set
    return possibleSwaps.count
  }

  
  func performSwap(swap: Swap) {
      let columnA = swap.cookieA.column
      let rowA = swap.cookieA.row
      let columnB = swap.cookieB.column
      let rowB = swap.cookieB.row
    
      cookies[columnA, rowA] = swap.cookieB
      swap.cookieB.column = columnA
      swap.cookieB.row = rowA
    
      cookies[columnB, rowB] = swap.cookieA
      swap.cookieA.column = columnB
      swap.cookieA.row = rowB
  }
  
  
  func removeMatches() -> Set<Chain> {
    let horizontalMatches = detectHorizontalMatches()
    let verticalMatches = detectVerticalMatches()
    
    //update model
    removeCookies(chains: horizontalMatches)
    removeCookies(chains: verticalMatches)
    
    //score
    calculateScore(for: horizontalMatches)
    calculateScore(for: verticalMatches)
    
    return horizontalMatches.union(verticalMatches)
  }
  
  //返回值为先下移动了填充空白位置的Cookie,每一列一个数组
  func fillHoles() -> [[Cookie]] {
    var set = [[Cookie]]()
    
    for column in 0..<NumColumns {
      var array = [Cookie]()
      
      for row in 0..<NumRows {
        //判断当前位置是否应该有元素，但是又没有
        if tiles[column, row] != nil && cookies[column, row] == nil {
          //循环找到在当前空白位置上方最近的一个元素，将它与当前空白内容换位
          for lookup in (row + 1)..<NumRows {
            if let cookie = cookies[column, lookup] {
              cookies[column, row] = cookie
              cookies[column, lookup] = nil
              cookie.row = row
  
              array.append(cookie)
              break;
            }
          }
        }
        
      }
      
      if !array.isEmpty {
        set.append(array)
      }
      
    }
    
    return set
  }
  
  func topUpCookies() -> [[Cookie]] {
    var set = [[Cookie]]()
    
    var cookieType: CookieType = .unknown
    
    for column in 0..<NumColumns {
      var array = [Cookie]()
      var row = NumRows - 1
      
      //从上往下填补，遇到有元素存在的就停止
      while row >= 0 && cookies[column, row] == nil {
        if tiles[column, row] != nil {
          //新建一个元素,并且新元素与上一个新元素类型不能一样
          var newCookieType: CookieType
          repeat {
            newCookieType = CookieType.random()
          } while newCookieType == cookieType
          cookieType = newCookieType
          
          let cookie = Cookie(column: column, row: row, cookieType: cookieType)
          cookies[column, row] = cookie
          array.append(cookie)
        }
        
        row -= 1
      }
      
      if !array.isEmpty {
        set.append(array)
      }
    }
    
    return set
  }
  
  // MARK:private methods
  private func calculateScore(for chains: Set<Chain>) {
    for chain in chains {//3个60分，每多1个加多60分,再乘上连击奖励倍数
      chain.score = 60 * (chain.length() - 2) * comboMultiplier
      comboMultiplier += 1
    }
  }
  
  private func removeCookies(chains: Set<Chain>) {
    for chain in chains {
      for cookie in chain.cookies {
//        print("remove cookie : \(cookies[cookie.column, cookie.row])")
        cookies[cookie.column, cookie.row] = nil
//        print("removed cookie : \(cookies[cookie.column, cookie.row])")
      }
    }
  }
  
  private func detectHorizontalMatches() -> Set<Chain> {
    var set = Set<Chain>()
    
    for row in 0..<NumRows {
      var column = 0
      
      while column < NumColumns - 2 {//最后两列的作为起点无法连成线,所以不用检测
        if let cookie = cookies[column, row] {
          let matchType = cookie.cookieType
          
          if cookies[column + 1, row]?.cookieType == matchType &&
             cookies[column + 2, row]?.cookieType == matchType {
            
            let chain = Chain(chainType: .horizontal)
            repeat {
              chain.add(cookie: cookies[column, row]!)
              column += 1
            } while (column < NumColumns) && (cookies[column, row]?.cookieType == matchType)
            
            set.insert(chain)
            continue
          }
          
        }
        
        column += 1
      }
      
    }
    return set
  }
  
  private func detectVerticalMatches() -> Set<Chain> {
    var set = Set<Chain>()
    
    for column in 0..<NumColumns {
      var row = 0
      
      while row < NumRows - 2 {
        if let cookie = cookies[column, row] {
          let matchType = cookie.cookieType
          
          if cookies[column, row + 1]?.cookieType == matchType &&
             cookies[column, row + 2]?.cookieType == matchType {
            
            let chain = Chain(chainType: .vertical)
            repeat {
              chain.add(cookie: cookies[column, row]!)
              row += 1
            } while (row < NumRows) && (cookies[column, row]?.cookieType == matchType)
            
            set.insert(chain)
            continue
          }
          
        }
        
        row += 1
      }
      
    }
    return set
  }

  private func createInitialCookies() -> Set<Cookie> {
      var set = Set<Cookie>()
      
      for row in 0..<NumRows {
          for column in 0..<NumColumns {
              
              if tiles[column, row] != nil {
//                    let type = CookieType.random()
                  //保证此type不会直接产生3个相同的type
                  var cookieType: CookieType
                  repeat {
                      cookieType = CookieType.random()
                  } while (column >= 2 &&
                      cookies[column - 1, row]?.cookieType == cookieType &&
                      cookies[column - 2, row]?.cookieType == cookieType)
                      || (row >= 2 &&
                          cookies[column, row - 1]?.cookieType == cookieType &&
                          cookies[column, row - 2]?.cookieType == cookieType)
                  
                  let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                  cookies[column, row] = cookie
                  set.insert(cookie)
              }
              
          }
      }
      
      return set
  }
  
  private func hasChainAt(column: Int, row: Int) -> Bool {
      let cookieType = cookies[column, row]!.cookieType
      
      // Horizontal chain check
      var horzLength = 1
      
      // Left
      var i = column - 1
      while i >= 0 && cookies[i, row]?.cookieType == cookieType {
          i -= 1
          horzLength += 1
      }
      
      // Right
      i = column + 1
      while i < NumColumns && cookies[i, row]?.cookieType == cookieType {
          i += 1
          horzLength += 1
      }
      if horzLength >= 3 { return true }
      
      // Vertical chain check
      var vertLength = 1
      
      // Down
      i = row - 1
      while i >= 0 && cookies[column, i]?.cookieType == cookieType {
          i -= 1
          vertLength += 1
      }
      
      // Up
      i = row + 1
      while i < NumRows && cookies[column, i]?.cookieType == cookieType {
          i += 1
          vertLength += 1
      }
      return vertLength >= 3
  }
}
