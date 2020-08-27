import Foundation
import Tun

func printDataBytes(bytes: Data, hexDumpFormat: Bool, seperator: String, decimal: Bool, enablePrinting: Bool = true) -> String
{
    var returnString: String = ""
    if hexDumpFormat
    {
        var count = 0
        var newLine: Bool = true
        for byte in bytes
        {
            if newLine
            {
                if enablePrinting { print("・ ", terminator: "") }
                newLine = false
            }
            if enablePrinting { print(String(format: "%02x", byte), terminator: " ") }
            returnString += String(format: "%02x", byte)
            returnString += " "
            count += 1
            if count % 8 == 0
            {
                if enablePrinting { print(" ", terminator: "") }
                returnString += " "
            }
            if count % 16 == 0
            {
                if enablePrinting { print("") }
                returnString += "\n"
                newLine = true
            }
        }
    }
    else
    {
        var i = 0
        for byte in bytes
        {
            if decimal
            {
                if enablePrinting { print(String(format: "%u", byte), terminator: "") }
                returnString += String(format: "%u", byte)
            }
            else
            {
                if enablePrinting { print(String(format: "%02x", byte), terminator: "") }
                returnString += String(format: "%02x", byte)
            }
            i += 1
            if i < bytes.count
            {
                if enablePrinting { print(seperator, terminator: "") }
                returnString += seperator
            }
        }
    }
    if enablePrinting { print("") }
    return returnString
}

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
    _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
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
