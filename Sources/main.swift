import SwiftUI
import AppKit
import Foundation
import ApplicationServices

// MARK: - Version Info

let AEROSWITCH_VERSION = "1.0.0"

// MARK: - CLI Arguments

enum AppMode {
    case background
    case activate
    case help
    case version
}

func parseArguments() -> AppMode {
    let args = CommandLine.arguments
    
    if args.contains("--version") || args.contains("-v") {
        return .version
    } else if args.contains("--help") || args.contains("-h") {
        return .help
    } else if args.contains("--background") {
        return .background
    } else if args.contains("--activate") {
        return .activate
    } else {
        // Default behavior: try to activate existing, or start background if none exists
        return checkForExistingInstance() ? .activate : .background
    }
}

func printVersion() {
    print("""
    AeroSwitch v\(AEROSWITCH_VERSION)
    Copyright (C) 2025 Ilmars Janis Bluzmanis
    
    This is free software; see the source for copying conditions.
    There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    """)
}

func printHelp() {
    print("""
    AeroSwitch v\(AEROSWITCH_VERSION) - Window switcher for AeroSpace
    
    Usage:
        aeroswitch [OPTIONS]
    
    Options:
        --background    Start as background helper process
        --activate      Activate existing helper process
        --version, -v   Show version information
        --help, -h      Show this help message
    
    Keyboard shortcuts when window switcher is open:
        Enter           Activate selected window (switch to its workspace)
        Alt+Enter       Summon selected window (move to current workspace)
        ↑/↓ arrows      Navigate window list
        Esc             Close window switcher
    
    Default behavior:
        If no flags are provided, will activate existing instance or start background process.
    """)
}

// MARK: - Inter-process communication

let ACTIVATION_PIPE = "/tmp/aeroswitch-activate"

func createActivationPipe() {
    if !FileManager.default.fileExists(atPath: ACTIVATION_PIPE) {
        FileManager.default.createFile(atPath: ACTIVATION_PIPE, contents: nil)
    }
}

func sendActivationSignal() -> Bool {
    do {
        let data = "activate\n".data(using: .utf8)!
        try data.write(to: URL(fileURLWithPath: ACTIVATION_PIPE))
        return true
    } catch {
        return false
    }
}

func checkForExistingInstance() -> Bool {
    // Check if activation pipe exists and is writable
    return FileManager.default.fileExists(atPath: ACTIVATION_PIPE) && 
           FileManager.default.isWritableFile(atPath: ACTIVATION_PIPE)
}

// MARK: - AeroSpace bridge

let AEROSPACE_PATHS = ["/opt/homebrew/bin/aerospace", "/usr/local/bin/aerospace", "/usr/bin/aerospace"]

func whichAeroSpace() -> String {
    for p in AEROSPACE_PATHS where FileManager.default.isExecutableFile(atPath: p) { return p }
    return "aerospace" // fallback to PATH
}

@discardableResult
func aero(_ args: [String]) throws -> String {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: whichAeroSpace())
    proc.arguments = args
    let out = Pipe(); proc.standardOutput = out
    let err = Pipe(); proc.standardError = err
    try proc.run()
    proc.waitUntilExit()
    if proc.terminationStatus != 0 {
        let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
        throw NSError(domain: "aerospace", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: msg])
    }
    return String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

struct WindowEntry: Identifiable, Hashable {
    let id: Int
    let workspace: String
    let monitor: String
    let app: String
    let title: String
    let icon: NSImage?
}

func getAppIcon(for appName: String) -> NSImage? {
    let workspace = NSWorkspace.shared
    
    // Try to find the app by name
    if let appURL = workspace.urlForApplication(withBundleIdentifier: appName) ??
                   workspace.urlForApplication(withBundleIdentifier: "com.apple.\(appName.lowercased())") ??
                   workspace.urlForApplication(withBundleIdentifier: "com.\(appName.lowercased())") {
        return workspace.icon(forFile: appURL.path)
    }
    
    // Try to find by display name
    let runningApps = workspace.runningApplications
    if let app = runningApps.first(where: { $0.localizedName?.lowercased() == appName.lowercased() }),
       let bundleURL = app.bundleURL {
        return workspace.icon(forFile: bundleURL.path)
    }
    
    // Fallback: try generic app icon
    return NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App")
}

