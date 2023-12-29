//
//  ViewController.swift
//  PiPlayground
//
//  Created by tbxark on 12/28/23.
//

import UIKit
import AVKit
import SwiftUI
import Combine

class ViewController: UIViewController, AVPictureInPictureControllerDelegate, UITextFieldDelegate {
    
    private let configure = Configuration()
    private let textView = UITextView()
    
    private var sinkStore = Set<AnyCancellable>()
    
    private lazy var playerLayer = AVPlayerLayer(player: AVPlayer(url: self.configure.scale.url))
    private lazy var pipController = AVPictureInPictureController(playerLayer: self.playerLayer)
    private var lastPlayerContainerConstraint = [NSLayoutConstraint]() {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(lastPlayerContainerConstraint)
        }
    }
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
   
        } catch {
            print(error)
        }
        
        do {
            playerLayer.player?.isMuted = true
            playerLayer.player?.allowsExternalPlayback = true
            playerLayer.player?.play()
            pipController?.delegate = self
            view.layer.addSublayer(playerLayer)
        }
        
        do {
            let hostingController = UIHostingController(rootView: ContentView(onStart: {[weak self] in
                print("startPictureInPicture")
                self?.pipController?.startPictureInPicture()
            }).environmentObject(configure))
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hostingController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
            hostingController.didMove(toParent: self)
        }
        
        updateTextViewStyle()
        
    }
    
    func updateTextViewStyle() {
        print("updateTextViewStyle")
        
        textView.text = configure.text
        textView.font = UIFont.systemFont(ofSize: configure.fontSize)
        textView.textColor = UIColor(hex: configure.textColorHex)
        textView.backgroundColor = UIColor(hex: configure.textBackgroundHex)

         configure.$text.sink {[weak self] (text) in
            self?.textView.text = text
        }.store(in: &sinkStore)

        configure.$fontSize.sink {[weak self] (fontSize) in
            self?.textView.font = UIFont.systemFont(ofSize: fontSize)
        }.store(in: &sinkStore)

        configure.$textColorHex.sink {[weak self] (textColorHex) in
            self?.textView.textColor = UIColor(hex: textColorHex)
        }.store(in: &sinkStore)

        configure.$textBackgroundHex.sink {[weak self] (textBackgroundHex) in
            self?.textView.backgroundColor = UIColor(hex: textBackgroundHex)
        }.store(in: &sinkStore)

        configure.$scale.sink {[weak self] (scale) in
            guard let self = self else { return }
            self.playerLayer.player?.replaceCurrentItem(with: AVPlayerItem(url: scale.url))
            self.playerLayer.player?.play()
        }.store(in: &sinkStore)


    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerWillStartPictureInPicture")
        guard let windows = UIApplication.shared.windows.first else { return }
        windows.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        lastPlayerContainerConstraint = [
            textView.topAnchor.constraint(equalTo: windows.topAnchor),
            textView.leftAnchor.constraint(equalTo: windows.leftAnchor),
            textView.rightAnchor.constraint(equalTo: windows.rightAnchor),
            textView.bottomAnchor.constraint(equalTo: windows.bottomAnchor)
        ]
    }
    
    
}
