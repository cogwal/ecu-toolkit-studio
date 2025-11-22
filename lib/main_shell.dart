import 'package:flutter/material.dart';
import 'ecu_model.dart';
import 'pages/connection_page.dart';
import 'pages/functional_pages.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  EcuProfile? _connectedProfile;

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
    // Rule: You cannot go to tabs 1, 2, or 3 unless connected
    if (_connectedProfile == null && index > 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please connect to an ECU to access this tool."),
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
      LiveDashboardPage(profile: _connectedProfile),
      DtcPage(profile: _connectedProfile),
      FlashWizardPage(profile: _connectedProfile),
    ];

    // Define visual state for tabs
    final bool isLocked = _connectedProfile == null;
    final Color activeColor = Colors.white;
    final Color disabledColor = Colors.grey.withOpacity(0.3);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // --- 1. UPDATED SIDEBAR ---
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  backgroundColor: const Color(0xFF252526),
                  
                  // Ensure text is always shown
                  labelType: NavigationRailLabelType.all,
                  
                  // Define base styles
                  selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
                  selectedLabelTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelTextStyle: const TextStyle(fontSize: 11),

                  destinations: [
                    // Tab 0: Connect (Always Active)
                    const NavigationRailDestination(
                      icon: Icon(Icons.cable),
                      label: Text('Connect'),
                    ),

                    // Tab 1: Live Data (Conditional)
                    NavigationRailDestination(
                      icon: Icon(Icons.speed, color: isLocked ? disabledColor : null),
                      label: Text('Live Data', style: TextStyle(color: isLocked ? disabledColor : activeColor)),
                    ),

                    // Tab 2: DTCs (Conditional)
                    NavigationRailDestination(
                      icon: Icon(Icons.healing, color: isLocked ? disabledColor : null),
                      label: Text('DTCs', style: TextStyle(color: isLocked ? disabledColor : activeColor)),
                    ),

                    // Tab 3: Flash (Conditional)
                    NavigationRailDestination(
                      icon: Icon(Icons.system_update_alt, color: isLocked ? disabledColor : null),
                      label: Text('Flash', style: TextStyle(color: isLocked ? disabledColor : activeColor)),
                    ),
                  ],
                ),
                
                const VerticalDivider(width: 1, thickness: 1),
                
                // --- 2. MAIN CONTENT ---
                Expanded(child: pages[_selectedIndex]),
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
            isConnected 
             ? "CONNECTED: ${_connectedProfile!.name} (0x${_connectedProfile!.txId.toRadixString(16).toUpperCase()})" 
             : "NO CONNECTION",
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