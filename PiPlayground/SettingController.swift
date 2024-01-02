//
//  SettingController.swift
//  PiPlayground
//
//  Created by tbxark on 12/29/23.
//

import SwiftUI


class Configuration: ObservableObject {
    enum Scale: String, CaseIterable, Hashable {
        case h1x1
        case h2x1
        case h3x1
        case h3x2
        case h4x3
    }
    
    @Published var text: String = "PlaceHolder"
    @Published var textColor = Color.white
    @Published var textBackground = Color.black
    @Published var speed: CGFloat = 1
    @Published var fontSize: CGFloat = 30
    @Published var scale: Scale = .h3x1
    @Published var autoScroll: Bool = false
    @Published var scrollProgress: CGFloat = 0
    @Published var serverAddress = "0.0.0.0"
    @Published var serverPort = 59090
    
    @Published var isRunning = false
    @Published var isPipMode = false
   
    func set(
        text: String? = nil,
        textColor: Color? = nil,
        textBackground: Color? = nil,
        speed: CGFloat? = nil,
        fontSize: CGFloat? = nil,
        scale: Scale? = nil,
        autoScroll: Bool? = nil,
        scrollProgress: CGFloat? = nil,
        serverAddress: String? = nil,
        serverPort: Int? = nil,
        isRunning: Bool? = nil,
        isPipMode: Bool? = nil
    ) {
        if let text = text {
            self.text = text
        }
        if let textColor = textColor {
            self.textColor = textColor
        }
        if let textBackground = textBackground {
            self.textBackground = textBackground
        }
        if let speed = speed {
            self.speed = speed
        }
        if let fontSize = fontSize {
            self.fontSize = fontSize
        }
        if let scale = scale {
            self.scale = scale
        }
        if let autoScroll = autoScroll {
            self.autoScroll = autoScroll
        }
        if let scrollProgress = scrollProgress {
            self.scrollProgress = scrollProgress
        }
        if let serverAddress = serverAddress {
            self.serverAddress = serverAddress
        }
        if let serverPort = serverPort {
            self.serverPort = serverPort
        }
        if let isRunning = isRunning {
            self.isRunning = isRunning
        }
        if let isPipMode = isPipMode {
            self.isPipMode = isPipMode
        }
    }
}




struct ContentView: View {
    
    var startPip: () -> Void
    var startServer: () -> Void
    
    @EnvironmentObject var configuration: Configuration
    
    var body: some View {
        ScrollView {
            VStack {
                Section {
                    TextEditor(text: $configuration.text)
                        .frame(height: 100)
                        .font(.system(size: configuration.fontSize))
                        .foregroundColor(configuration.textColor)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding()
                }
                .background(configuration.textBackground)
                .cornerRadius(20.0)
                .padding(.vertical)
                
                Group {
                    HStack {
                        Text("显示比例")
                        Picker("显示比例", selection: $configuration.scale) {
                            ForEach(Configuration.Scale.allCases, id: \.rawValue) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        Text("字体大小")
                        Slider(value: $configuration.fontSize, in: 10...100, step: 1)
                            .padding(.horizontal)
                        Text("\(Int(configuration.fontSize))").frame(width: 50)
                    }
                    
                    
                    HStack {
                        Text("滚动速度")
                        Slider(value: $configuration.speed, in: 1...100, step: 1)
                            .padding(.horizontal)
                        Text("\(Int(configuration.speed))").frame(width: 50)
                    }

                    HStack {
                        Text("滚动进度")
                        Slider(value: $configuration.scrollProgress, in: 0...100, step: 0.01)
                            .padding(.horizontal)
                        Text("\(String(format: "%.2f", configuration.scrollProgress))%").frame(width: 50)
                    }
                    
                    HStack {
                        Text("文字颜色")
                        Spacer()
                        ColorPicker(configuration.textColor.toHex(), selection: $configuration.textColor)
                    }
                    
                    HStack {
                        Text("背景颜色")
                        Spacer()
                        ColorPicker(configuration.textBackground.toHex(), selection: $configuration.textBackground)
                    }
                    HStack {
                        Text("网页控制")
                        Spacer()
                        Picker("Address", selection: $configuration.serverAddress) {
                            ForEach(localIPv4Address(), id: \.self) { address in
                                Text(address).tag(address)
                            }
                        }.pickerStyle(.menu)
                            .disabled(configuration.isRunning)
                        TextField("Port", text: Binding(get: {
                            "\(configuration.serverPort)"
                        }, set: { (value) in
                            configuration.serverPort = Int(value) ?? 59090
                        })).disabled(configuration.isRunning)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .padding(.trailing)
                    }
                }
                .padding()
                Spacer()
                HStack {
                    if configuration.autoScroll {
                        Button("停止滚动", action: {
                            configuration.autoScroll = false
                        }).buttonStyle(.bordered)
                    } else {
                        Button("开始滚动", action: {
                            configuration.autoScroll = true
                        }).buttonStyle(.bordered)
                    }
                    if !configuration.isRunning {
                        Button("启动服务器", action: startServer).buttonStyle(.bordered)
                    }
                    Button("启动画中画", action: startPip).buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color(white: 0.9))
        .colorScheme(.light)
        .tint(Color.black)
        
    }
}
