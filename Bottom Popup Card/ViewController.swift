//
//  ViewController.swift
//  Bottom Popup Card
//
//  Created by Rishabh Raj on 12/07/19.
//  Copyright © 2019 Rishabh Raj. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    var cardViewController : CardViewController!
    var visualEffectView : UIVisualEffectView!
    
    let cardHeight : CGFloat = 600
    let cardHandleAreaHeight : CGFloat = 65
    
    var cardVisible = false
    
    var nextState : CardState {
        return cardVisible ? .collapsed : .expanded
    }

    var runningAnimations = [UIViewPropertyAnimator]()
    var animationsProgressWhenInterrupted : CGFloat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        setupCard()
    }

    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        cardViewController = CardViewController()
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        
        cardViewController.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(recognizer:)))
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(recognizer:)))
        
        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func handleCardTap(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc func handleCardPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        
        
        case .began:
            // start transition
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            // update transition
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            // continue transition
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded(state: CardState, duration : TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                }
            }
            
            frameAnimator.addCompletion { (_) in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded :
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    func startInteractiveTransition(state : CardState, duration : TimeInterval) {
        if runningAnimations.isEmpty {
            // run animations
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationsProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationsProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}

