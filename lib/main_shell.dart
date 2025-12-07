import 'dart:async';
import 'package:flutter/material.dart';
import 'models/target.dart';
import 'pages/connection_page.dart';
import 'pages/functional_pages.dart';
import 'pages/settings_page.dart';
import 'services/log_service.dart';
import 'widgets/log_panel.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const MainShell({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  Target? _connectedTarget;
  bool _isLogPanelVisible = false;
  LogEntry? _lastLogEntry;
  StreamSubscription<LogEntry>? _logSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to log updates
    _logSubscription = LogService().logStream.listen((entry) {
      setState(() {
        _lastLogEntry = entry;
      });
    });

    // Add initial log message
    LogService().info('Application started');
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }

  // --- Connection Logic ---
  void _handleConnection(Target target) {
    setState(() {
      _connectedTarget = target;
      _selectedIndex = 1; // Auto-jump to Dashboard on connect
    });
  }

  void _handleDisconnect() {
    setState(() {
      _connectedTarget = null;
      _selectedIndex = 0; // Return to Connect page
    });
  }

  // --- Navigation Logic ---
  void _onDestinationSelected(int index) {
    // Rule: You cannot go to tabs 1, or 2 unless connected
    if (_connectedTarget == null && index >= 1 && index <= 2) {
      LogService().warning("Please connect to an ECU to access this page.");
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define pages
    final List<Widget> pages = [
      ConnectionPage(onEcuConnected: _handleConnection),
      TargetInfoPage(target: _connectedTarget),
      FlashWizardPage(target: _connectedTarget),
      // Settings Page (full-screen like other pages)
      SettingsPage(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme),
    ];

    // Define visual state for tabs
    final bool isLocked = _connectedTarget == null;
    final brightness = Theme.of(context).brightness;
    final Color disabledColor = Theme.of(context).disabledColor.withOpacity(brightness == Brightness.dark ? 0.3 : 0.6);
    final Color sidebarBg = Theme.of(context).cardColor;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // --- SIDEBAR ---
                SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Expanded(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _onDestinationSelected,
                          backgroundColor: sidebarBg,

                          // Ensure text is always shown
                          labelType: NavigationRailLabelType.all,

                          // Define base styles
                          selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
                          selectedLabelTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          unselectedLabelTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11),

                          destinations: [
                            // Tab 0: Connect (Always Active)
                            NavigationRailDestination(
                              icon: Icon(Icons.cable),
                              label: Text('Connect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),

                            // Tab 1: Target Info (Conditional)
                            NavigationRailDestination(
                              icon: Icon(Icons.info_outline, color: isLocked ? disabledColor : null),
                              label: Text(
                                'Target Info',
                                style: TextStyle(color: isLocked ? disabledColor : null, fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Tab 2: Flash (Conditional)
                            NavigationRailDestination(
                              icon: Icon(Icons.system_update_alt, color: isLocked ? disabledColor : null),
                              label: Text(
                                'Flash',
                                style: TextStyle(color: isLocked ? disabledColor : null, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),

                            // Tab 3: Settings
                            const NavigationRailDestination(
                              icon: Icon(Icons.settings),
                              label: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(width: 1, thickness: 1),

                // --- MAIN CONTENT + LOG PANEL ---
                Expanded(
                  child: Column(
                    children: [
                      // Main page content
                      Expanded(
                        child: Stack(children: [Positioned.fill(child: pages[_selectedIndex])]),
                      ),
                      // Log panel (hidden on Settings page, index 3)
                      if (_isLogPanelVisible && _selectedIndex != 3) LogPanel(onClose: () => setState(() => _isLogPanelVisible = false)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 3. BOTTOM STATUS BAR ---
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final profile = _connectedTarget?.profile;
    bool isConnected = _connectedTarget != null;
    return Container(
      height: 28,
      color: isConnected ? const Color(0xFF007ACC) : const Color(0xFF333333), // Blue if connected, Grey if not
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(isConnected ? Icons.link : Icons.link_off, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            isConnected ? "CONNECTED: ${profile?.name ?? 'Unknown'} (0x${profile?.txId.toRadixString(16).toUpperCase() ?? '???'})" : "NO CONNECTION",
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          // Last log message
          if (_lastLogEntry != null)
            Expanded(
              child: Row(
                children: [
                  Icon(_getLogIcon(_lastLogEntry!.level), size: 12, color: _getLogColor(_lastLogEntry!.level)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _lastLogEntry!.message,
                      style: TextStyle(color: _getLogColor(_lastLogEntry!.level), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(),
          // Log panel toggle button (hidden on Settings page)
          if (_selectedIndex != 3)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(_isLogPanelVisible ? Icons.expand_more : Icons.terminal, size: 16, color: Colors.white),
              tooltip: _isLogPanelVisible ? 'Hide Output' : 'Show Output',
              onPressed: () => setState(() => _isLogPanelVisible = !_isLogPanelVisible),
            ),
          if (_selectedIndex != 3) const SizedBox(width: 12),
          if (isConnected)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              tooltip: "Disconnect",
              onPressed: _handleDisconnect,
            ),
        ],
      ),
    );
  }

  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.debug:
        return Icons.bug_report;
    }
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red.shade300;
      case LogLevel.warning:
        return Colors.orange.shade300;
      case LogLevel.info:
        return Colors.white;
      case LogLevel.debug:
        return Colors.grey.shade400;
    }
  }
}
