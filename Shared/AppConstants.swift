//
//  AppConstants.swift
//  PiStats
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI

// MARK: - System Images
public struct SystemImages {
    // Pi-hole Status
    public static let piholeStatusOnline = "checkmark.shield.fill"
    public static let checkmarkShieldFill = "checkmark.shield.fill"
    public static let piholeStatusOffline = "xmark.shield.fill"
    public static let xmarkShieldFill = "xmark.shield.fill"
    public static let piholeStatusWarning = "exclamationmark.shield.fill"
    public static let exclamationmarkShieldFill = "exclamationmark.shield.fill"
    
    // Navigation & Actions
    public static let plus = "plus"
    public static let plusCircleFill = "plus.circle.fill"
    public static let gearshape = "gearshape"
    public static let infoCircle = "info.circle"
    public static let trash = "trash"
    public static let deleteButton = "minus.circle.fill"
    public static let manage = "list.bullet.circle"
    public static let quit = "power.circle.fill"
    
    // Pi-hole Setup
    public static let piholeSetupHost = "server.rack"
    public static let piholeSetupDisplayName = "person.crop.square.fill.and.at.rectangle"
    public static let piholeSetupPort = "globe"
    public static let piholeSetupToken = "key"
    public static let piholeSetupTokenQRCode = "qrcode"
    public static let piholeSetupMonitor = "binoculars"
    
    // Statistics
    public static let globe = "globe"
    public static let totalQueries = "globe"
    public static let queriesBlocked = "hand.raised"
    public static let handRaised = "hand.raised"
    public static let percentBlocked = "chart.pie"
    public static let chartPie = "chart.pie"
    public static let domainsOnBlockList = "list.bullet"
    
    // Controls
    public static let enablePiholeButton = "play.fill"
    public static let disablePiholeButton = "stop.fill"
    
    // Settings
    public static let settingsDisplayAsList = "list.bullet"
    public static let settingsDisplayAllPiholesInSingleCard = "square.split.2x2"
    public static let settingsDisplayIconBadgeForOffline = "app.badge"
    public static let settingsDisablePermanently = "xmark.shield"
    public static let customizeDisableTimes = "clock"
    public static let addNewCustomDisableTime = "plus"
    
    // Pi Monitor
    public static let piMonitorInfoButton = "info.circle"
    public static let metricTemperature = "thermometer"
    public static let metricUptime = "power"
    public static let metricLoadAverage = "cpu"
    public static let metricMemoryUsage = "memorychip"
    public static let piMonitorTemperature = "thermometer"
    
    // App & Platform
    public static let shieldLefthalfFill = "shield.lefthalf.fill"
    public static let shieldSlash = "shield.slash"
    public static let piStatsSourceCode = "terminal"
    public static let piStatsMacOS = "desktopcomputer"
    public static let leaveReview = "heart"
    
    // Alerts & Errors
    public static let errorMessageWarning = "exclamationmark.triangle.fill"
}

// MARK: - User Text
public struct UserText {
    // MARK: - Common Actions
    public static let saveButton = "Save"
    public static let cancelButton = "Cancel"
    public static let deleteButton = "Delete"
    public static let enableButton = "Enable"
    public static let disableButton = "Disable"
    public static let closeButton = "Close"
    public static let doneButton = "Done"
    
    // MARK: - Pi-hole Status
    public static let statusEnabled = "Active"
    public static let statusDisabled = "Offline"
    public static let statusNeedsAttention = "Needs Attention"
    public static let statusEnabledAndDisabled = "Partially Active"
    public static let statusUnknown = "Unknown"
    
    // MARK: - Pi-hole Row Status Text
    public struct PiholeRow {
        public static let statusActive = "Active"
        public static let statusDisabled = "Disabled"
        public static let statusUnknown = "Unknown"
    }
    
    // MARK: - Statistics
    public static let totalQueries = "Total Queries"
    public static let percentBlocked = "Percent Blocked"
    public static let domainsOnList = "Domains on List"
    public static let queriesBlocked = "Queries Blocked"
    
