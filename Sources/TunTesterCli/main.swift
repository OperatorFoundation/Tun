import Foundation
import Tun
import ArgumentParser
import Dispatch
import TransmissionLinux
import Datable
import Flower
import Routing


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


func isValidIPv4Address(address: String) -> Bool
{
    if address == "" { return false }
    if address.range(of: #"^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"#, options: .regularExpression) == nil {
        return false //not a valid IP address
    }
    else
    {
        return true //valid IP address
    }
}


func isValidIPv6Address(address: String) -> Bool
{
    //FIXME: change regex to check for ipv6 instead of ipv4
    /*
    \A(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4} | (?:[A-F0-9]{1,4}:){6}:[A-F0-9]{1,4} | (?:[A-F0-9]{1,4}:){5}(?::[A-F0-9]{1,4}){1,2} | (?:[A-F0-9]{1,4}:){4}(?::[A-F0-9]{1,4}){1,3} | (?:[A-F0-9]{1,4}:){3}(?::[A-F0-9]{1,4}){1,4} | (?:[A-F0-9]{1,4}:){2}(?::[A-F0-9]{1,4}){1,5} | [A-F0-9]{1,4}:(?::[A-F0-9]{1,4}){1,6} | (?:[A-F0-9]{1,4}:){1,7}:| :(?::[A-F0-9]{1,4}){1,7} | ::)\z
    */
    if address == "" { return false }
    if address.range(of: #"^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"#, options: .regularExpression) == nil {
        return false //not a valid IP address
    }
    else
    {
        return true //valid IP address
    }
}

let packetBytes = Data(array: [
    0x45, 0x00, 0x00, 0x54, 0xc1, 0x88, 0x40, 0x00,    0x40, 0x01, 0x54, 0x64, 0x0a, 0x00, 0x08, 0x63,
    0x0a, 0x00, 0x08, 0x5a, 0x08, 0x00, 0x2c, 0x79,    0x49, 0x35, 0x00, 0x05, 0x6e, 0xde, 0x47, 0x5f,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x3c, 0x0d, 0x00,    0x00, 0x00, 0x00, 0x00, 0x10, 0x11, 0x12, 0x13,
    0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b,    0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23,
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b,    0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33,
    0x34, 0x35, 0x36, 0x37])



struct TunTesterCli: ParsableCommand
{
    static var configuration = CommandConfiguration(
            abstract: "Program to test Tun Library, implements simple VPN.",
            discussion: """
                        TunTesterCli can be invoked as either a server or a client. The client/server connection is TCP and forwards packets received on the tun interface over the TCP tunnel

                        Server Example:
                            sudo ./.build/debug/TunTesterCli -s -c 10.37.132.4 -i enp0s5

                        Client Example:
                            sudo ./.build/debug/TunTesterCli -c 10.37.132.4

                        """)

    @Flag(name: [.short, .long], help: "If the server flag is set (i.e. -s or --server-mode) then TunTesterCli will run in server mode, if flag is omitted then it will run in client mode.")
    var serverMode = false

    @Option(name: [.short, .long], default: "127.0.0.1", help: "The IPv4 address. If server mode then it is the IP address to listen on, if client mode then it is the IP addrees of the server to connect to.") //fix with better examples
    var connectionAddress: String

    @Option(name: [.short, .customLong("port")], default: 5555, help: "The TCP port. If server mode then it is the TCP port to listen on, if client mode then it is the TCP port of the server to connect to.") //fix with better examples
    var port: Int

    @Option(name: [.short, .long], default: "", help: "The IPv4 address assigned to the local tun interface in server or client mode. (default: in server mode 10.4.2.1, client mode 10.4.2.100)") //fix with better examples
    var localTunAddress: String

    @Option(name: [.short, .long], default: "10.4.2.1", help: "The IPv4 address assigned to the server's tun interface, required for client mode.") //fix with better examples
    var tunAddressOfServer: String

