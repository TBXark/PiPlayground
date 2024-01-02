//
//  Color.swift
//  PiPlayground
//
//  Created by tbxark on 12/29/23.
//

import UIKit
import SwiftUI

extension Color {

    init?(hex: String) {
        guard let (a, r, g, b) = Color.hex2ARGB(hex: hex) else {
            return nil
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String {
        let components = self.cgColor!.components!
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }

    func toUIColor() -> UIColor {
        let components = self.cgColor!.components!
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
    }

    static func hex2ARGB(hex: String) -> (a: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat)? {
        var hexStr = hex
        if hexStr.hasPrefix("#") {
            hexStr = String(hexStr.dropFirst())
        }
        let scanner = Scanner(string: hexStr)
        var hexInt: UInt64 = 0
        guard scanner.scanHexInt64(&hexInt) else {
            return nil
        }
        switch hexStr.count {
        case 3: // RGB (12-bit)
            let divisor = CGFloat(15)
            let r = CGFloat((hexInt & 0xF00) >> 8) / divisor
            let g = CGFloat((hexInt & 0x0F0) >> 4) / divisor
            let b = CGFloat(hexInt & 0x00F) / divisor
            return (1, r, g, b)
        case 4: // ARGB (16-bit)
            let divisor = CGFloat(15)
            let a = CGFloat((hexInt & 0xF000) >> 12) / divisor
            let r = CGFloat((hexInt & 0x0F00) >> 8) / divisor
            let g = CGFloat((hexInt & 0x00F0) >> 4) / divisor
            let b = CGFloat(hexInt & 0x000F) / divisor
            return (a, r, g, b)
        case 6: // RGB (24-bit)
            let divisor = CGFloat(255)
            let r = CGFloat((hexInt & 0xFF0000) >> 16) / divisor
            let g = CGFloat((hexInt & 0x00FF00) >> 8) / divisor
            let b = CGFloat(hexInt & 0x0000FF) / divisor
            return (1, r, g, b)
        case 8: // ARGB (32-bit)
            let divisor = CGFloat(255)
            let a = CGFloat((hexInt & 0xFF000000) >> 24) / divisor
            let r = CGFloat((hexInt & 0x00FF0000) >> 16) / divisor
            let g = CGFloat((hexInt & 0x0000FF00) >> 8) / divisor
            let b = CGFloat(hexInt & 0x000000FF) / divisor
            return (a, r, g, b)
        default:
            return nil
        }
    }
    
}

extension UIColor {

    convenience init?(hex: String) {
        guard let (a, r, g, b) = Color.hex2ARGB(hex: hex) else {
            return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
}

func localIPv4Address() -> [String] {
    var address = ["127.0.0.1", "0.0.0.0"]
    // 获取所有网卡本地IPv4地址
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    guard getifaddrs(&ifaddr) == 0 else {
        return address
    }
    guard let firstAddr = ifaddr else {
        return address
    }
    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let flags = Int32(ptr.pointee.ifa_flags)
        let addr = ptr.pointee.ifa_addr.pointee
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
            if addr.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                    address.append(String(cString: hostname))
                }
            }
        }
    }
    freeifaddrs(ifaddr)
    return address
}
