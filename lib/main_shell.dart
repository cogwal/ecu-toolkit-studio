import 'package:flutter/material.dart';
import 'models/ecu_profile.dart';
import 'pages/connection_page.dart';
import 'pages/functional_pages.dart';
import 'pages/settings_page.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const MainShell({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  EcuProfile? _connectedProfile;

  @override
  void initState() {
    super.initState();
    debugPrint('MainShell.initState called');
  }

  // --- Connection Logic ---
  void _handleConnection(EcuProfile profile) {
    setState(() {
      _connectedProfile = profile;
      _selectedIndex = 1; // Auto-jump to Dashboard on connect
    });
  }

  void _handleDisconnect() {
    setState(() {
      _connectedProfile = null;
      _selectedIndex = 0; // Return to Connect page
    });
  }

  // --- Navigation Logic ---
  void _onDestinationSelected(int index) {
    // Rule: You cannot go to tabs 1, or 2 unless connected
    if (_connectedProfile == null && index >= 1 && index <= 2) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please connect to an ECU to access this tool.", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ),
      );
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
      TargetInfoPage(profile: _connectedProfile),
      FlashWizardPage(profile: _connectedProfile),
      // Settings Page (full-screen like other pages)
      SettingsPage(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme),
    ];

    // Define visual state for tabs
    final bool isLocked = _connectedProfile == null;
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

                // --- MAIN CONTENT ---
                Expanded(
                  child: Stack(
                    children: [
                      // Main content
                      Positioned.fill(child: pages[_selectedIndex]),
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
    bool isConnected = _connectedProfile != null;
    return Container(
      height: 28,
      color: isConnected ? const Color(0xFF007ACC) : const Color(0xFF333333), // Blue if connected, Grey if not
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(isConnected ? Icons.link : Icons.link_off, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            isConnected ? "CONNECTED: ${_connectedProfile!.name} (0x${_connectedProfile!.txId.toRadixString(16).toUpperCase()})" : "NO CONNECTION",
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
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
}
