//
//  GameScene.swift
//  Pachinko
//
//  Created by Николай Никитин on 28.12.2021.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

  //MARK: - Properties
  var scoreLabel: SKLabelNode!
  var  score = 0 {
    didSet {
      if score < 0 {
        self.score = 0
      }
      scoreLabel.text = "Score: \(score)"
    }
  }
  var editLabel: SKLabelNode!
  var editingMode: Bool = false {
    didSet {
      if editingMode {
        editLabel.text = "Done"
      } else {
        editLabel.text = "Edit"
      }
    }
  }
  var limitLabel: SKLabelNode!
  var ballLimit = 0 {
    didSet {
      limitLabel.text = "Limit of balls: \(ballLimit)"
    }
  }

  //MARK: - Scene presentation methods
  override func didMove(to view: SKView) {
    //Set backgrount
    let background = SKSpriteNode(imageNamed: "background")
    background.position = CGPoint(x: 512, y: 384)
    background.blendMode = .replace
    background.zPosition = -1
    addChild(background)

    //Set&add scoreLabel
    scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    scoreLabel.text = "Score: 0"
    scoreLabel.horizontalAlignmentMode = .right
    scoreLabel.position = CGPoint(x: 980, y: 700)
    addChild(scoreLabel)

    //Add edit label
    editLabel = SKLabelNode(fontNamed: "Chalkduster")
    editLabel.text = "Edit"
    editLabel.position = CGPoint(x: 80, y: 700)
    addChild(editLabel)

    //Set limit label of ball for edit mode
    limitLabel = SKLabelNode(fontNamed: "Chalkduster")
    limitLabel.text = "Press edit for more balls!"
    limitLabel.position = CGPoint(x: 500, y: 700)
    addChild(limitLabel)

    //Set frame bounds
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    physicsWorld.contactDelegate = self

    //Set&add slots
    makeSlot(at: CGPoint(x: 128, y: 0), isGood: true)
    makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
    makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
    makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)

    //Set&add bouncers
    makeBouncer(at: CGPoint(x: 0, y: 0))
    makeBouncer(at: CGPoint(x: 256, y: 0))
    makeBouncer(at: CGPoint(x: 512, y: 0))
    makeBouncer(at: CGPoint(x: 768, y: 0))
    makeBouncer(at: CGPoint(x: 1024, y: 0))

  }

  //MARK: - UIMethods
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    let objects = nodes(at: location)

    // If tap location is in editLabel
    if objects.contains(editLabel) {
      editingMode.toggle()
    } else {
      if editingMode {
        let size = CGSize(width: Int.random(in: 16...128), height: 16)
        let box = SKSpriteNode(color: UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1), size: size)
        box.zRotation = CGFloat.random(in: 0...3)
        box.position = location
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
        box.physicsBody?.isDynamic = false
        box.name = "box"
        addChild(box)
        ballLimit += 1
      } else {

        let color = Int.random(in: 1...7)
        var name: String = ""

        switch color {
        case 1:
          name = "ballRed"
        case 2:
          name = "ballBlue"
        case 3:
          name = "ballCyan"
        case 4:
          name = "ballGreen"
        case 5:
          name = "ballGrey"
        case 6:
          name = "ballPurple"
        case 7:
          name = "ballYellow"
        default:
          name = "ballYellow"
        }

        let ball = SKSpriteNode(imageNamed: name)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2.0)
        ball.physicsBody?.restitution = 0.4
        ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? 0

        ball.position = CGPoint(x: location.x, y: 650)
        ball.name = "ball"
        if ballLimit != 0 {
          addChild(ball)
        }
      }
    }
  }

  func makeBouncer(at position: CGPoint) {
    let  bouncer = SKSpriteNode(imageNamed: "bouncer")
    bouncer.position = position
    bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2)
    bouncer.physicsBody?.isDynamic = false
    addChild(bouncer)
  }

  func makeSlot(at position: CGPoint, isGood: Bool) {
    var slotBase: SKSpriteNode
    var slotGlow: SKSpriteNode
    if isGood {
      slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
      slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
      slotBase.name = "good"
    } else {
      slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
      slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
      slotBase.name = "bad"
    }
    slotBase.position = position
    slotGlow.position = position

    slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
    slotBase.physicsBody?.isDynamic = false

    addChild(slotBase)
    addChild(slotGlow)

    let spin = SKAction.rotate(byAngle: .pi, duration: 10)
    let spinForever = SKAction.repeatForever(spin)
    slotGlow.run(spinForever)
  }

  //MARK: - Collisions methods
  func collision(between ball: SKNode, object: SKNode) {
    if object.name == "good" {
      destroy(ball: ball)
      score += 1
      ballLimit += 1
    } else if object.name == "bad"{
      destroy(ball: ball)
      score -= 1
      ballLimit -= 1
      if ballLimit <= 0 {
        for node in scene!.children {
          if node.name == "box" {
            node.removeFromParent()
          }
          limitLabel.text = "Press edit for more balls!"
        }
      }
    }
  }

  func destroy(ball: SKNode) {
    if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
      fireParticles.position = ball.position
      addChild(fireParticles)
    }
    ball.removeFromParent()
  }

  func didBegin(_ contact: SKPhysicsContact) {

    guard let nodeA = contact.bodyA.node else { return }
    guard let nodeB = contact.bodyB.node else { return }

    if nodeA.name == "ball" {
      collision(between: nodeA, object: nodeB)
    } else if nodeB.name == "ball" {
      collision(between: nodeB, object: nodeA)
    }
  }


}