@MainActor
func listWindows(vm: VM) async throws -> [WindowEntry] {
    let fmt = "%{window-id}%{tab}%{workspace}%{tab}%{monitor-id}%{tab}%{app-name}%{tab}%{window-title}%{newline}"
    let raw = try aero(["list-windows", "--all", "--format", fmt])
    
    // Get current window to exclude it from the list
    let currentWindowId = vm.currentWindowId
    
    return raw.split(separator: "\n").compactMap { line -> WindowEntry? in
        let parts = line.split(separator: "\t", maxSplits: 4, omittingEmptySubsequences: false)
        guard parts.count == 5, let id = Int(parts[0]) else { return nil }
        
        // Skip the currently focused window
        if let currentId = currentWindowId, id == currentId {
            return nil
        }
        
        let appName = String(parts[3])
        
        // Skip AeroSwitch windows
        if appName.lowercased() == "aeroswitch" {
            return nil
        }
        
        if let icon = vm.iconCache[appName] {
            return WindowEntry(id: id,
                               workspace: String(parts[1]),
                               monitor: String(parts[2]),
                               app: appName,
                               title: String(parts[4]),
                               icon: icon)
        }
        let icon = getAppIcon(for: appName)
        vm.iconCache[appName] = icon
        return WindowEntry(id: id,
                           workspace: String(parts[1]),
                           monitor: String(parts[2]),
                           app: appName,
                           title: String(parts[4]),
                           icon: icon)
    }
}

func focusedWorkspace() -> String? {
    (try? aero(["list-workspaces", "--focused", "--format", "%{workspace}"]))?.trimmingCharacters(in: .whitespacesAndNewlines)
}

func focusedWindow() -> Int? {
    guard let raw = try? aero(["list-windows", "--focused", "--format", "%{window-id}"]) else { return nil }
    return Int(raw.trimmingCharacters(in: .whitespacesAndNewlines))
}

func activateWindow(_ e: WindowEntry) throws {
    // Go to the window's workspace if needed, then focus the window
    if focusedWorkspace() != e.workspace {
        _ = try aero(["workspace", e.workspace])
    }
    _ = try aero(["focus", "--window-id", String(e.id)])
}

func summonWindow(_ e: WindowEntry) throws {
    // Get the current workspace
    guard let currentWorkspace = focusedWorkspace() else { return }
    
    // Skip if window is already in current workspace
    if e.workspace == currentWorkspace { 
        _ = try aero(["focus", "--window-id", String(e.id)])
        return 
    }
    
    // Move the window to current workspace and focus it automatically
    _ = try aero(["move-node-to-workspace", "--focus-follows-window", "--window-id", String(e.id), currentWorkspace])
}

// MARK: - View model

@MainActor final class VM: ObservableObject {
    @Published var query = ""
    @Published var all: [WindowEntry] = []
    @Published var filtered: [WindowEntry] = []
    @Published var selection: WindowEntry?
    @Published var error: String?
    @Published var isVisible = false
    private var activationTimer: Timer?
    private var axObserver: AXObserver?
    private var statusItem: NSStatusItem?
    private var keyEventMonitor: Any?
    fileprivate var currentWindowId: Int?
    fileprivate var previousWindowId: Int?
    fileprivate var iconCache: [String: NSImage] = [:]

    init(isBackgroundMode: Bool = true) {
        if isBackgroundMode {
            setupSystemTray()
            startActivationMonitoring()
            startFocusTracking()
        }
        Task {
            await reload()
        }
    }
    
