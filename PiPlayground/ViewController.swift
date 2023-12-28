//
//  ViewController.swift
//  PiPlayground
//
//  Created by tbxark on 12/28/23.
//

import UIKit
import AVKit
import WebKit

class ViewController: UIViewController, AVPictureInPictureControllerDelegate, UITextFieldDelegate {
    
    struct Config {
        static let video200x100: URL = Bundle.main.url(forResource: "200x100", withExtension: "mp4")!
    }
    
    private let urlField = UITextField()
    private let playButton = UIButton()
    private let loadButton = UIButton()
    private let playerContainerView = WKWebView()
    private let playerContainerPlaceholder = UIView()

    private let playerLayer = AVPlayerLayer(player: AVPlayer(url: Config.video200x100))
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
        
        playerLayer.player?.isMuted = true
        playerLayer.player?.allowsExternalPlayback = true
        playerLayer.player?.play()
        view.layer.addSublayer(playerLayer)


        view.addSubview(playerContainerPlaceholder)
        view.addSubview(urlField)
        view.addSubview(playButton)
        
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        playerContainerPlaceholder.backgroundColor = UIColor.secondarySystemBackground
        
        urlField.text = "https://tbxark.com"
        urlField.backgroundColor = UIColor.secondarySystemBackground
        urlField.layer.cornerRadius = 10
        urlField.layer.masksToBounds = true
        urlField.font = UIFont.systemFont(ofSize: 15)
        urlField.textAlignment = .center
        urlField.translatesAutoresizingMaskIntoConstraints = false
        urlField.returnKeyType = .go
        urlField.delegate = self


        playButton.setTitle("画中画", for: .normal)
        playButton.addTarget(self, action: #selector(changePipState), for: .touchUpInside)
        loadButton.setTitle("预览", for: .normal)
        loadButton.addTarget(self, action: #selector(loadWebContent), for: .touchUpInside)


        for btn in [playButton, loadButton] {
            btn.backgroundColor = UIColor(white: 0.8, alpha: 1)
            btn.layer.cornerRadius = 10
            btn.layer.masksToBounds = true
            btn.setTitleColor(.black, for: .normal)
            btn.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(btn)
        }
        
        
        let hSpace = CGFloat(20)
        NSLayoutConstraint.activate([
            
            playerContainerPlaceholder.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            playerContainerPlaceholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerContainerPlaceholder.leftAnchor.constraint(equalTo: view.leftAnchor, constant: hSpace),
            playerContainerPlaceholder.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -hSpace),
            playerContainerPlaceholder.heightAnchor.constraint(equalTo: playerContainerPlaceholder.widthAnchor, multiplier: 0.5),
            
            urlField.topAnchor.constraint(equalTo: playerContainerPlaceholder.bottomAnchor, constant: 60),
            urlField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: hSpace),
            urlField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -hSpace),
            urlField.heightAnchor.constraint(equalToConstant: 60),
            
            
            playButton.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 20),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            playButton.rightAnchor.constraint(equalTo: view.centerXAnchor, constant: -20),

            loadButton.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 20),
            loadButton.widthAnchor.constraint(equalToConstant: 100),
            loadButton.heightAnchor.constraint(equalToConstant: 50),
            loadButton.leftAnchor.constraint(equalTo: view.centerXAnchor, constant: 20),
            
        ])
        
        pipController?.delegate = self
        pipController?.setValue(1, forKey: "controlsStyle")
        if let pc = pipController {
            pictureInPictureControllerWillStopPictureInPicture(pc)
        }
    }
    
    @objc func loadWebContent(_ sender: Any) {
        print("loadWebContent")
        if let url = URL(string: urlField.text ?? "") {
            playerContainerView.load(URLRequest(url: url))
        }
    }

    @objc func changePipState(_ sender: Any) {
        guard let pc = pipController else {
            return
        }
        print("changePipState")
        if pc.isPictureInPictureActive {
            pc.stopPictureInPicture()
        } else {
            pc.startPictureInPicture()
        }
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerWillStartPictureInPicture")
        guard let windows = UIApplication.shared.windows.first else { return }
        playerContainerView.removeFromSuperview()
        windows.addSubview(playerContainerView)
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        lastPlayerContainerConstraint = [
            playerContainerView.topAnchor.constraint(equalTo: windows.topAnchor),
            playerContainerView.leftAnchor.constraint(equalTo: windows.leftAnchor),
            playerContainerView.rightAnchor.constraint(equalTo: windows.rightAnchor),
            playerContainerView.bottomAnchor.constraint(equalTo: windows.bottomAnchor)
        ]
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerWillStopPictureInPicture")
        playerContainerView.removeFromSuperview()
        playerContainerPlaceholder.addSubview(playerContainerView)
        lastPlayerContainerConstraint = [
            playerContainerView.topAnchor.constraint(equalTo: playerContainerPlaceholder.topAnchor),
            playerContainerView.leftAnchor.constraint(equalTo: playerContainerPlaceholder.leftAnchor),
            playerContainerView.rightAnchor.constraint(equalTo: playerContainerPlaceholder.rightAnchor),
            playerContainerView.bottomAnchor.constraint(equalTo: playerContainerPlaceholder.bottomAnchor)
        ]
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loadWebContent(textField)
        return true
    }
}

