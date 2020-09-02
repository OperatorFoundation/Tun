import Foundation
import Tun
import NIO
import ArgumentParser
import Dispatch


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

//var haveData: Bool = false
//var theData = Data()
//
//var haveTunData: Bool = false
//var theTunData = Data()







private final class TrafficHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    public var shuttle = DataShuttle()



    public func writeDataFromTun(data: Data)
    {
        //context.writeAndFlush(self.wrapOutboundOut(read), promise: nil)
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        //handles incoming data over the TCP connection
        print("got tcp data")
        let id = ObjectIdentifier(context.channel)
        var read = self.unwrapInboundIn(data)
        guard let bytes = read.readBytes(length: read.readableBytes) else { return }

        var theData = Data(bytes)

//        guard let tun = self.tunDevice else { return }
//        tun.writeV4(theData)

        //context.writeAndFlush(self.wrapOutboundOut(read), promise: nil)
        shuttle.writeToTunDevice(bytes: theData)
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func channelActive(context: ChannelHandlerContext) {
        let remoteAddress = context.remoteAddress!
        let channel = context.channel
        print( "Connected with remote address: \(remoteAddress)\n")
        shuttle.channel = channel
        print(channel)

//        var buffer = channel.allocator.buffer(capacity: 64)
//        buffer.writeString("Hello\n") //send some test data backAAC
//        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

    }

    public func channelInactive(context: ChannelHandlerContext) {

        let remoteAddress = context.remoteAddress!
        print( "Disconnect with address: \(remoteAddress)\n")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
}




public struct DataShuttle
{
    public var channel: Channel?
    public var tun: TunDevice?

    public func writeToChannel(bytes: Data)
    {
        print("shuttle write channel, bytes:")
        _ = printDataBytes(bytes: bytes, hexDumpFormat: true, seperator: "", decimal: false)
        guard let channel = self.channel else { return }
        print(channel)
        if channel.isWritable {
            print("shuttle try to write to ch")
            var buffer = channel.allocator.buffer(capacity: bytes.count)
            buffer.writeBytes(bytes)
            try! channel.writeAndFlush(buffer)
            print("shuttle post try to write to ch")
        }


        //channel.writeAndFlush(bytes)

        print("shuttle end write channel")
        //ch.writeAndFlush(ch.wrapOutboundOut(read), promise: nil)
    }

    public func writeToTunDevice(bytes: Data)
    {
        print("shutle write tun, bytes:")
        _ = printDataBytes(bytes: bytes, hexDumpFormat: true, seperator: "", decimal: false)
        guard let tun = self.tun else { return }
        tun.writeV4(bytes)
        print("shuttle wrote tun")
    }

    init()
    {
        self.channel = nil
        self.tun = nil
    }

}


//public func takeData(data: NIOAny)
//{
//    print("data: \(data)")
//}


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

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        var shuttle = DataShuttle()

        let reader: (Data) -> Void = {
            data in
            //packetCount += 1
            //print("packet count: \(packetCount)")
            print("Number of bytes: \(data.count)")
            print("Data: ")
            _ = printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
            //theTunData = data
            //haveTunData = true
            //try! channel.writeAndFlush(data).wait()
            shuttle.writeToChannel(bytes: data)
        }

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

        guard let tun  = TunDevice(address: tunA, reader: reader) else { return }
        shuttle.tun = tun

        if server
        {
            print("Mode: server")




            var trafficHandler = TrafficHandler()
            trafficHandler.shuttle = shuttle
            let bootstrap = ServerBootstrap(group: group)
                    // Specify backlog and enable SO_REUSEADDR for the server itself
                    .serverChannelOption(ChannelOptions.backlog, value: 256)
                    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)


                    // Set the handlers that are appled to the accepted Channels
                    .childChannelInitializer { channel in
                        // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                        channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                            channel.pipeline.addHandler(trafficHandler)
                        }
                    }

                    // Enable SO_REUSEADDR for the accepted Channels
                    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
                    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
            defer {
                try! group.syncShutdownGracefully()
            }

            enum BindTo {
                case ip(host: String, port: Int)
            }

            let bindTarget: BindTo
            bindTarget = .ip(host: address, port: port)

            let channel = try { () -> Channel in
                switch bindTarget {
                case .ip(let host, let port):
                    return try bootstrap.bind(host: host, port: port).wait()
                }
            }()
            //shuttle.channel = channel
            print("Server started and listening on \(channel.localAddress!)")


            //channel.

            //FIXME: tun doesn't work, however if the following line is commented out, tun works and tcp channel doesn't
            //try shuttle.channel?.closeFuture.wait()
            try channel.closeFuture.wait()
            //print("post closeFuture")
        }
        else
        {
            print("Mode: client")

            var trafficHandler = TrafficHandler()
            trafficHandler.shuttle = shuttle

            let bootstrap = ClientBootstrap(group: group)
                    // Enable SO_REUSEADDR.
                    .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                    .channelInitializer { channel in
                        channel.pipeline.addHandler(trafficHandler)
                    }
            defer {
                try! group.syncShutdownGracefully()
            }

            enum ConnectTo {
                case ip(host: String, port: Int)
            }

            let connectTarget: ConnectTo
            connectTarget = .ip(host: address, port: port)

            let channel = try { () -> Channel in
                switch connectTarget {
                case .ip(let host, let port):
                    return try bootstrap.connect(host: host, port: port).wait()
                }
            }()
            shuttle.channel = channel
            //FIXME: similar to the above server functionality, either tun works or the tcp channel works. If the server is killed while client is connected then tun will start working.
            try channel.closeFuture.wait()
            //try shuttle.channel?.closeFuture.wait()


        }

//        while true {
//            if haveData
//            {
//                print("got tunnel data")
//                haveData = false
//                tun.writeV4(theData)
//            }
//
//            if haveTunData
//            {
//                print("got Tun data")
//                haveTunData = false
//                //write data to the the tcp channel
//            }
//
//        }


    }




}


TunTesterCli.main()
RunLoop.current.run()