    private func findAppIcon() -> String? {
        // Look for app icons in common locations relative to the executable
        let executablePath = Bundle.main.executablePath ?? ""
        let executableDir = (executablePath as NSString).deletingLastPathComponent
        let currentDir = FileManager.default.currentDirectoryPath
        
        let iconPaths = [
            // In current working directory (most likely for development)
            "\(currentDir)/Assets.xcassets/AppIcon.appiconset/32.png",
            "\(currentDir)/Assets.xcassets/AppIcon.appiconset/16.png",
            // Relative to executable
            "\(executableDir)/../Assets.xcassets/AppIcon.appiconset/32.png",
            "\(executableDir)/../Assets.xcassets/AppIcon.appiconset/16.png",
            "\(executableDir)/Assets.xcassets/AppIcon.appiconset/32.png",
            "\(executableDir)/Assets.xcassets/AppIcon.appiconset/16.png"
        ]
        
        for path in iconPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    private func processIconForTray(_ originalIcon: NSImage) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        
        // Clear the background to ensure transparency
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw the original icon, scaled to fit
        let drawRect = NSRect(origin: .zero, size: size)
        originalIcon.draw(in: drawRect, from: NSRect.zero, operation: .sourceOver, fraction: 1.0)
        
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func setupSystemTray() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Try to load custom app icon, fallback to SF Symbol
            if let iconPath = findAppIcon(),
               let customIcon = NSImage(contentsOfFile: iconPath) {
                // Process the image to ensure transparency and proper sizing
                let processedIcon = processIconForTray(customIcon)
                button.image = processedIcon
                button.image?.isTemplate = false
            } else if let image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "AeroSwitch") {
                button.image = image
                button.image?.isTemplate = true
            } else {
                // Fallback for older macOS versions
                button.title = "AS"
            }
        }
        
        let menu = NSMenu()
        
        let showItem = NSMenuItem(title: "Show Window Switcher", action: #selector(showWindowFromTray), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit AeroSwitch", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func showWindowFromTray() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowSwitcher"), object: nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func startActivationMonitoring() {
        createActivationPipe()
        activationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.checkForActivationSignal()
            }
        }
    }
    
    private func startFocusTracking() {
        // Initialize current window
        currentWindowId = focusedWindow()
        print("Initial window ID: \(currentWindowId ?? -1)")
        
        // Set up AXObserver for real-time focus tracking
        setupAXObserver()
    }
    
    private func setupAXObserver() {
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Create observer callback
        let callback: AXObserverCallback = { observer, element, notification, refcon in
            if let vm = unsafeBitCast(refcon, to: VM?.self) {
                // Handle immediately for fastest response
                if Thread.isMainThread {
                    vm.handleFocusChangeSync()
                } else {
                    DispatchQueue.main.sync {
                        vm.handleFocusChangeSync()
                    }
                }
            }
        }
        
        // Create observer
        let result = AXObserverCreate(getpid(), callback, &axObserver)
        guard result == .success, let observer = axObserver else {
            print("Failed to create AXObserver, falling back to polling")
            fallbackToPolling()
            return
        }
        
        // Add notification for focused window changes
        let addResult = AXObserverAddNotification(
            observer,
            systemWideElement,
            kAXFocusedWindowChangedNotification as CFString,
            unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        )
        
        if addResult == .success {
            // Add observer to run loop
            CFRunLoopAddSource(
                CFRunLoopGetCurrent(),
                AXObserverGetRunLoopSource(observer),
                .defaultMode
            )
            print("✅ AXObserver setup successful")
        } else {
            print("Failed to add AXObserver notification, falling back to polling")
            fallbackToPolling()
        }
    }
    
    private func fallbackToPolling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkFocusChange()
            }
        }
    }
    
    private func handleFocusChangeSync() {
        guard !isVisible else { return }
        
        let newCurrentId = focusedWindow()
        
        if let current = newCurrentId, current != self.currentWindowId {
            print("🎯 AX Focus change: \(self.currentWindowId ?? -1) -> \(current)")
            self.previousWindowId = self.currentWindowId
            self.currentWindowId = current
        }
    }
    
    private func checkForActivationSignal() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: ACTIVATION_PIPE)),
              let content = String(data: data, encoding: .utf8),
              content.contains("activate") else { return }
        
        // Clear the signal
        try? "".write(to: URL(fileURLWithPath: ACTIVATION_PIPE), atomically: true, encoding: .utf8)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("ShowSwitcher"), object: nil)
        }
    }
    
    func showWindow() async {
        print("=== Showing window ===")
        print("Current window ID: \(currentWindowId ?? -1)")
        print("Previous window ID: \(previousWindowId ?? -1)")
        
        await reload()
        query = ""
        isVisible = true
        
        print("Total windows after reload: \(all.count)")
        print("Filtered windows: \(filtered.count)")
        print("Window IDs in list: \(filtered.map { $0.id })")
        
        // Select previously active window if available, otherwise first item
        selectPreviouslyActiveWindow()
        
        // Start monitoring for arrow key and Alt+Enter events
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.isVisible {
                switch event.keyCode {
                case 126: // Up arrow
                    self.moveSelection(offset: -1)
                    return nil // Consume the event
                case 125: // Down arrow
                    self.moveSelection(offset: 1)
                    return nil // Consume the event
                case 36: // Return/Enter key
                    if event.modifierFlags.contains(.option) { // Alt+Enter
                        if let selection = self.selection {
                            self.confirmSelectionFor(entry: selection, useSummon: true)
                        }
                        return nil // Consume the event
                    }
                    return event // Let normal Enter pass through
                default:
                    return event // Let other events pass through
                }
            }
            return event
        }
    }
    
    func hideWindow() {
        isVisible = false
        
        // Stop monitoring key events
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("HideSwitcher"), object: nil)
        }
    }

    func reload() async {
        iconCache = [:]
        do {
            all = try await listWindows(vm: self)
            applyFilter()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func applyFilter() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            filtered = all
        } else {
            filtered = all
                .map { ($0, score($0, q)) }
                .filter { $0.1 < 1_000_000 }
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }
        }
        if let sel = selection, !filtered.contains(sel) {
            selectPreviouslyActiveWindow()
        } else if selection == nil {
            selectPreviouslyActiveWindow()
        }
    }

    // tiny scoring: prefer app prefix > app contains > title prefix > title contains
    func score(_ e: WindowEntry, _ q: String) -> Int {
        let a = e.app.lowercased(), t = e.title.lowercased()
        if a.hasPrefix(q) { return (q.count * 2) * 100 } // Prioritize prefix matches, more specific prefixes are better
        if t.hasPrefix(q) { return (q.count * 2) * 80 }
        if a.contains(q)  { return q.count * 50 }
        if t.contains(q)  { return q.count * 40 }
        return 1_000_000 // Return a large number for no match
    }

    func confirmSelection() {
        guard let s = selection else {
            DispatchQueue.main.async { self.hideWindow() }
            return
        }
        confirmSelectionFor(entry: s)
    }
    
    func confirmSelectionFor(entry: WindowEntry, useSummon: Bool = false) {
        // Execute aerospace commands on background thread
        Task {
            do {
                if useSummon {
                    try summonWindow(entry)
                } else {
                    try activateWindow(entry)
                }
                // Hide window after aerospace command completes
                await MainActor.run {
                    self.hideWindow()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func moveSelection(offset: Int) {
        guard !filtered.isEmpty else { return }
        let currentIndex = selection.flatMap { filtered.firstIndex(of: $0) } ?? 0
        let newIndex = (currentIndex + offset + filtered.count) % filtered.count
        selection = filtered[newIndex]
    }
    
    private func checkFocusChange() {
        // Don't track focus changes while switcher is visible
        guard !isVisible else { return }
        
        let newCurrentId = focusedWindow()
        
        if let current = newCurrentId, current != self.currentWindowId {
            print("📊 Polling focus change: \(self.currentWindowId ?? -1) -> \(current)")
            self.previousWindowId = self.currentWindowId
            self.currentWindowId = current
        }
    }
    
    private func selectPreviouslyActiveWindow() {
        // Try to find the previously active window in filtered list
        if let prevId = previousWindowId,
           let prevWindow = filtered.first(where: { $0.id == prevId }) {
            selection = prevWindow
            print("Selected previous window: \(prevId)")
        } else {
            // Fallback: select first available window (current window already filtered out)
            selection = filtered.first
            print("No previous window found, selected first: \(selection?.id ?? -1)")
        }
    }
}

// MARK: - Window helpers

struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow) -> Void
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let w = v.window { onResolve(w) }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - UI

struct Row: View {
    let e: WindowEntry
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let icon = e.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(e.app).font(.headline)
                    Spacer()
                    Text("ws:\(e.workspace)").font(.caption).opacity(0.7)
                }
                Text(e.title).lineLimit(1).font(.subheadline).opacity(0.9)
            }
        }.padding(.vertical, 6)
    }
}