    @Option(name: [.long], default: "", help: "The IPv4 address assigned to the local tun interface in server or client mode. (default: in server mode fc00:bbbb:bbbb:bb01::1:1, client mode fc00:bbbb:bbbb:bb01::1:b)") //fix with better examples
    var localTunAddressV6: String

    @Option(name: [.long], default: "fc00:bbbb:bbbb:bb01::1:1", help: "The IPv4 address assigned to the server's tun interface, required for client mode.") //fix with better examples
    var tunAddressOfServerV6: String


    @Option(name: [.customShort("i"), .long], default: "", help: "Name of the server's network interface that is connected to the internet, eg enp0s5, eth0, wlan0, etc. Required for server mode.")
    var serverInternetInterface: String

    func validate() throws
    {
        //basic validation of parameters

        guard self.port > 0 && self.port <= 65535 else
        {
            throw ValidationError("The port must be between 1 and 65535. Use --help for more info.")
        }

        if connectionAddress != "" && !isValidIPv4Address(address: connectionAddress)
        {
            throw ValidationError("'\(connectionAddress)' is not a valid IPv4 address for client or server.")
        }


        if localTunAddress != "" && !isValidIPv4Address(address: localTunAddress)
        {
            throw ValidationError("'\(localTunAddress)' is not a valid IPv4 address for the local tun interface.")
        }

        if serverMode
        {
            if serverInternetInterface != ""
            {
                if serverInternetInterface.range(of: #"^([[:digit:][:lower:]]{1,8})$"#, options: .regularExpression) == nil {
                    throw ValidationError("'\(serverInternetInterface)' does not appear to be a valid interface name.")
                }
                else
                {
                    let fileManager = FileManager()
                    let path = "/sys/class/net/" + serverInternetInterface
                    if !fileManager.fileExists(atPath: path)
                    {
                        throw ValidationError("'\(serverInternetInterface)' interface does not seem to exist (\(path)).")
                    }
                }
            }
            else
            {
                throw ValidationError("Server internet interface is required when running server mode.")
            }
        }
        else
        {
            if !isValidIPv4Address(address: connectionAddress) // tun address of server to connect to
            {
                throw ValidationError("'\(connectionAddress)' is not a valid IPv4 address for the connection address.")
            }
        }
    }

