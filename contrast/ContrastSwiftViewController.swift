//
//  ContrastSwiftViewController.swift
//  contrast
//
//  Created by Johan Halin on 13.9.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

import UIKit

class ContrastSwiftViewController: UIViewController, ContrastChannelViewDelegate {
	let maximumChannelCount = 8
	let animationDuration = 0.2
	
	let channelController: ContrastChannelController
	
	var channels: Array<ContrastChannelView> // FIXME: this sucks, the channel controller can be used for this purpose
	var introLabel: UILabel?
	var patternView: UIView?
	
	// MARK: - Private
	
	private func frequencyPosition(point: CGPoint) -> CGFloat {
		let heightRatio = point.y / self.view.bounds.size.width
		let widthModifier = ((point.x / self.view.bounds.size.width) / 10.0) - 0.05
		
		return (1.0 - heightRatio) + widthModifier
	}
	
	private func noiseAmount(point: CGPoint) -> CGFloat {
		let width = self.view.bounds.size.width;
		let minThreshold = width * 0.1
		let maxThreshold = width - minThreshold
		
		if (point.x < minThreshold) {
			return 1.0 - (point.x / minThreshold)
		} else if (point.x > maxThreshold) {
			return 1.0 - (width - point.x) / minThreshold
		}
		
		return 0
	}
	
	private func panPosition(point: CGPoint) -> CGFloat {
		let halfWidth = self.view.bounds.size.width / 2.0
		let panPosition = (point.x / halfWidth) - 1.0
		
		return panPosition
	}
	
	private func addChannel(point: CGPoint) {
		if self.channels.count >= self.maximumChannelCount {
			return
		}

		if self.introLabel != nil {
			UIView.animateWithDuration(
				self.animationDuration,
				animations: {
					self.introLabel?.alpha = 0
				},
				completion: { finished in
					self.introLabel?.removeFromSuperview()
					self.introLabel = nil
				}
			)
		}
		
		let channelView: ContrastChannelView = ContrastChannelView.init(center: point, delegate: self)
		channelView.alpha = 0
		channelView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0)
		self.view.addSubview(channelView)
		self.channels.append(channelView)
		self.channelController.addView(channelView)
		self.channelController.updateChannelWithView(
			channelView,
			frequencyPosition: Float(self.frequencyPosition(point)),
			volume: 0.5,
			effectAmount: 0,
			noiseAmount: Float(self.noiseAmount(point)),
			panPosition: Float(self.panPosition(point))
		)
		
		UIView.animateWithDuration(
			self.animationDuration,
			delay: 0,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0.5,
			options: [],
			animations: {
				channelView.alpha = 1
				channelView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1)
			},
			completion: nil
		)
	}
	
	private func removeChannel(channelView: ContrastChannelView) {
		self.channelController.removeView(channelView)
		
		UIView.animateWithDuration(self.animationDuration * 2.0,
			delay: 0,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0.5,
			options: [],
			animations: {
				channelView.alpha = 0
				channelView.transform = CGAffineTransformRotate(channelView.transform, CGFloat(M_PI_4))
				channelView.transform = CGAffineTransformScale(channelView.transform, 0.1, 0.1)
			},
			completion: { finished in
				self.channels.removeAtIndex(self.channels.indexOf(channelView)!)
			}
		)
	}
	
	@objc(doubleTapRecognized:)
	private func doubleTapRecognized(tapRecognizer: UITapGestureRecognizer) {
		let location = tapRecognizer.locationInView(self.view)
		let view = self.view.hitTest(location, withEvent: nil)
		
		if view == self.view {
			self.addChannel(location)
		}
	}
	
	private func effectAmount(rotation: CGFloat) -> CGFloat {
		if rotation >= 0 {
			var amount = (rotation / CGFloat(M_PI * 2.0))
			
			if amount > 1 {
				amount = 1
			}
			
			return amount
		} else {
			return 0
		}
	}
	
	private func startBackgroundPatternAnimation() {
		let patternImage = UIImage.init(named: "pattern")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
		let frame = CGRectMake(
			0,
			0,
			CGRectGetWidth(self.view.bounds) + patternImage!.size.width,
			CGRectGetHeight(self.view.bounds)
		)
		
		if self.patternView == nil {
			let patternView = UIView.init(frame: frame)
			patternView.backgroundColor = UIColor.init(patternImage: patternImage!)
			patternView.userInteractionEnabled = false
			self.view.addSubview(patternView)
			
			self.patternView = patternView
		} else {
			self.patternView?.frame = frame
		}
		
		let animation = CABasicAnimation.init(keyPath: "position.x")
		let from = frame.size.width / 2.0
		animation.fromValue = from
		animation.toValue = from - patternImage!.size.width
		animation.duration = 1
		animation.repeatCount = MAXFLOAT
		self.patternView?.layer.addAnimation(animation, forKey: "animation")
	}
	
	@objc(willEnterForeground:)
	private func willEnterForeground(notification: NSNotification) {
		self.startBackgroundPatternAnimation()
	}
	
	private func createIntroLabel() {
		let label = UILabel.init(frame: self.view.bounds)
		label.autoresizingMask = [ UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight ]
		label.backgroundColor = UIColor.clearColor()
		label.font = UIFont.boldSystemFontOfSize(56.0)
		label.textColor = ContrastChannelView.outlineColor()
		label.numberOfLines = 0
		label.lineBreakMode = NSLineBreakMode.ByCharWrapping
		
		let attributedString = NSMutableAttributedString.init(string: NSLocalizedString("Contrast by Johan & Jaakko Please use headphones Double-tap to begin", comment: ""))
		// FIXME: how the fuck does this work
//		attributedString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleThick as! AnyObject, range: NSMakeRange(0, "Contrast".lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
		label.attributedText = attributedString
		
		self.view.addSubview(label)
		
		self.introLabel = label
	}
	
	// MARK: - ContrastChannelViewDelegate
	
	func channelView(channelView: ContrastChannelView!, updatedWithPosition position: CGPoint, scale: CGFloat, rotation: CGFloat) {
		self.channelController.updateChannelWithView(
			channelView,
			frequencyPosition: Float(self.frequencyPosition(position)),
			volume: Float(scale - 0.5),
			effectAmount: Float(self.effectAmount(rotation)),
			noiseAmount: Float(self.noiseAmount(position)),
			panPosition: Float(self.panPosition(position))
		)
	}
	
	func channelViewReceivedTap(channelView: ContrastChannelView!) {
		self.channelController.viewWasTouched(channelView)
	}
	
	func channelViewReceivedDoubleTap(channelView: ContrastChannelView!) {
		self.removeChannel(channelView)
	}
	
	// MARK: - UIViewController
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector.init("willEnterForeground:"), name: UIApplicationWillEnterForegroundNotification, object: nil)
		
		self.view.backgroundColor = ContrastChannelView.cyanColor()
		
		self.createIntroLabel()
		
		let doubleTapRecognizer = UITapGestureRecognizer.init(target: self, action: "doubleTapRecognized:")
		doubleTapRecognizer.numberOfTapsRequired = 2
		self.view.addGestureRecognizer(doubleTapRecognizer)
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		self.startBackgroundPatternAnimation()
	}
	
	init() {
		self.channelController = ContrastChannelController()
		self.channels = Array<ContrastChannelView>()
		
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