struct ContentView: View {
    @ObservedObject var vm: VM
    @FocusState private var searchFocused: Bool
    @State private var listID = UUID()
    
    var body: some View {
        VStack(spacing: 10) {
            TextField("Search by app or title…", text: $vm.query)
                .textFieldStyle(.roundedBorder)
                .padding(.top, 6)
                .focused($searchFocused)
                .onChange(of: vm.query) { _ in vm.applyFilter() }
                .onSubmit { vm.confirmSelection() }

            if let err = vm.error {
                Text(err).foregroundStyle(.red).font(.caption)
            }

            List(selection: $vm.selection) {
                ForEach(vm.filtered, id: \.self) { e in
                    Row(e: e)
                        .tag(e)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.confirmSelectionFor(entry: e)
                        }
                }
            }
            .id(listID)
            .frame(width: 680, height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                DispatchQueue.main.async {
                    searchFocused = true
                }
            }
            .onAppear { 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    searchFocused = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSwitcher"))) { _ in
                // Reset list to force scroll position reset
                listID = UUID()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    searchFocused = true
                }
            }
            .overlay(
                vm.filtered.isEmpty ?
                    Text("No matches").opacity(0.6) : nil
            )
        }
        .padding(12)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
        .onExitCommand { vm.hideWindow() } // Esc to hide
    }
}

