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
import Vapor

class ViewController: UIViewController, AVPictureInPictureControllerDelegate, UITextFieldDelegate {
    
    private let configure = Configuration()
    private let textView = UITextView()
    private var sinkStore = Set<AnyCancellable>()
    private var currentServer: Application?
    private var currentAutoScrollTimer: DispatchSourceTimer?
    
    private lazy var playerLayer = AVPlayerLayer(player: AVPlayer(playerItem: nil))
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
            pipController?.setValue(1, forKey: "controlsStyle")
            view.layer.addSublayer(playerLayer)
        }
        
        do {
            let contentView = ContentView(startPip: {
                print("startPictureInPicture")
                self.pipController?.startPictureInPicture()
            }, startServer: {
                DispatchQueue.global(qos: .background).async {
                    self.startWebServer()
                }
                self.configure.isRunning = true
            }).environmentObject(configure)
            let hostingController = UIHostingController(rootView: contentView)
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
        
        if let url = Bundle.main.url(forResource: configure.scale.rawValue, withExtension: "mp4")  {
            self.playerLayer.player?.replaceCurrentItem(with: AVPlayerItem(url: url))
            self.playerLayer.player?.play()
        }
        textView.text = configure.text
        textView.font = UIFont.systemFont(ofSize: configure.fontSize)
        textView.textColor = configure.textColor.toUIColor()
        textView.backgroundColor = configure.textBackground.toUIColor()

         configure.$text.sink {[weak self] (text) in
             DispatchQueue.main.async {
                 self?.textView.text = text
             }
        }.store(in: &sinkStore)

        configure.$fontSize.sink {[weak self] (fontSize) in
            DispatchQueue.main.async {
                self?.textView.font = UIFont.systemFont(ofSize: fontSize)
            }
        }.store(in: &sinkStore)

        configure.$textColor.sink {[weak self] (c) in
            DispatchQueue.main.async {
                self?.textView.textColor = c.toUIColor()
            }
        }.store(in: &sinkStore)

        configure.$textBackground.sink {[weak self] (c) in
            DispatchQueue.main.async {
                self?.textView.backgroundColor = c.toUIColor()
            }
        }.store(in: &sinkStore)

        configure.$speed.sink {[weak self] (speed) in
            self?.startAutoScrollGCDTimer(scroll: nil)
        }.store(in: &sinkStore)

        configure.$autoScroll.sink {[weak self] (autoScroll) in
            self?.startAutoScrollGCDTimer(scroll: autoScroll)
        }.store(in: &sinkStore)

        configure.$scale.sink {[weak self] (scale) in
            guard let self = self,
                  let url = Bundle.main.url(forResource: scale.rawValue, withExtension: "mp4") else { return }
            DispatchQueue.main.async {
                self.playerLayer.player?.replaceCurrentItem(with: AVPlayerItem(url: url))
                self.playerLayer.player?.play()
            }
        }.store(in: &sinkStore)


    }
    
    private func startWebServer() {
        do {
            currentServer?.shutdown()
            let vapor = try Application(.detect())
            vapor.http.server.configuration.hostname = configure.serverAddress
            vapor.http.server.configuration.port = configure.serverPort
            if let url = Bundle.main.url(forResource: "index", withExtension: "html"),
                let html = try? Data(contentsOf: url) {
                vapor.get { (req)  in
                    let response = Response(status: .ok, body: .init(data: html))
                    response.headers.add(name: "Content-Type", value: "text/html")
                    return response
                }
            }
            vapor.post("update") {[weak self] (req) -> ConfigurationDataModel in
                guard let self = self else { return ConfigurationDataModel() }
                let data = try req.content.decode(ConfigurationDataModel.self)
                if let text = data.text {
                    self.configure.text = text
                }
                if let textColorHex = data.textColorHex {
                    self.configure.textColor = Color(hex: textColorHex)
                }
                if let textBackgroundHex = data.textBackgroundHex {
                    self.configure.textBackground = Color(hex: textBackgroundHex)
                }
                if let speed = data.speed {
                    self.configure.speed = speed
                }
                if let fontSize = data.fontSize {
                    self.configure.fontSize = fontSize
                }
                if let autoScroll = data.autoScroll {
                    self.configure.autoScroll = autoScroll
                }
                if let scrollProgress = data.scrollProgress {
                    self.configure.scrollProgress = scrollProgress
                }
                return ConfigurationDataModel.from(self.configure)
            }
            // vapor.webSocket("status") { (req, ws) in
            //     let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
            //     timer.schedule(deadline: .now(), repeating: .seconds(1))
            //     timer.setEventHandler(handler: {
            //         let data = ConfigurationDataModel.from(self.configure)
            //         if let jData = try? JSONEncoder().encode(data),
            //            let jText = String(data: jData, encoding: .utf8) {
            //             ws.send(jText)
            //         }
            //     })
            //     timer.resume()
            //     ws.onClose.whenComplete { (_) in
            //         timer.cancel()
            //     }
            // }
            try vapor.start()
        } catch(let e) {
            print(e.localizedDescription)
        }

    }

    private func startAutoScrollGCDTimer(scroll: Bool? = nil) {
        currentAutoScrollTimer?.cancel()
        if (scroll ?? configure.autoScroll) {
            currentAutoScrollTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
            currentAutoScrollTimer?.schedule(deadline: .now(), repeating: .seconds(1))
            currentAutoScrollTimer?.setEventHandler(handler: {[weak self] in
                print("startAutoScrollGCDTimer handler")
                guard let self = self else { return }
                let progress = self.textView.contentOffset.y / self.textView.contentSize.height
                self.configure.scrollProgress = progress
                UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
                    self.textView.contentOffset.y += 10 * self.configure.speed
                }
            })
            currentAutoScrollTimer?.resume()
        }
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerWillStartPictureInPicture")
        guard let windows = UIApplication.shared.windows.first else { return }
        configure.isPipMode = true
        windows.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        lastPlayerContainerConstraint = [
            textView.topAnchor.constraint(equalTo: windows.topAnchor),
            textView.leftAnchor.constraint(equalTo: windows.leftAnchor),
            textView.rightAnchor.constraint(equalTo: windows.rightAnchor),
            textView.bottomAnchor.constraint(equalTo: windows.bottomAnchor)
        ]
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        configure.isPipMode = false
    }
}

struct ConfigurationDataModel: Content {
    
    static var defaultContentType: HTTPMediaType {
        return .json
    }

    var text: String?
    var textColorHex: String?
    var textBackgroundHex: String?
    var speed: CGFloat?
    var fontSize: CGFloat?
    var autoScroll: Bool?
    var scrollProgress: CGFloat?
    
    static func from(_ c: Configuration) -> ConfigurationDataModel {
        return ConfigurationDataModel(text: c.text,
                                      textColorHex: c.textColor.toHex(),
                                      textBackgroundHex: c.textBackground.toHex(),
                                      speed: c.speed,
                                      fontSize: c.fontSize,
                                      autoScroll: c.autoScroll,
                                      scrollProgress: c.scrollProgress
                                      )
    }
}
