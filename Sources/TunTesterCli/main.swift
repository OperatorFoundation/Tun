import Foundation

import Tun

print("Hello, Operator.")

var address = "10.0.0.1"

if CommandLine.arguments.count > 0 {
    address = CommandLine.arguments[0]
}

let reader: (Data, UInt32) -> Void = {
    data, protocolNumber in
    
    print(data)
    print(protocolNumber)
}

if let tun = TunDevice(address: address, reader: reader) {
    print(tun)

    while true {
        guard let result = tun.read(packetSize: 1024) else {
            break
        }
        
        print(result)
    }
}

RunLoop.current.run()
