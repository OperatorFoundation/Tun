import Foundation

import Tun


print("Sleeping 2 seconds to allow debugger to attach to process...")
sleep(2)

print("Hello, Operator.")

var address = "10.2.0.1"

if CommandLine.arguments.count > 1 {
    address = CommandLine.arguments[1]
}
print("Address: \(address)")

let reader: (Data, UInt32) -> Void = {
    data, protocolNumber in
    
    print(data)
    print(protocolNumber)
}

if let tun = TunDevice(address: address, reader: reader) {
    print(tun)

    while true {
        guard let result = tun.read(packetSize: 1024) else {
            print("No result of tun.read")
            break
        }
        print("Result of read: \(result)")
    }
}

RunLoop.current.run()