    // MARK: - Pi-hole Setup
    public static let piholeSetupTitle = "Pi-hole Setup"
    public static let piholeSetupHostPlaceholder = "Host"
    public static let piholeSetupPortPlaceholder = "Port (80)"
    public static let piholeSetupDisplayName = "Display Name (Optional)"
    public static let piholeSetupTokenPlaceholder = "Token (Optional)"
    public static let piholeSetupEnablePiMonitor = "Enable Pi Monitor"
    public static let piholeTokenFooterSection = "Token is required for some functionalities like disable/enable your pi-hole.\\n\\nYou can find the API Token on /etc/pihole/setupVars.conf under WEBPASSWORD or you can open the web UI and go to Settings -> API -> Show API Token"
    public static let piholeTokenFooterV6Section = "For version 6.x, you can use your actual password for authenticating"
    
    // MARK: - Pi Monitor
    public static let piMonitorSetupPortPlaceholder = "Port (8088)"
    public static let piMonitorSetupAlertTitle = "Pi Monitor"
    public static let piMonitorSetupAlertOKButton = "OK"
    public static let piMonitorSetupAlertLearnMoreButton = "Learn More"
    public static let piMonitorExplanation = "Pi Monitor is a service that helps you to monitor your Raspberry Pi by showing you information like temperature, memory usage and more!\\n\\nIn order to use it you'll need to install it in your Raspberry Pi."
    
    // MARK: - Navigation
    public static let piholesNavigationTitle = "Pi-holes"
    public static let settingsNavigationTitle = "Settings"
    public static let allPiholesTitle = "All Pi-holes"
    public static let qrCodeScannerTitle = "Scanner"
    
    // MARK: - Settings Sections
    public struct Settings {
        // Section Headers
        public struct Sections {
            public static let interface = "Interface"
            public static let enableDisable = "Enable / Disable"
            public static let piMonitor = "Pi Monitor"
            public static let about = "About"
            public static let pihole = "Pi-hole"
            public static let startup = "Startup"
        }
        
        // Settings Options
        public static let displayAsListToggle = "Display Pi-hole stats as list"
        public static let displayAllPiholesToggle = "Display all Pi-holes in a single card"
        public static let alwaysDisablePermanentlyToggle = "Always disable Pi-hole permanently"
        public static let temperatureScaleLabel = "Temperature Scale"
        public static let startAtLoginToggle = "Start Pi Stats when macOS begins"
        public static let versionLabel = "Version"
        public static let sourceCodeLink = "Pi Stats source code"
        public static let macOSLink = "Pi Stats for macOS"
        public static let sourceCodeURL = "https://github.com/Bunn/PiStats"
        public static let macOSURL = "https://github.com/Bunn/PiStats"
        
        // Legacy properties for backward compatibility
        public static let sectionInterface = Sections.interface
        public static let sectionEnableDisable = Sections.enableDisable
        public static let sectionPiMonitor = Sections.piMonitor
        public static let about = Sections.about
        public static let displayAsList = displayAsListToggle
        public static let alwaysDisablePermanently = alwaysDisablePermanentlyToggle
        public static let displayAllPiholesInSingleCard = displayAllPiholesToggle
        public static let version = versionLabel
        public static let piStatsSourceCode = sourceCodeLink
        public static let piStatsForMacOS = macOSLink
        public static let leaveReview = "Write a review on the App Store"
        public static let customizeDisableTimes = "Customize disable times"
        public static let piMonitorTemperature = temperatureScaleLabel
        public static let protocolHTTP = "HTTP"
        public static let protocolHTTPS = "HTTPS"
        
        // Temperature
        public struct TemperatureScale {
            public static let celsius = "°C"
            public static let fahrenheit = "°F"
        }
        
        // Legacy temperature properties
        public static let temperatureScaleCelsius = TemperatureScale.celsius
        public static let temperatureScaleFahrenheit = TemperatureScale.fahrenheit
    }
    
    // MARK: - Platform-Specific Text
    #if os(macOS)
    public struct MainView {
        public static let noPiholesTitle = "No Pi-holes Configured"
        public static let getStartedMessage = "Get started by adding your first Pi-hole:"
        public static let step1 = "1. Make sure your Pi-hole is running"
        public static let step2 = "2. Note your Pi-hole's IP address"
        public static let step3 = "3. Get your API token or password from Pi-hole settings"
        public static let step4 = "4. Click the button below to add it"
        public static let addFirstPiholeButton = "Add Your First Pi-hole"
        public static let addPiholeButton = "Add Pi-hole"
        public static let settingsButton = "Settings"
        public static let aboutButton = "About"
        public static let deleteButton = "Delete"
        public static let editTooltip = "Edit Pi-hole settings"
    }
    
