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


let packetBytes = Data(array: [
    0x45, 0x00, 0x00, 0x54, 0xc1, 0x88, 0x40, 0x00,    0x40, 0x01, 0x54, 0x64, 0x0a, 0x00, 0x08, 0x63,
    0x0a, 0x00, 0x08, 0x5a, 0x08, 0x00, 0x2c, 0x79,    0x49, 0x35, 0x00, 0x05, 0x6e, 0xde, 0x47, 0x5f,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x3c, 0x0d, 0x00,    0x00, 0x00, 0x00, 0x00, 0x10, 0x11, 0x12, 0x13,
    0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b,    0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23,
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b,    0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33,
    0x34, 0x35, 0x36, 0x37])


public struct DataShuttle
{
//    public var channel: Channel?
//    public var channels: [ObjectIdentifier: Channel] = [:]
//    public var channelID: ObjectIdentifier?
    public var tun: TunDevice?
    public let timestamp = NSDate().timeIntervalSince1970


    public func writeToChannelServer(bytes: Data)
    {
        print("Server write to channel:")
        print("Shuttle ID: \(self.timestamp)")
//        print("self.channels: \(self.channels)")
//        print("self.channelID: \(self.channelID)")
    }




    public func writeToChannel(bytes: Data)
    {
        print("Shuttle ID: \(self.timestamp)")
        //print("Channel: \(self.channel)")
        print("Tun: \(self.tun)")
        print("Shuttle write channel, bytes:")
        _ = printDataBytes(bytes: bytes, hexDumpFormat: true, seperator: "", decimal: false)
//        guard let channel = self.channel else { return }
//
//        if channel.isWritable {
//            print("Shuttle try to write to ch")
//            var buffer = channel.allocator.buffer(capacity: bytes.count)
//            buffer.writeBytes(bytes)
//            try! channel.writeAndFlush(buffer)
//            print("Shuttle post try to write to ch")
//        }

        //channel.writeAndFlush(bytes)

        print("Shuttle end write channel")
        //ch.writeAndFlush(ch.wrapOutboundOut(read), promise: nil)
    }

    public func writeToTunDevice(bytes: Data)
    {
        print("Shuttle ID: \(timestamp)")
        print("shutle write tun, bytes:")
        _ = printDataBytes(bytes: bytes, hexDumpFormat: true, seperator: "", decimal: false)
        guard let tun = self.tun else { return }
        tun.writeV4(bytes)
        print("shuttle wrote tun")
    }

    init()
    {
        //self.channel = nil
        self.tun = nil
    }

}


struct TunTesterCli: ParsableCommand
{
    static var configuration = CommandConfiguration(
            abstract: "Program to test Tun Library, implements simple VPN.",
            discussion: """
                        TunTesterCli can be invoked as either a server or a client. The client/server connection is TCP and forwards packets received on the tun interface over the TCP tunnel
                        """)

    @Flag(name: [.short, .customLong("server")], help: "If the server flag is set (i.e. -s or --server) then TunTesterCli will run in server mode, if flag is omitted then it will run in client mode.")
    var server = false

    @Option(name: [.short, .customLong("ip")], default: "127.0.0.1", help: "The IPv4 address. If server mode then it is the IP address to listen on, if client mode then it is the IP addrees of the server to connect to.") //fix with better examples
    var address: String

    @Option(name: [.short, .customLong("port")], default: 5555, help: "The TCP port. If server mode then it is the TCP port to listen on, if client mode then it is the TCP port of the server to connect to.") //fix with better examples
    var port: Int

    @Option(name: [.short, .customLong("tun")], default: "", help: "The IPv4 address assigned to the tun interface. ") //fix with better examples
    var tunAddress: String

    func validate() throws
    {
        guard self.port > 0 && self.port <= 65535 else
        {
            throw ValidationError("The port must be between 1 and 65535. Use --help for more info.")
        }

        if address.range(of: #"^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"#, options: .regularExpression) == nil
        {
            throw ValidationError("'\(address)' is not a valid IPv4 address for client or server.")
        }

        if tunAddress != "" {
            if tunAddress.range(of: #"^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"#, options: .regularExpression) == nil {
                throw ValidationError("'\(tunAddress)' is not a valid IPv4 address for the tun interface.")
            }
        }

    }

    func run() throws
    {

        print("Sleeping 2 seconds to allow debugger to attach to process...")
        sleep(2)

        print("Hello, Operator.")
        print("Tunnel set to use address: \(address)")

        var tunA = tunAddress
        if tunA == "" {
            print("Tun address parameter omitted, using default values")
            if server {
                tunA = "10.4.2.5"
            } else {
                tunA = "10.4.2.99"
            }
        }

        print("Setting tun interface address to: \(tunA)")

        if server
        {
            print("Mode: server")
            let reader: (Data) -> Void = {
                data in
                //packetCount += 1
                //print("packet count: \(packetCount)")
                print("Number of bytes: \(data.count)")
                print("Data: ")
                _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

            }

            guard let tun  = TunDevice(address: tunA, reader: reader) else { return }

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

                    if let data = connection.read(size: size) {
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
                //packetCount += 1
                //print("packet count: \(packetCount)")
                print("Number of bytes: \(data.count)")
                print("Data: ")
                _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)

                //shuttle.writeToChannel(bytes: data)
            }


            guard let tunMain  = TunDevice(address: tunA, reader: reader) else { return }

            guard let tun  = TunDevice(address: tunA, reader: reader) else { return }

            guard let connection = Connection(host: address, port: port) else { return }

            let networkToTunQueue = DispatchQueue(label: "networkToTunQueue")



            networkToTunQueue.async
            {
                while true
                {
                    guard let sizeData = connection.read(size: 2) else { return }

                    guard let sizeUint16 = sizeData.uint16 else { return }
                    let size = Int(sizeUint16)

                    if let data = connection.read(size: size) {
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
                    let dataSize = data.count
                    let dataSizeUInt16 = UInt16(dataSize)
                    connection.write(data: dataSizeUInt16.data)
                    connection.write(data: data)
                }

            }

        }

    }




}


TunTesterCli.main()
RunLoop.current.run()










