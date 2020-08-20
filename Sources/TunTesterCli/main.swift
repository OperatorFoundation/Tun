import Foundation
import Tun
import InternetProtocols


print("Sleeping 2 seconds to allow debugger to attach to process...")
sleep(2)

print("Hello, Operator.")

var address = "10.11.12.13"

if CommandLine.arguments.count > 1 {
    address = CommandLine.arguments[1]
}
print("Address: \(address)")

var packetCount = 0

let reader: (Data, UInt32) -> Void = {
    data, protocolNumber in
    packetCount += 1
    print("packet count: \(packetCount)")
    print("protocolNumber: \(protocolNumber)")
    print("Number of bytes: \(data.count)")
    print("Data: ")
    printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
}

if let tun = TunDevice(address: address, reader: reader) {
    
    print("tun: \(tun)")

    while true {
        print(".")
        guard let result = tun.read(packetSize: 1500) else {
            print("No result of tun.read")
            break
        }
        print("Result of read: \(result)")
    }
}

RunLoop.current.run()