    public struct MenuBar {
        public static let appName = "Pi Stats"
        public static let noPiholesConfigured = "Pi Stats - No Pi-holes configured"
        public static let allEnabled = "Pi Stats - All %d Pi-holes are enabled"
        public static let allDisabled = "Pi Stats - All %d Pi-holes are disabled"
        public static let mixedStatus = "Pi Stats - %d enabled, %d disabled"
        public static let withErrors = "Pi Stats - %d of %d Pi-holes have errors"
    }
    
    public struct Popover {
        public static let manageButton = "Manage"
        public static let quitButton = "Quit Pi Stats"
        public static let noPiholesMessage = "No Pi-holes configured or loading..."
        public static let noPiholesTitle = "No Pi-holes Configured"
        public static let noPiholesInstructions = "Click 'Manage' below to add your first Pi-hole"
        public static let allPiholesTitle = "All Pi-holes"
        public static let dataSection = "Data"
        public static let deviceSection = "Device"
        public static let disableOptionsTitle = "Disable Pi-hole"
        public static let disablePermanently = "Permanently"
        public static let cancelButton = "Cancel"
    }
    
    public struct Commands {
        public static let addPiholeMenu = "Add Pi-hole…"
        public static let showPiStatsMenu = "Show Pi Stats"
    }
    
    public struct Setup {
        public static let addPiholeTitle = "Add Pi-hole"
        public static let editPiholeTitle = "Edit Pi-hole"
        public static let piholeConfigurationSection = "Pi-hole Configuration"
        public static let piMonitorOptionalSection = "Pi Monitor (Optional)"
        public static let dangerZoneSection = "Danger Zone"
        public static let hostLabel = "Host"
        public static let hostPlaceholder = "192.168.1.100 or pi.local"
        public static let displayNameLabel = "Display Name"
        public static let displayNamePlaceholder = "Optional friendly name"
        public static let portLabel = "Port"
        public static let portPlaceholder = "80"
        public static let apiTokenLabel = "API Token"
        public static let passwordLabel = "Password"
        public static let apiTokenPlaceholder = "Optional - enables additional features"
        public static let passwordPlaceholder = "Required for Pi-hole v6"
        public static let apiTokenHelp = "Find in /etc/pihole/setupVars.conf under WEBPASSWORD or in Web UI → Settings → API"
        public static let passwordHelp = "Use your Pi-hole web interface password"
        public static let enablePiMonitorLabel = "Enable Pi Monitor"
        public static let piMonitorPortPlaceholder = "8088"
        public static let whatsThisButton = "What's this?"
        public static let deletePiholeLabel = "Delete Pi-hole"
        public static let deletePiholeDescription = "This will permanently remove this Pi-hole from Pi Stats."
        public static let piMonitorInfoTitle = "Pi Monitor"
        public static let piMonitorInfoMessage = "Pi Monitor is a service that helps you monitor your Raspberry Pi by showing information like temperature, memory usage and more! To use it, you'll need to install Pi Monitor on your Raspberry Pi."
        public static let learnMoreButton = "Learn More"
        public static let okButton = "OK"
        public static let piMonitorURL = "https://github.com/Bunn/pi_monitor"
    }
    
    public struct About {
        public static let appName = "Pi Stats"
        public static let tagline = "Monitor your Pi-hole instances"
        public static let versionFormat = "Version %@ (%@)"
        public static let copyright = "© 2025 Fernando Bunn"
        public static let websiteButton = "Website"
        public static let supportButton = "Support"
        public static let closeButton = "Close"
        public static let websiteURL = "https://github.com/bunn/PiStats"
        public static let supportURL = "https://github.com/bunn/PiStats/issues"
        public static let sourceCodeURL = "https://github.com/Bunn/PiStats"
        public static let macOSURL = "https://github.com/Bunn/PiStats"
    }
    #else
    public struct MainView {
        public static let addFirstPiholeCaption = "Tap here to add your first pi-hole"
    }
    #endif
    
