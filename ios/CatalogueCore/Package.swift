// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CatalogueCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "CatalogueDomain", targets: ["CatalogueDomain"]),
        .library(name: "CatalogueData", targets: ["CatalogueData"]),
    ],
    targets: [
        .target(name: "CatalogueDomain"),
        .target(name: "CatalogueData", dependencies: ["CatalogueDomain"]),
        .testTarget(name: "CatalogueDomainTests", dependencies: ["CatalogueDomain"]),
        .testTarget(name: "CatalogueDataTests", dependencies: ["CatalogueData"]),
    ]
)
