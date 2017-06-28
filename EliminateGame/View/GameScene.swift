//
//  GameScene.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/23.
//
//

import SpriteKit
import GameplayKit

let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)

class GameScene: SKScene {
    
  var level: Level!
  var swipeHandler : ((Swap) -> Void)?
  
  private let TileWidth: CGFloat = 32.0
  private let TileHeight: CGFloat = 36.0
  
  private let gameLayer = SKNode()
  private let tilesLayer = SKNode()
  private let cookiesLayer = SKNode()
  private let cropLayer = SKCropNode()
  
  private var swipeFromColumn: Int?
  private var swipeFromRow: Int?
  
  private var selectionSprite = SKSpriteNode()
  
  // MARK:init
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    print("<deinit> - GameScene")
  }
  override init(size: CGSize) {
    super.init(size: size)
    
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    let background = SKSpriteNode(imageNamed: "Background_Dessert")
    background.size = size
    addChild(background)
    
    //add layers
    addChild(gameLayer)
    gameLayer.isHidden = true
  
    let layerPosition = CGPoint(
        x: -TileWidth * CGFloat(NumColumns) / 2,
        y: -TileHeight * CGFloat(NumRows) / 2)

    
    gameLayer.addChild(cropLayer)
    cropLayer.position = layerPosition
    cropLayer.maskNode = tilesLayer
    cropLayer.addChild(tilesLayer)
    
    cropLayer.addChild(cookiesLayer)
    
    
    swipeFromColumn = nil
    swipeFromRow = nil
  }
  
  // MARK:public methods
  func addTiles() {
    //add masks
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if level.tileAt(column: column, row: row) != nil {
          let tileNode = SKSpriteNode(imageNamed: "Tile")
          tileNode.size = CGSize(width: TileWidth, height: TileHeight)
          tileNode.position = pointFor(column: column, row: row)
          tilesLayer.addChild(tileNode)
        }
      }
    }
  }
  
  func addSprites(for cookies: Set<Cookie>) {
    for cookie in cookies {
      let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
      sprite.size = CGSize(width: TileWidth, height: TileHeight)
      sprite.position = pointFor(column: cookie.column, row: cookie.row)
      cookiesLayer.addChild(sprite)
      cookie.sprite = sprite
      
      //给每个sprite添加一个进场动画，每个有随机的延迟等待时间
      sprite.alpha = 0
      sprite.xScale = 0.5
      sprite.yScale = 0.5
      sprite.run(SKAction.sequence([SKAction.wait(forDuration: 0.25, withRange: 0.25),
                                    SKAction.group([SKAction.fadeIn(withDuration: 0.25),
                                                    SKAction.scale(to: 1.0, duration: 0.25)])]))
    }
  }
  
  func removeAllCookieSprites() {
    self.cookiesLayer.removeAllChildren()
  }
  
  func animate(swap: Swap, completion: @escaping (() -> Void)) {
      let spriteA = swap.cookieA.sprite!
      let spriteB = swap.cookieB.sprite!
      
      spriteA.zPosition = 100
      spriteB.zPosition = 90
      
      let duration: TimeInterval = 0.3
      
      let moveA = SKAction.move(to: spriteB.position, duration: duration)
      moveA.timingMode = .easeOut
      spriteA.run(moveA, completion: completion)
      
      let moveB = SKAction.move(to: spriteA.position, duration: duration)
      moveB.timingMode = .easeOut
      spriteB.run(moveB)
      
      run(swapSound)
  }
  
  func animateInvalidSwap(swap: Swap, completion: @escaping (() -> Void)) {
      let spriteA = swap.cookieA.sprite!
      let spriteB = swap.cookieB.sprite!
      
      spriteA.zPosition = 100
      spriteB.zPosition = 90
      
      let duration: TimeInterval = 0.2
      
      let moveA = SKAction.move(to: spriteB.position, duration: duration)
      moveA.timingMode = .easeOut
      let moveB = SKAction.move(to: spriteA.position, duration: duration)
      moveB.timingMode = .easeOut
      
      spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
      spriteB.run(SKAction.sequence([moveB, moveA]))
      run(invalidSwapSound)
  }

  func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping (() -> Void)) {
    let animateInterval = 0.3
    
    for chain in chains {
      animateScore(for: chain)
      
      for cookie in chain.cookies {
        if let sprite = cookie.sprite {
          if sprite.action(forKey: "removing") == nil {
            let scaleAction = SKAction.scale(to: 0.1, duration: animateInterval)
            scaleAction.timingMode = .easeOut
            let removeAct = SKAction.removeFromParent()
            sprite.run(SKAction.sequence([scaleAction, removeAct]), withKey: "removing")
          }
        }
      }
    }
    
    run(matchSound)
    run(SKAction.wait(forDuration: animateInterval), completion: completion)
  }
  
  func animateFallingCookies(columns: [[Cookie]], completion: @escaping (() -> Void)) {
    var longestDurantion : TimeInterval = 0.0
    
    for column in columns {
      
      for (index, cookie) in column.enumerated() {
        let newPosition = pointFor(column: cookie.column, row: cookie.row)
        let sprite = cookie.sprite!
        
        let delay = 0.05 + 0.05 * Double(index)
        let durantion = TimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.2)
        
        longestDurantion = max(longestDurantion, delay + durantion)
        let moveAct = SKAction.move(to: newPosition, duration: durantion)
        moveAct.timingMode = .easeOut
        sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay),
                                      SKAction.group([moveAct, fallingCookieSound])]))
        
      }
      
    }
    
    run(SKAction.wait(forDuration: longestDurantion), completion: completion)
  }
  
  func animateNewCookies(columns: [[Cookie]], completion: @escaping (() -> Void)) {
    var longestDuration: TimeInterval = 0.0
    
    for column in columns {
      //新sprite动画起始position row在当列最高的这个row+1
      let startRow = column[0].row + 1
      
      for (index, cookie) in column.enumerated() {
        let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
        sprite.position = pointFor(column: cookie.column, row: startRow)
        cookiesLayer.addChild(sprite)
        cookie.sprite = sprite
        
        let delay = 0.1 + 0.15 * TimeInterval(column.count - index - 1)
        let duration = TimeInterval(startRow - cookie.row) * 0.1
        
        longestDuration = max(longestDuration, delay + duration)
        
        let moveAct = SKAction.move(to: pointFor(column: cookie.column, row: cookie.row), duration: duration)
        moveAct.timingMode = .easeOut
        sprite.alpha = 0
        sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay),
                                      SKAction.group([SKAction.fadeIn(withDuration: 0.05), moveAct, addCookieSound])]))
      }
    }
    
    run(SKAction.wait(forDuration: longestDuration), completion: completion)
  }
  
  func animateScore(for chain: Chain) {
    let firstSprite = chain.firstCookie().sprite!
    let lastSprite = chain.lastCookie().sprite!
    let centerPosition = CGPoint(
      x: (firstSprite.position.x + lastSprite.position.x)/2,
      y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
    
    let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    scoreLabel.fontSize = 16
    scoreLabel.text = "\(chain.score)"
    scoreLabel.position = centerPosition
    scoreLabel.zPosition = 300
    cookiesLayer.addChild(scoreLabel)
    
    let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
    moveAction.timingMode = .easeOut
    scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
  }
  
  func animateGameOver(_ completion: @escaping () -> ()) {
    let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.5)
    action.timingMode = .easeIn
    gameLayer.run(action, completion: completion)
  }
  
  func animateBeginGame(_ completion: @escaping () -> ()) {
    gameLayer.isHidden = false
    gameLayer.position = CGPoint(x: 0, y: size.height)
    let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.5)
    action.timingMode = .easeOut
    gameLayer.run(action, completion: completion)
  }
  
  // MARK:private methods
  private func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
      guard swipeFromColumn != nil else { return }
      guard swipeFromRow != nil else { return }
      
      let toColumn = swipeFromColumn! + horzDelta
      let toRow = swipeFromRow! + vertDelta
      
      guard toColumn >= 0 && toColumn < NumColumns  else { return }
      guard toRow >= 0 && toRow < NumRows  else { return }
      
      if let toCookie = level.cookieAt(column: toColumn, row: toRow) {
          if let fromCookie = level.cookieAt(column: swipeFromColumn!, row: swipeFromRow!) {
              if let handler = swipeHandler {
                  let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                  handler(swap)
              }
          }
      }
  }

  private func showSelectionIndicatorForCookie(cookie: Cookie) {
    if selectionSprite.parent != nil {
      selectionSprite.removeFromParent()
    }
    
    if let sprite = cookie.sprite {
      let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
      selectionSprite.size = CGSize(width: TileWidth, height: TileHeight)
      selectionSprite.run(SKAction.setTexture(texture))
      
      sprite.addChild(selectionSprite)
      selectionSprite.alpha = 1.0
    }
  }
  
  private func hideSelectionIndicator() {
    selectionSprite.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3),
                                           SKAction.removeFromParent()]))
  }
  
  private func pointFor(column: Int, row: Int) -> CGPoint {
      return CGPoint(x: CGFloat(column)*TileWidth + TileWidth/2,
                     y: CGFloat(row)*TileHeight + TileHeight/2)
  }

  private func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
      if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
          point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
          return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
      } else {
          return (false, 0, 0)  // invalid location
      }
  }
  
  // MARK:touches
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      
      guard let touch = touches.first else { return }
      let location = touch.location(in: cookiesLayer)
      
      let (success, column, row) = convertPoint(point: location)
      if success {
          if let cookie = level.cookieAt(column: column, row: row) {
              showSelectionIndicatorForCookie(cookie: cookie)
              
              swipeFromColumn = column
              swipeFromRow = row
          }
      }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

      guard swipeFromColumn != nil else { return }
      
      guard let touch = touches.first else { return }
      let location = touch.location(in: cookiesLayer)
      
      let (success, column, row) = convertPoint(point: location)
      if success {
          
          var horzDelta = 0, vertDelta = 0
          if column < swipeFromColumn! {          // swipe left
              horzDelta = -1
          } else if column > swipeFromColumn! {   // swipe right
              horzDelta = 1
          } else if row < swipeFromRow! {         // swipe down
              vertDelta = -1
          } else if row > swipeFromRow! {         // swipe up
              vertDelta = 1
          }

          if horzDelta != 0 || vertDelta != 0 {
              trySwap(horizontal: horzDelta, vertical: vertDelta)
              hideSelectionIndicator()
              
              swipeFromColumn = nil
          }
      }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      
      if selectionSprite.parent != nil && swipeFromColumn != nil {
          hideSelectionIndicator()
      }
      
      swipeFromColumn = nil
      swipeFromRow = nil
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
      touchesEnded(touches, with: event)
  }
  
  // MARK:frame update
  override func update(_ currentTime: TimeInterval) {
      
  }
    
}