    func run() throws
    {
        print("Sleeping 2 seconds to allow debugger to attach to process...")
        sleep(2)

        print("Hello, Operator.")
        print("Local tun address: \(localTunAddress)")

        var tunA = localTunAddress

        if tunA == "" {
            print("Tun address parameter omitted, using default values")
            if serverMode {
                tunA = "10.4.2.1"

            } else {
                tunA = "10.4.2.100"
            }
        }

        var tunAv6 = ""
        if tunAv6 == "" {
            print("Tun address parameter omitted, using default values")
            if serverMode {
                tunAv6 = "fc00:bbbb:bbbb:bb01::1:1"

            } else {
                tunAv6 = "fc00:bbbb:bbbb:bb01::1:b"
            }
        }


        if serverMode
        {
            //[TX][RX]
            print("[S]Mode: server")
            let reader: (Data) -> Void = {
                data in
                //print("\n\n[S][TUN][RX] Tun RX bytes: \(data.count)\n\n")
                //print("Data: ")
                //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
            }

            guard let tun  = TunDevice(address: tunA, reader: reader) else { return }

            guard let tunName = tun.maybeName else { return }
            setAddressV6(interfaceName: tunName, addressString: tunAv6, subnetPrefix: 64)

            setIPv4Forwarding(setTo: true)
            setIPv6Forwarding(setTo: true)

            print("[S] Deleting all ipv4 NAT entries for \(serverInternetInterface)")
            var result4 = false
            while !result4 {
                result4 = deleteServerNAT(serverPublicInterface: serverInternetInterface)
            }

            print("[S] Deleting all ipv6 NAT entries for \(serverInternetInterface)")
            var result6 = false
            while !result6 {
                result6 = deleteServerNATv6(serverPublicInterface: serverInternetInterface)
            }

            configServerNAT(serverPublicInterface: serverInternetInterface)
            print("[S] Current ipv4 NAT: \n\n\(getNAT())\n\n")

            configServerNATv6(serverPublicInterface: serverInternetInterface)
            print("[S] Current ipv6 NAT: \n\n\(getNATv6())\n\n")


            guard let listener = Listener(port: port) else { return }
            print("[S][CHA] Listening for client")
            guard let connection = listener.accept() else { return }
            print("[S][CHA] Connection established\n\n")


            let networkToTunQueue = DispatchQueue(label: "networkToTunQueue")
            networkToTunQueue.async
            {
                var countTCP = 0
                var tunErrorCount = 0
                var zeroByteCount = 0
                while true
                {
                    guard let sizeData = connection.read(size: 2) else { return }
                    countTCP += 1
                    print("\n\n[S][CHA][RX] Count TCP RX: \(countTCP)")
                    print("[S][CHA][RX] sizeData: ")
                    _ = printDataBytes(bytes: sizeData, hexDumpFormat: true, seperator: "", decimal: false)

                    if sizeData.count > 2
                    {
                        print("[S][CHA][RX] ERROR    TCP RX size byte count wrong, too many bytes")
                        if sizeData[2] == 0x60 || sizeData[2] == 0x45
                        {
                            var sizeDataParsed = sizeData[0..<2]
                            var dataParsed = sizeData[2..<sizeData.count]

                            guard let sizeUint16 = sizeDataParsed.uint16 else {
                                return
                            }
                            let size = Int(sizeUint16)

                            if size == dataParsed.count
                            {
                                let bytesWritten = tun.writeBytes(dataParsed)
                                print("[S][TUN][TX] tun write return value: \(bytesWritten)")
                            }


                        }

                    }
                    else
                    {

                        if sizeData.count == 0 {
                            zeroByteCount += 1
                        } else {
                            zeroByteCount = 0
                        }

                        if zeroByteCount > 1 {
                            break
                        }

                        if sizeData.count == 2 {
                            guard let sizeUint16 = sizeData.uint16 else {
                                return
                            }
                            let size = Int(sizeUint16)
                            print("[S][CHA][RX] received read size: \(size)")
                            if let data = connection.read(size: size) {
                                //print("[S][CHA][RX] TCP RX data:")
                                //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                                if data.count != size
                                {
                                    print("[S] ERROR tried to receive \(size) bytes, instead got \(data.count) bytes")
                                    print("[S] bytes received:")
                                    _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
                                }


                                let bytesWritten = tun.writeBytes(data)
                                print("[S][TUN][TX] bytesWritten: \(bytesWritten)")

                                if bytesWritten != 0 {
                                    tunErrorCount += 1
                                    print("[S][TUN][TX] error writing to tun. # \(tunErrorCount)")
                                    //break
                                }
                            } else {
                                print("break")
                                break
                                abort()
                            }
                        }
                    }

                }
            }

            var countTUN = 0
            while true
            {
                if let data = tun.read(packetSize: 1500)
                {
                    countTUN += 1
                    print("\n\n[S][TUN][RX] tun rx packet Count: \(countTUN)")
                    //print("[S][TUN][RX] Tun RX data:")
                    //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
                    let dataSize = data.count
                    let dataSizeUInt16 = UInt16(dataSize)
                    connection.write(data: dataSizeUInt16.data)
                    connection.write(data: data)
                }
            }
        }
        else
        {

            print("[C] Mode: client")

            let reader: (Data) -> Void = {
                data in
                //print("Number of bytes: \(data.count)")
                //print("\n\n[C][TUN][RX] Tun RX bytes: \(data.count)\n\n")
                //print("Data: ")
                //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
            }

            guard let tun  = TunDevice(address: tunA, reader: reader) else { return }

            guard let tunName = tun.maybeName else { return }
            setAddressV6(interfaceName: tunName, addressString: tunAv6, subnetPrefix: 64)

            setIPv4Forwarding(setTo: true)
            setIPv6Forwarding(setTo: true)


            setClientRoute(serverTunAddress: tunAddressOfServer, localTunName: tunName)
            print("[C] ipv4 route has been set")

            setClientRouteV6(serverTunAddress: tunAddressOfServerV6, localTunName: tunName)
            print("[C] ipv6 route has been set")


            guard let connection = Connection(host: connectionAddress, port: port) else { return }
            print("[C][CHA] Connection established\n\n")

//            connection.readMessages
//            {
//                message in
//
//                switch message
//                {
//                case .IPDataV4(let data):
//                    print("Received an IPv4 packet")
//                case .IPDataV6(let data):
//                    print("Receieved an IPv6 packet")
//                }
//            }

            let networkToTunQueue = DispatchQueue(label: "networkToTunQueue")
            networkToTunQueue.async
            {
                var countTCP = 0
                var tunErrorCount = 0
                var zeroByteCount = 0
                while true
                {
                    guard let sizeData = connection.read(size: 2) else { return }
                    print("\n\n[C][CHA][RX] sizeData: ")
                    _ = printDataBytes(bytes: sizeData, hexDumpFormat: true, seperator: "", decimal: false)

                    countTCP += 1
                    print("[C][CHA][RX] TCP RX count: \(countTCP)")


                    if sizeData.count > 2
                    {
                        if sizeData[2] == 0x60 || sizeData[2] == 0x45
                        {
                            var sizeDataParsed = sizeData[0..<2]
                            var dataParsed = sizeData[2..<sizeData.count]

                            guard let sizeUint16 = sizeDataParsed.uint16 else {
                                return
                            }
                            let size = Int(sizeUint16)

                            if size == dataParsed.count
                            {
                                let bytesWritten = tun.writeBytes(dataParsed)
                                print("[S][TUN][TX] tun write return value: \(bytesWritten)")
                            }


                        }
                    }
                    else
                    {

                        if sizeData.count == 0 {
                            zeroByteCount += 1
                        } else {
                            zeroByteCount = 0
                        }

                        if zeroByteCount > 1 {
                            print("break")
                            break
                            abort()
                        }

                        if sizeData.count == 2 {
                            guard let sizeUint16 = sizeData.uint16 else {
                                return
                            }
                            let size = Int(sizeUint16)

                            if let data = connection.read(size: size) {
                                print("[C][CHA][RX] TCP RX data:")
                                _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                                if data.count != size
                                {
                                    print("[S] ERROR tried to receive \(size) bytes, instead got \(data.count) bytes")
                                    print("[S] bytes received:")
                                    _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
                                }

                                let bytesWritten = tun.writeBytes(data)
                                print("[C][TUN][TX] tun write return value: \(bytesWritten)")

                                if bytesWritten != 0 {
                                    tunErrorCount += 1
                                    print("[C][TUN][TX] error writing to tun. # \(tunErrorCount)")
                                    //break
                                }
                            } else {
                                break
                            }
                        }
                    }



                }
            }

            var countTUN = 0
            while true
            {

                if let data = tun.read(packetSize: 1500)
                {
                    countTUN += 1
                    print("\n\n[C][TUN][RX] Tun Count: \(countTUN)")

                    //print("[C][TUN][RX] Tun RX data:")
                    //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                    let dataSize = data.count
                    //print("[C][CHA][TX] Client dataSize: \(dataSize)")
                    let dataSizeUInt16 = UInt16(dataSize)
                    print("[C][CHA][TX] Client write size: \(dataSizeUInt16)")
                    connection.write(data: dataSizeUInt16.data)
                    connection.write(data: data)
                }
            }
        }
    }
}

TunTesterCli.main()
RunLoop.current.run()

