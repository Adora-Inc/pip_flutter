// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "pip_flutter",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "pip-flutter", targets: ["pip_flutter"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "pip_flutter",
      dependencies: [],
      cSettings: [
        .headerSearchPath("include/pip_flutter")
      ]
    )
  ]
)
