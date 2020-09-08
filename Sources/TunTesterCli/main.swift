import Foundation
import Tun
import ArgumentParser
import Dispatch
import TransmissionLinux
import Datable


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





struct TunTesterCli: ParsableCommand
{
    static var configuration = CommandConfiguration(
            abstract: "Program to test Tun Library, implements simple VPN.",
            discussion: """
                        TunTesterCli can be invoked as either a server or a client. The client/server connection is TCP and forwards packets received on the tun interface over the TCP tunnel

                        Server Example:

                        Client Example:

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

        print("Setting tun interface address to: \(tunA)")

        if serverMode
        {
            print("Mode: server")
            let reader: (Data) -> Void = {
                data in
                //print("Number of bytes: \(data.count)")
                //print("Data: ")
                //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

            }

            guard let tun  = TunDevice(address: tunA, reader: reader) else { return }

            tun.setIPv4Forwarding(setTo: true)
            tun.configServerNAT(serverPublicInterface: serverInternetInterface, deleteNAT: true)
            tun.configServerNAT(serverPublicInterface: serverInternetInterface, deleteNAT: false)

            guard let listener = Listener(port: port) else { return }

            let networkToTunQueue = DispatchQueue(label: "networkToTunQueue")

            guard let connection = listener.accept() else { return }

            networkToTunQueue.async
            {
                while true
                {
                    guard let sizeData = connection.read(size: 2) else { return }

                    guard let sizeUint16 = sizeData.uint16 else { return }
                    let size = Int(sizeUint16)
                    print("Server read size: \(size)")
                    if let data = connection.read(size: size) {
                        print("TCP RX data:")
                        _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
                        tun.writeV4(data)
                    }
                    else
                    {
                        break
                    }
                }


            }

            while true
            {
                if let data = tun.read(packetSize: 1500)
                {
                    print("Tun RX data:")
                    _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                    let dataSize = data.count
                    let dataSizeUInt16 = UInt16(dataSize)
                    connection.write(data: dataSizeUInt16.data)
                    connection.write(data: data)
                }

            }

        }
        else
        {
            print("Mode: client")

            let reader: (Data) -> Void = {
                data in
                //print("Number of bytes: \(data.count)")
                //print("Data: ")
                //_ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
            }

            guard let tun  = TunDevice(address: tunA, reader: reader) else { return }
            tun.setIPv4Forwarding(setTo: true)
            //when in client mode add routing table entry
            guard let tunName = tun.maybeName else { return }
            tun.setClientRoute(serverTunAddress: tunAddressOfServer, localTunName: tunName)


            guard let connection = Connection(host: localTunAddress, port: port) else { return }

            let networkToTunQueue = DispatchQueue(label: "networkToTunQueue")



            networkToTunQueue.async
            {
                while true
                {
                    guard let sizeData = connection.read(size: 2) else { return }

                    guard let sizeUint16 = sizeData.uint16 else { return }
                    let size = Int(sizeUint16)

                    if let data = connection.read(size: size) {
                        print("TCP RX data:")
                        _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                        tun.writeV4(data)
                    }
                    else
                    {
                        break
                    }
                }
            }

            while true
            {
                if let data = tun.read(packetSize: 1500)
                {
                    print("Tun RX data:")
                    _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                    let dataSize = data.count
                    let dataSizeUInt16 = UInt16(dataSize)
                    print("Client write size: \(dataSizeUInt16)")
                    connection.write(data: dataSizeUInt16.data)
                    connection.write(data: data)
                }

            }

        }

    }
}

TunTesterCli.main()
RunLoop.current.run()










