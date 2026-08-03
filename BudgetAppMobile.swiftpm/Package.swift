// swift-tools-version: 5.7

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "BudgetAppMobile",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "BudgetAppMobile",
            targets: ["BudgetAppMobile"],
            bundleIdentifier: "com.vinod.budgetappmobile",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .bag),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "BudgetAppMobile"
        )
    ]
)
