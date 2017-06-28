//
//  GameViewController.swift
//  EliminateGame
//
//  Created by LingNanTong on 2017/6/23.
//
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {
    
  var scene: GameScene!
  var level: Level!
  
  var movesLeft = 0
  var score = 0
  
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var gameOverPanel: UIImageView!
  @IBOutlet weak var shuffleButton: UIButton!
  
  var currentLevelNum = 1
  
  var tapGestureRecognizer: UITapGestureRecognizer!
  
  lazy var backgroundMusic: AVAudioPlayer? = {
    guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
      return nil
    }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.numberOfLoops = -1
      return player
    } catch {
      return nil
    }
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupLevel(levelNum: currentLevelNum)

    backgroundMusic?.play()
  }

  func setupLevel(levelNum : Int) {
    
    let skView = view as! SKView
    skView.isMultipleTouchEnabled = false
    
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .aspectFill
    skView.presentScene(scene)
    
    gameOverPanel.isHidden = true
    shuffleButton.isHidden = true
    
    level = Level(filename: "Level_\(levelNum)")
    scene.level = level
    scene.addTiles()
    scene.swipeHandler = handleSwipe(swap:)
    
    beginGame()
  }

  func beginGame() {

    movesLeft = level.maximumMoves
    score = 0
    updateLabels()
    
    scene.animateBeginGame { 
      self.shuffleButton.isHidden = false
    }
    
    shuffle()
    
  }
  
  func shuffle() {
    scene.removeAllCookieSprites()

    let newCookies = level.shuffle()
    scene.addSprites(for: newCookies)
    
    level.resetComboMultiplier()
  }
  
  func beginNextTurn() {
    level.resetComboMultiplier()
    
    //再次检测有哪些可能的交换,如果没有则自动洗牌
    let swapsCount = level.detectPossibleSwaps()
    if swapsCount == 0 {
      shuffle()
    }
    
    view.isUserInteractionEnabled = true
  }
  
  @IBAction func shuffleButtonPressed() {
    shuffle()
    decrementMoves()
  }
  
  func handleSwipe(swap: Swap) {
    view.isUserInteractionEnabled = false
  
    //检查这个交换是否可行
    if level.isPossibleSwap(swap) { 
        level.performSwap(swap: swap)
        scene.animate(swap: swap, completion: handleMatches)
    }else {
        scene.animateInvalidSwap(swap: swap) { 
            self.view.isUserInteractionEnabled = true
        }
    }

  }

  func handleMatches() { 
    //消除matched
    let chains = level.removeMatches()
    
    //检查是否有能消除的chains
    if chains.isEmpty {
      decrementMoves()
      beginNextTurn()
      return
    }
    
    scene.animateMatchedCookies(for: chains) { 
      //更新分数
      for chain in chains {
        self.score += chain.score
      }
      self.updateLabels()
      
      //填充空档
      let fillColumns = self.level.fillHoles()
      self.scene.animateFallingCookies(columns: fillColumns, completion: {
        
        //添加新元素填满顶部的空档
        let newCookies = self.level.topUpCookies()
        self.scene.animateNewCookies(columns: newCookies, completion: {
          //检查心元素添加后是否又有matched的
          self.handleMatches()
        })
        
      })

    }
  }
  
  func showGameOver() {
    gameOverPanel.isHidden = false
    scene.isUserInteractionEnabled = false
    shuffleButton.isHidden = true
    
    scene.animateGameOver { 
      self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
      self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
  }
  
  func hideGameOver() {
    self.view.removeGestureRecognizer(tapGestureRecognizer)
    tapGestureRecognizer = nil
    
    gameOverPanel.isHidden = true
    scene.isUserInteractionEnabled = true
    
    //设置游戏level重新开始
    setupLevel(levelNum: currentLevelNum)
  }
  
  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoreLabel.text = String(format: "%ld", score)
  }
  
  func decrementMoves() {
    movesLeft -= 1
    updateLabels()
    
    if self.score >= level.targetScore {
      gameOverPanel.image = UIImage(named: "LevelComplete")
      currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 1
      showGameOver()
    }else if self.movesLeft == 0 {
      gameOverPanel.image = UIImage(named: "GameOver")
      showGameOver()
    }
    
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
      return .portraitUpsideDown;
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Release any cached data, images, etc that aren't in use.
  }

  
  override var shouldAutorotate: Bool {
      return false
  }
  
  override var prefersStatusBarHidden: Bool {
      return true
  }
}