// NSVisualEffect in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        v.wantsLayer = true
        v.layer?.cornerRadius = 16
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - App

// MARK: - Custom Window

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    override func resignKey() {
        super.resignKey()
        // Post notification to hide the window when it loses focus
        NotificationCenter.default.post(name: NSNotification.Name("HideSwitcher"), object: nil)
    }
}

// MARK: - Menu Bar App

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var vm: VM?
    var switcherWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let mode = parseArguments()
        
        switch mode {
        case .version:
            printVersion()
            exit(0)
            
        case .help:
            printHelp()
            exit(0)
            
        case .activate:
            // Try to activate existing instance
            if sendActivationSignal() {
                exit(0)
            } else {
                print("No background instance found. Starting new background process...")
                startBackgroundMode()
            }
            
        case .background:
            // Start as background process
            startBackgroundMode()
        }
    }
    
    private func startBackgroundMode() {
        NSApp.setActivationPolicy(.accessory)
        vm = VM(isBackgroundMode: true)
        
        // Listen for show window requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSwitcherWindow),
            name: NSNotification.Name("ShowSwitcher"),
            object: nil
        )
    }
    
    @objc func showSwitcherWindow() {
        guard let vm = vm else { return }
        
        if switcherWindow == nil {
            createSwitcherWindow(vm: vm)
        }
        
        Task {
            await vm.showWindow()
        }
        switcherWindow?.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure window becomes first responder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.switcherWindow?.makeFirstResponder(self.switcherWindow?.contentView)
        }
    }
    
    private func createSwitcherWindow(vm: VM) {
        let contentView = ContentView(vm: vm)
        let hostingView = NSHostingView(rootView: contentView)
        
        switcherWindow = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 420),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        switcherWindow?.contentView = hostingView
        switcherWindow?.level = .floating
        switcherWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        switcherWindow?.acceptsMouseMovedEvents = true
        switcherWindow?.center()
        
        // Make window background transparent and add rounded corners
        switcherWindow?.backgroundColor = NSColor.clear
        switcherWindow?.isOpaque = false
        switcherWindow?.hasShadow = true
        switcherWindow?.alphaValue = 0.98
        if let contentView = switcherWindow?.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 16
            contentView.layer?.masksToBounds = true
        }
        
        // Listen for hide requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideSwitcherWindow),
            name: NSNotification.Name("HideSwitcher"),
            object: nil
        )
    }
    
    @objc func hideSwitcherWindow() {
        guard let window = switcherWindow else { return }
        
        window.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        
        // Update VM state without triggering another notification
        vm?.isVisible = false
    }
}

@main
struct SwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - all UI is handled by AppDelegate
        Settings {
            EmptyView()
        }
    }
}

