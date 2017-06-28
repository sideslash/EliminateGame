//
//  Array2D.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/23.
//
//

import Foundation

struct Array2D<T> {
    let columns : Int
    let rows : Int
    fileprivate var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        self.array = Array(repeating: nil, count: columns * rows)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row * columns + column]
        }
        
        set {
            array[row * columns + column] = newValue
        }
    }
    
}