    // MARK: - Disable Options
    public static let disablePiholeOptionsTitle = "Disable Pi-hole"
    public static let disablePiholeOptionsPermanently = "Permanently"
    
    // MARK: - Custom Disable Times
    public struct CustomizeDisabletime {
        public static let emptyListMessage = "Tap here to add a custom disable time"
        public static let title = "Disable Time"
    }
    
    // MARK: - Widget
    public struct Widget {
        public static let piholeNotEnabledOn = "Pi Monitor is not enabled on"
    }
    
    // MARK: - Error Messages
    public struct Error {
        public static let invalidAPIToken = "Invalid API Token"
        public static let invalidResponse = "Invalid Response"
        public static let invalidURL = "Invalid URL"
        public static let decodeResponseError = "Can't decode response"
        public static let noAPITokenProvided = "No API Token Provided"
        public static let sessionError = "Session Error"
        public static let cantAddNewItem = "Can't add new item"
    }
}

// MARK: - Layout Constants
public struct LayoutConstants {
    // MARK: - Common Geometry
    public static let defaultCornerRadius: CGFloat = 20.0
    public static let defaultPadding: CGFloat = 10.0
    public static let shadowRadius: CGFloat = 0
    public static let addPiholeButtonHeight: CGFloat = 56.0
    public static let widgetDefaultPadding: CGFloat = 16.0
    
    // MARK: - Platform-Specific Layout
    #if os(macOS)
    public struct MainView {
        public static let defaultSpacing: CGFloat = 0
        public static let emptyStateSpacing: CGFloat = 20
        public static let emptyStateIconSize: CGFloat = 64
        public static let setupStepsSpacing: CGFloat = 8
        public static let setupStepsItemSpacing: CGFloat = 4
        public static let rowVerticalPadding: CGFloat = 4
        public static let rowItemSpacing: CGFloat = 12
        public static let rowInternalSpacing: CGFloat = 6
    }
    
    public struct Settings {
        public static let minWidth: CGFloat = 520
        public static let minHeight: CGFloat = 420
        public static let temperaturePickerMaxWidth: CGFloat = 220
    }
    
    public struct About {
        public static let contentPadding: CGFloat = 40
        public static let mainSpacing: CGFloat = 20
        public static let titleSpacing: CGFloat = 8
        public static let footerSpacing: CGFloat = 12
        public static let linkSpacing: CGFloat = 16
        public static let iconSize: CGFloat = 64
    }
    
    public struct App {
        public static let windowMinWidth: CGFloat = 300
        public static let windowMaxWidth: CGFloat = 470
        public static let windowMinHeight: CGFloat = 350
        public static let windowMaxHeight: CGFloat = 900
        public static let menuBarExtraMinWidth: CGFloat = 320
    }
    #endif
}

// MARK: - App Colors
public struct AppColors {
    public static let background = Color("BackgroundColor")
    public static let cardColor = Color("CardColor")
    public static let cardColorGradientTop = Color("CardColorGradientTop")
    public static let cardColorGradientBottom = Color("CardColorGradientBottom")
    public static let domainsOnBlocklist = Color("DomainsOnBlockList")
    public static let totalQueries = Color("TotalQueries")
    public static let queriesBlocked = Color("QueriesBlocked")
    public static let percentBlocked = Color("PercentBlocked")
    public static let statusOffline = Color("StatusOffline")
    public static let statusOnline = Color("StatusOnline")
    public static let statusWarning = Color("StatusWarning")
    public static let errorMessage = Color("StatusOffline")
    public static let piMonitorWidgetBackground = Color("PiMonitorWidgetBackground")
}

// MARK: - App Identifiers
public struct AppIdentifiers {
    public static let mainWindowSceneId = "main"
}

// MARK: - Preferences Constants
public struct PreferencesConstants {
    public     struct Keys {
        public static let displayStatsAsList = "displayStatsAsList"
        public static let displayAllPiholes = "displayAllPiholes"
        public static let disablePermanently = "disablePermanently"
        public static let temperatureScale = "temperatureScale"
        public static let startAtLogin = "startAtLogin"
    }
    
    public struct Defaults {
        public static let disablePermanentlyDefault = true
        public static let celsiusTemperatureValue = 0
        public static let fahrenheitTemperatureValue = 1
    }
}
