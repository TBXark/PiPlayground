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
    @Published var textColorHex: String = "FFFFFF"
    @Published var textBackgroundHex: String = "000000"
    @Published var speed: CGFloat = 1
    @Published var fontSize: CGFloat = 30
    @Published var scale: Scale = .h3x1
    @Published var autoScroll: Bool = false
    @Published var scrollProgress: CGFloat = 0
    @Published var serverAddress = "0.0.0.0"
    @Published var serverPort = 59090
    
    @Published var isRunning = false
    @Published var isPipMode = false
    
    
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
                        .foregroundColor(Color(hex: configuration.textColorHex))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding()
                }
                .background(Color(hex: configuration.textBackgroundHex))
                .cornerRadius(20.0)
                .padding(.vertical)
                
                Group {
                    Text("自定义样式").font(.title)
                    
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
                        Text("文字颜色")
                        Spacer()
                        TextField("文字颜色", text: $configuration.textColorHex)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                        Rectangle()
                            .fill(Color(hex: configuration.textColorHex))
                            .frame(width: 20, height: 20)
                        
                    }
                    
                    HStack {
                        Text("背景颜色")
                        Spacer()
                        TextField("背景颜色", text: $configuration.textBackgroundHex)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                        Rectangle()
                            .fill(Color(hex: configuration.textBackgroundHex))
                            .frame(width: 20, height: 20)
                    }
                    HStack {
                        Text("服务器地址")
                        Spacer()
                        TextField("Address", text: $configuration.serverAddress)
                            .textFieldStyle(.roundedBorder)
                            .padding(.leading)
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
