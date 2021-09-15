// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tun",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        
        .library(
            name: "Tun",
            targets: ["Tun", "TunC"]),
        .executable(name: "TunTesterCli", targets: ["TunTesterCli"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", from: "3.0.6"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", from: "1.1.14"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionLinux.git", from: "0.3.4"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.4"),
        .package(url: "https://github.com/OperatorFoundation/Flower.git", from: "0.1.17"),
        .package(url: "https://github.com/OperatorFoundation/Routing.git", from: "0.0.9"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "TunC",
            dependencies: []),
        .target(
            name: "Tun",
            dependencies: ["Datable", "TunC", "Routing"]),
        .target(
		name: "TunTesterCli",
		dependencies:
		[
			"Tun",
			"Routing",
			"Flower",
			.product(name: "TransmissionLinux", package: "TransmissionLinux", condition: .when(platforms: [.linux])),
			.product(name: "ArgumentParser", package: "swift-argument-parser")
		]
	),
        .testTarget(
		name: "TunTests",
		dependencies: ["Tun", "InternetProtocols"],
		exclude: ["Tun-Package.xctestplan"]
	),
    ],
    swiftLanguageVersions: [.v5]
)
