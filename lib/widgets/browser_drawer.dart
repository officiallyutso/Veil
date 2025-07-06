import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veil/core/routes.dart';
import 'package:veil/services/focus_mode_service.dart';
import 'package:veil/services/glass_mode_service.dart';

class BrowserDrawer extends StatelessWidget {
  final VoidCallback onToggleIncognito;
  final bool isIncognito;
  
  const BrowserDrawer({
    super.key,
    required this.onToggleIncognito,
    required this.isIncognito,
  });
  
  @override
  Widget build(BuildContext context) {
    final focusModeService = Provider.of<FocusModeService>(context);
    final glassModeService = Provider.of<GlassModeService>(context);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veil Browser',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Private and focused browsing',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              isIncognito ? Icons.visibility_off : Icons.visibility,
              color: isIncognito ? Theme.of(context).colorScheme.primary : null,
            ),
            title: const Text('Incognito Mode'),
            subtitle: Text(
              isIncognito 
                  ? 'Browsing privately' 
                  : 'Browsing normally',
            ),
            trailing: Switch(
              value: isIncognito,
              onChanged: (_) => onToggleIncognito(),
            ),
          ),
          const Divider(),
          ListTile(
            

            leading: Icon(
              focusModeService.isActive ? Icons.forum : Icons.blur_off,
              color: focusModeService.isActive ? Theme.of(context).colorScheme.primary : null,
            ),
            title: const Text('Focus Mode'),
            subtitle: Text(
              focusModeService.isActive 
                  ? 'Stay on task' 
                  : 'Distraction allowed',
            ),
            trailing: Switch(
              value: focusModeService.isActive,
              onChanged: (value) {
                if (value) {
                  _showFocusModeDialog(context);
                } else {
                  focusModeService.stopFocusMode();
                }
              },
            ),
          ),
          ListTile(
            leading: Icon(
              glassModeService.isActive ? Icons.shield : Icons.shield_outlined,
              color: glassModeService.isActive ? Theme.of(context).colorScheme.primary : null,
            ),
            title: const Text('Glass Mode'),
            subtitle: Text(
              glassModeService.isActive 
                  ? 'Sensitive content blurred' 
                  : 'All content visible',
            ),
            trailing: Switch(
              value: glassModeService.isActive,
              onChanged: (value) {
                if (value) {
                  glassModeService.enableGlassMode();
                } else {
                  glassModeService.disableGlassMode();
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Bookmarks'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.bookmarks);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.history);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Sessions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.sessions);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Notes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.notes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Receipts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.receipts);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }
  
  void _showFocusModeDialog(BuildContext context) {
    final focusModeService = Provider.of<FocusModeService>(context, listen: false);
    final allowedDomainsController = TextEditingController(
      text: focusModeService.allowedDomains.join(', '),
    );
    int timeLimit = focusModeService.timeLimit;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Focus Mode Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set time limit and allowed domains:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: timeLimit,
              decoration: const InputDecoration(
                labelText: 'Time Limit',
                border: OutlineInputBorder(),
              ),
              items: [15, 30, 45, 60, 90, 120].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value minutes'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  timeLimit = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: allowedDomainsController,
              decoration: const InputDecoration(
                labelText: 'Allowed Domains (comma separated)',
                hintText: 'example.com, another.com',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final domains = allowedDomainsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              
              focusModeService.startFocusMode(
                timeLimit: timeLimit,
                allowedDomains: domains,
              );
              
              Navigator.pop(context);
            },
            child: const Text('Start Focus Mode'),
          ),
        ],
      ),
    );
  }
}