import 'package:flutter/material.dart';
import '../../../services/sync_service.dart';
import '../../../theme/app_theme.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  final SyncService _syncService = SyncService();

  SyncStatus _syncStatus = SyncStatus.idle;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();

    // Listen to sync status changes
    _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });

        // Reload pending count after sync completes
        if (status == SyncStatus.completed || status == SyncStatus.error) {
          _loadPendingCount();
        }
      }
    });
  }

  Future<void> _loadPendingCount() async {
    final count = await _syncService.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  Future<void> _manualSync() async {
    final result = await _syncService.syncPendingOperations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.successColor : Colors.red,
          action: result.errors.isNotEmpty
              ? SnackBarAction(
                  label: 'Ver errores',
                  textColor: Colors.white,
                  onPressed: () {
                    _showErrorsDialog(result.errors);
                  },
                )
              : null,
        ),
      );
    }
  }

  void _showErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errores de sincronización'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('• $error'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0 && _syncStatus == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _syncStatus == SyncStatus.syncing ? null : _manualSync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_syncStatus == SyncStatus.syncing)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(_getIcon(), size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              _getText(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return AppTheme.secondaryBlue;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.completed:
        return AppTheme.successColor;
      default:
        return Colors.orange;
    }
  }

  IconData _getIcon() {
    switch (_syncStatus) {
      case SyncStatus.error:
        return Icons.sync_problem;
      case SyncStatus.completed:
        return Icons.cloud_done;
      default:
        return Icons.cloud_upload;
    }
  }

  String _getText() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.error:
        return 'Error sync';
      case SyncStatus.completed:
        return 'Sincronizado';
      default:
        return _pendingCount > 0
            ? '$_pendingCount pendiente${_pendingCount > 1 ? 's' : ''}'
            : '';
    }
  }
}
