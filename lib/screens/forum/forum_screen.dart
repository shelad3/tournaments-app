import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/forum_provider.dart';
import '../../models/forum_message_model.dart';
import '../../models/channel_model.dart';
import '../../utils/avatar_helper.dart';
import '../profile/user_profile_screen.dart';
import '../../services/forum_service.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _showingChannels = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().ensureGlobalChannel();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final auth = context.read<AuthProvider>();
    final forum = context.read<ForumProvider>();
    final text = _textController.text.trim();
    if (text.isEmpty || !auth.isLoggedIn) return;
    _textController.clear();
    forum.sendText(
      userId: auth.user!.uid,
      userName: auth.user!.fullName,
      userPhotoUrl: auth.user!.photoUrl,
      text: text,
    );
  }

  Future<void> _pickAndSendImage() async {
    final auth = context.read<AuthProvider>();
    final forum = context.read<ForumProvider>();
    if (!auth.isLoggedIn) return;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    await forum.sendImage(
      userId: auth.user!.uid,
      userName: auth.user!.fullName,
      userPhotoUrl: auth.user!.photoUrl,
      image: image,
    );
    _scrollToBottom();
  }

  void _openChannel(ChannelModel channel) {
    context.read<ForumProvider>().switchChannel(channel.id);
    setState(() => _showingChannels = false);
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    ChannelType selectedType = ChannelType.public;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Create Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Channel name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChannelType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Channel Type',
                  prefixIcon: Icon(Icons.visibility, size: 20),
                ),
                items: [
                  const DropdownMenuItem(value: ChannelType.public, child: Text('Public — everyone can read & write')),
                  const DropdownMenuItem(value: ChannelType.adminOnly, child: Text('Admin Only — only admins can write')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final service = ForumService();
                await service.createChannel(name, context.read<AuthProvider>().user!.uid, type: selectedType);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showingChannels) return _buildChannelList();
    return _buildChat();
  }

  Widget _buildChannelList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        actions: [
          if (context.read<AuthProvider>().isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create channel',
              onPressed: _showCreateChannelDialog,
            ),
        ],
      ),
      body: Consumer<ForumProvider>(
        builder: (_, provider, __) {
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: const TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadChannels(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!provider.channelsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.channels.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No channels yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.channels.length,
            itemBuilder: (_, i) {
              final channel = provider.channels[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: channel.type == ChannelType.global
                        ? Colors.green.shade100
                        : Colors.indigo.shade100,
                    child: Icon(
                      channel.type == ChannelType.global ? Icons.public : Icons.tag,
                      color: channel.type == ChannelType.global ? Colors.green.shade700 : Colors.indigo.shade700,
                    ),
                  ),
                  title: Text(channel.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(channel.type == ChannelType.global ? 'Default channel' : channel.typeLabel,
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openChannel(channel),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChat() {
    final forum = context.read<ForumProvider>();
    final channelName = forum.channels
        .where((c) => c.id == forum.currentChannelId)
        .map((c) => c.name)
        .firstOrNull ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(channelName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showingChannels = true),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ForumProvider>(
              builder: (_, provider, __) {
                if (provider.messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Start the conversation!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    final max = _scrollController.position.maxScrollExtent;
                    if (_scrollController.offset < max - 100) {
                      _scrollController.jumpTo(max);
                    }
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.messages.length,
                  itemBuilder: (_, i) => _MessageBubble(message: provider.messages[i]),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -1))],
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickAndSendImage,
                    tooltip: 'Send photo',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ForumMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarHelper.buildCircleAvatar(message.userPhotoUrl, 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: message.userId),
                  )),
                  child: Text(
                    message.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 2),
                if (message.type == ForumMessageType.text && message.text != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message.text!, style: const TextStyle(fontSize: 14)),
                  ),
                if (message.type == ForumMessageType.image && message.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () => _showImagePreview(context, message.imageUrl!),
                      child: Image.network(
                        message.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(timeFormat.format(message.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
