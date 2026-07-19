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
    
    // Top Domains
    public static let topDomains = "chart.bar"

    // Top Clients
    public static let topClients = "person.2"

    // Query History
    public static let queryHistory = "chart.xyaxis.line"

    // Detail / Actions
    public static let moreDetails = "list.bullet.rectangle"
    public static let healthUpdate = "arrow.down.circle.fill"
    public static let healthUpToDate = "checkmark.circle.fill"

    // Domains
    public static let manageDomains = "globe"
    public static let allowDomain = "checkmark.shield"
    public static let blockDomain = "hand.raised"

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
    public static let settingsLiveActivity = "timer"
    public static let addNewCustomDisableTime = "plus"
    
    // System Metrics
    public static let metricTemperature = "thermometer"
    public static let metricUptime = "power"
    public static let metricLoadAverage = "cpu"
    public static let metricMemoryUsage = "memorychip"
    public static let settingsTemperature = "thermometer"
    
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
    public static let saveButton = String(localized: "Save")
    public static let cancelButton = String(localized: "Cancel")
    public static let deleteButton = String(localized: "Delete")
    public static let enableButton = String(localized: "Enable")
    public static let disableButton = String(localized: "Disable")
    public static let closeButton = String(localized: "Close")
    public static let doneButton = String(localized: "Done")
    public static let settingsButton = String(localized: "Settings")

    // MARK: - Pi-hole Status
    public static let statusEnabled = String(localized: "Active")
    public static let statusDisabled = String(localized: "Offline")
    public static let statusNeedsAttention = String(localized: "Needs Attention")
    public static let statusEnabledAndDisabled = String(localized: "Partially Active")
    public static let statusUnknown = String(localized: "Unknown")

    // MARK: - Pi-hole Row Status Text
    public struct PiholeRow {
        public static let statusActive = String(localized: "Active")
        public static let statusDisabled = String(localized: "Disabled")
        public static let statusUnknown = String(localized: "Unknown")
    }

    // MARK: - Statistics
    public static let totalQueries = String(localized: "Total Queries")
    public static let percentBlocked = String(localized: "Percent Blocked")
    public static let domainsOnList = String(localized: "Domains on List")
    public static let queriesBlocked = String(localized: "Queries Blocked")

    // MARK: - Detail Sections
    public static let moreDetails = String(localized: "More Details")
    public static let queryHistory = String(localized: "Last 24 Hours")
    public static let topDomainsSection = String(localized: "Top Domains")
    public static let topClientsSection = String(localized: "Top Clients")
    public static let queryTypesSection = String(localized: "Query Types")
    public static let upstreamsSection = String(localized: "Upstream Servers")
    public static let deviceSection = String(localized: "Device")
    public static let blocklistSection = String(localized: "Blocklist")
    public static let blockServicesSection = String(localized: "Block Services")
    public static let healthSection = String(localized: "Health")
    public static let healthUpdateAvailable = String(localized: "Update available")
    public static let healthUpToDate = String(localized: "Up to date")
    public static let clearMessages = String(localized: "Clear Messages")
    public static let clearMessagesConfirmTitle = String(localized: "Clear Messages?")
    public static let clearMessagesConfirmMessage = String(localized: "This permanently removes all diagnosis messages from this Pi-hole.")
    public static let queryLogTitle = String(localized: "Query Log")
    public static let queryLogSearchPrompt = String(localized: "Search domain or client")
    public static let queryLogCardTitle = String(localized: "Query Log")
    public static let queryLogCardSubtitle = String(localized: "Browse and search recent queries")
    public static let blocklistsCardTitle = String(localized: "Blocklists")
    public static let blocklistsCardSubtitle = String(localized: "Manage your block & allow lists")

    // MARK: - Domain Management
    public static let domainsCardTitle = String(localized: "Domains")
    public static let domainsCardSubtitle = String(localized: "Manage allow & deny lists")
    public static let domainsTitle = String(localized: "Domains")
    public static let addDomainTitle = String(localized: "Add Domain")
    public static let allowDomainAction = String(localized: "Allow")
    public static let blockDomainAction = String(localized: "Block")
    public static let domainFieldPlaceholder = String(localized: "Domain or regex")
    public static let commentFieldPlaceholder = String(localized: "Comment (optional)")
    public static func domainAddedToAllow(_ domain: String) -> String { String(localized: "Allowed \(domain)") }
    public static func domainAddedToBlock(_ domain: String) -> String { String(localized: "Blocked \(domain)") }

    // MARK: - Pi-hole Setup
    public static let piholeSetupTitle = String(localized: "Pi-hole Setup")
    public static let piholeSetupHostPlaceholder = String(localized: "Host")
    public static let piholeSetupPortPlaceholder = String(localized: "Port (80)")
    public static let piholeSetupDisplayName = String(localized: "Display Name (Optional)")
    public static let piholeSetupTokenPlaceholder = String(localized: "Token (Optional)")
    public static let piholeSetupShowTopDomains = String(localized: "Show Top Domains")
    public static let piholeSetupShowTopClients = String(localized: "Show Top Clients")
    public static let piholeSetupShowHistory = String(localized: "Show History Chart")
    public static let showSystemMetrics = String(localized: "Show System Metrics")
    public static let systemMetricsV6Description = String(localized: "Shows temperature, uptime, load, and memory reported by the Pi-hole API.")
    public static let systemMetricsV5Description = String(localized: "Pi-hole 5 requires Pi Monitor to provide system metrics.")
    public static let legacySystemMetricsSetupLink = String(localized: "Pi Monitor setup")
    public static let legacySystemMetricsPortPlaceholder = String(localized: "Pi Monitor port (8088)")
    public static let legacySystemMetricsSetupURL = "https://github.com/Bunn/pi_monitor"
    public static let piholeTokenFooterSection = String(localized: "Token is required for some functionalities like disable/enable your pi-hole.\\n\\nYou can find the API Token on /etc/pihole/setupVars.conf under WEBPASSWORD or you can open the web UI and go to Settings -> API -> Show API Token")
    public static let piholeTokenFooterV6Section = String(localized: "For version 6.x, you can use your actual password for authenticating")

    // MARK: - Navigation
    public static let piholesNavigationTitle = "Pi-holes"
    public static let settingsNavigationTitle = String(localized: "Settings")
    public static let allPiholesTitle = String(localized: "All Pi-holes")
    public static let qrCodeScannerTitle = String(localized: "Scanner")
    
    // MARK: - Settings Sections
    public struct Settings {
        // Section Headers
        public struct Sections {
            public static let interface = String(localized: "Interface")
            public static let enableDisable = String(localized: "Enable / Disable")
            public static let systemMetrics = String(localized: "System Metrics")
            public static let about = String(localized: "About")
            public static let pihole = "Pi-hole"
            public static let startup = String(localized: "Startup")
        }

        // Settings Options
        public static let displayAsListToggle = String(localized: "Display Pi-hole stats as list")
        public static let displayAllPiholesToggle = String(localized: "Display all Pi-holes in a single card")
        public static let alwaysDisablePermanentlyToggle = String(localized: "Always disable Pi-hole permanently")
        public static let alwaysDisablePermanentlyDescription = String(localized: "When on, disabling a Pi-hole turns it off indefinitely instead of for a set time.")
        public static let liveActivityToggle = String(localized: "Show Live Activity")
        public static let liveActivityDescription = String(localized: "Shows a Lock Screen and Dynamic Island countdown when you pause blocking for a set time.")
        public static let temperatureScaleLabel = String(localized: "Temperature Scale")
        public static let startAtLoginToggle = String(localized: "Start Pi Stats when macOS begins")
        public static let versionLabel = String(localized: "Version")
        public static let sourceCodeLink = String(localized: "Pi Stats source code")
        public static let macOSLink = String(localized: "Pi Stats for macOS")
        public static let sourceCodeURL = "https://github.com/Bunn/PiStats"
        public static let macOSURL = "https://github.com/Bunn/PiStats"

        // Legacy properties for backward compatibility
        public static let sectionInterface = Sections.interface
        public static let sectionEnableDisable = Sections.enableDisable
        public static let about = Sections.about
        public static let displayAsList = displayAsListToggle
        public static let alwaysDisablePermanently = alwaysDisablePermanentlyToggle
        public static let displayAllPiholesInSingleCard = displayAllPiholesToggle
        public static let version = versionLabel
        public static let piStatsSourceCode = sourceCodeLink
        public static let piStatsForMacOS = macOSLink
        public static let leaveReview = String(localized: "Write a review on the App Store")
        public static let customizeDisableTimes = String(localized: "Customize disable times")
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
        public static let noPiholesTitle = String(localized: "No Pi-holes Configured")
        public static let getStartedMessage = String(localized: "Get started by adding your first Pi-hole:")
        public static let step1 = String(localized: "1. Make sure your Pi-hole is running")
        public static let step2 = String(localized: "2. Note your Pi-hole's IP address")
        public static let step3 = String(localized: "3. Get your API token or password from Pi-hole settings")
        public static let step4 = String(localized: "4. Click the button below to add it")
        public static let addFirstPiholeButton = String(localized: "Add Your First Pi-hole")
        public static let addPiholeButton = String(localized: "Add Pi-hole")
        public static let settingsButton = String(localized: "Settings")
        public static let aboutButton = String(localized: "About")
        public static let deleteButton = String(localized: "Delete")
        public static let editTooltip = String(localized: "Edit Pi-hole settings")
    }

    public struct MenuBar {
        public static let appName = "Pi Stats"
        public static let noPiholesConfigured = String(localized: "Pi Stats - No Pi-holes configured")
        public static let allEnabled = String(localized: "Pi Stats - All %d Pi-holes are enabled")
        public static let allDisabled = String(localized: "Pi Stats - All %d Pi-holes are disabled")
        public static let mixedStatus = String(localized: "Pi Stats - %d enabled, %d disabled")
        public static let withErrors = String(localized: "Pi Stats - %d of %d Pi-holes have errors")
    }

    public struct Popover {
        public static let manageButton = String(localized: "Manage")
        public static let quitButton = String(localized: "Quit Pi Stats")
        public static let noPiholesMessage = String(localized: "No Pi-holes configured or loading...")
        public static let noPiholesTitle = String(localized: "No Pi-holes Configured")
        public static let noPiholesInstructions = String(localized: "Click 'Manage' below to add your first Pi-hole")
        public static let allPiholesTitle = String(localized: "All Pi-holes")
        public static let dataSection = String(localized: "Data")
        public static let deviceSection = String(localized: "Device")
        public static let disableOptionsTitle = String(localized: "Disable Pi-hole")
        public static let disablePermanently = String(localized: "Permanently")
        public static let cancelButton = String(localized: "Cancel")
    }

    public struct Commands {
        public static let addPiholeMenu = String(localized: "Add Pi-hole…")
        public static let showPiStatsMenu = String(localized: "Show Pi Stats")
    }

    public struct Setup {
        public static let addPiholeTitle = String(localized: "Add Pi-hole")
        public static let editPiholeTitle = String(localized: "Edit Pi-hole")
        public static let piholeConfigurationSection = String(localized: "Pi-hole Configuration")
        public static let systemMetricsSection = String(localized: "System Metrics")
        public static let dangerZoneSection = String(localized: "Danger Zone")
        public static let hostLabel = String(localized: "Host")
        public static let hostPlaceholder = String(localized: "192.168.1.100 or pi.local")
        public static let displayNameLabel = String(localized: "Display Name")
        public static let displayNamePlaceholder = String(localized: "Optional friendly name")
        public static let portLabel = String(localized: "Port")
        public static let portPlaceholder = "80"
        public static let apiTokenLabel = String(localized: "API Token")
        public static let passwordLabel = String(localized: "Password")
        public static let apiTokenPlaceholder = String(localized: "Optional - enables additional features")
        public static let passwordPlaceholder = String(localized: "Required for Pi-hole v6")
        public static let apiTokenHelp = String(localized: "Find in /etc/pihole/setupVars.conf under WEBPASSWORD or in Web UI → Settings → API")
        public static let passwordHelp = String(localized: "Use your Pi-hole web interface password")
        public static let showTopDomainsLabel = String(localized: "Show Top Domains")
        public static let showTopClientsLabel = String(localized: "Show Top Clients")
        public static let showHistoryLabel = String(localized: "Show History Chart")
        public static let legacySystemMetricsPortPlaceholder = "8088"
        public static let deletePiholeLabel = String(localized: "Delete Pi-hole")
        public static let deletePiholeDescription = String(localized: "This will permanently remove this Pi-hole from Pi Stats.")
    }

    public struct About {
        public static let appName = "Pi Stats"
        public static let tagline = String(localized: "Monitor your Pi-hole instances")
        public static let versionFormat = String(localized: "Version %@ (%@)")
        public static let copyright = "© 2025 Fernando Bunn"
        public static let websiteButton = String(localized: "Website")
        public static let developerWebsiteButton = String(localized: "Developer Website")
        public static let supportButton = String(localized: "Support")
        public static let closeButton = String(localized: "Close")
        public static let websiteURL = "https://pistats.app/"
        public static let developerWebsiteURL = "https://bunn.dev"
        public static let supportURL = "https://github.com/bunn/PiStats/issues"
        public static let sourceCodeURL = "https://github.com/Bunn/PiStats"
        public static let macOSURL = "https://github.com/Bunn/PiStats"
    }
    #else
    public struct MainView {
        public static let addFirstPiholeCaption = String(localized: "Tap here to add your first pi-hole")
    }
    #endif

    // MARK: - Disable Options
    public static let disablePiholeOptionsTitle = String(localized: "Disable Pi-hole")
    public static let disablePiholeOptionsPermanently = String(localized: "Permanently")

    // MARK: - Custom Disable Times
    public struct CustomizeDisabletime {
        public static let emptyListMessage = String(localized: "Tap here to add a custom disable time")
        public static let title = String(localized: "Disable Time")
    }

    // MARK: - Error Messages
    public struct Error {
        public static let invalidAPIToken = String(localized: "Invalid API Token")
        public static let invalidResponse = String(localized: "Invalid Response")
        public static let invalidURL = String(localized: "Invalid URL")
        public static let decodeResponseError = String(localized: "Can't decode response")
        public static let noAPITokenProvided = String(localized: "No API Token Provided")
        public static let sessionError = String(localized: "Session Error")
        public static let cantAddNewItem = String(localized: "Can't add new item")
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
    public static let detailWindowSceneId = "pihole-detail"
}

// MARK: - Preferences Constants
public struct PreferencesConstants {
    public     struct Keys {
        public static let displayStatsAsList = "displayStatsAsList"
        public static let displayAllPiholes = "displayAllPiholes"
        public static let disablePermanently = "disablePermanently"
        public static let temperatureScale = "temperatureScale"
        public static let showTopDomains = "showTopDomains"
        public static let startAtLogin = "startAtLogin"
    }
    
    public struct Defaults {
        public static let disablePermanentlyDefault = true
        public static let celsiusTemperatureValue = 0
        public static let fahrenheitTemperatureValue = 1
    }
}
