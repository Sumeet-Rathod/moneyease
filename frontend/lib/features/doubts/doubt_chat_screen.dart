import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../config.dart';
import 'doubts_provider.dart';

class DoubtChatScreen extends ConsumerStatefulWidget {
  const DoubtChatScreen({super.key});

  @override
  ConsumerState<DoubtChatScreen> createState() => _DoubtChatScreenState();
}

class _DoubtChatScreenState extends ConsumerState<DoubtChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doubtsProvider.notifier).init();
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

  @override
  Widget build(BuildContext context) {
    final doubtsState = ref.watch(doubtsProvider);
    final notifier = ref.read(doubtsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.psychology, color: AppTheme.primaryTeal, size: 20),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Financial Doubt Assistant", style: TextStyle(fontSize: 16)),
                Text("AI & AMFI Knowledge Base", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _showCallbackDialog,
            icon: const Icon(Icons.phone_in_talk, size: 16, color: AppTheme.primaryTeal),
            label: const Text(
              "Talk to Expert",
              style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: doubtsState.messages.length + (doubtsState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == doubtsState.messages.length && doubtsState.isLoading) {
                    return _buildLoadingBubble();
                  }
                  final msg = doubtsState.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Suggested Chips Section
            if (doubtsState.suggestedChips.isNotEmpty)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: doubtsState.suggestedChips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final chip = doubtsState.suggestedChips[idx];
                    return ActionChip(
                      label: Text(
                        chip,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      elevation: 0,
                      onPressed: () {
                        notifier.askQuestion(chip);
                        _scrollToBottom();
                      },
                    );
                  },
                ),
              ),

            // Fixed Compliance Disclaimer in Chat Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFF1F5F9),
              child: const Text(
                AppConfig.complianceDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
            ),

            // Chat Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Ask about mutual funds, SIP, ELSS, KYC...",
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.primaryTeal),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (val) => _handleSend(notifier),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: doubtsState.isLoading ? null : () => _handleSend(notifier),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(DoubtMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.primaryTeal,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 40),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.topic != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  msg.topic!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ),
            Text(
              msg.text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  msg.source == "gemini_ai" ? "Source: Gemini AI" : "Source: MoneyEase FAQ KB",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
                InkWell(
                  onTap: _showCallbackDialog,
                  child: const Row(
                    children: [
                      Icon(Icons.support_agent, size: 14, color: AppTheme.primaryTeal),
                      SizedBox(width: 4),
                      Text(
                        "Talk to an Advisor",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
            ),
            SizedBox(width: 10),
            Text("Consulting knowledge base...", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  void _handleSend(DoubtsNotifier notifier) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    notifier.askQuestion(text);
    _scrollToBottom();
  }

  void _showCallbackDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text("Request Advisor Callback"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "A dedicated AMFI-registered advisor will contact you to review your goals and answer your queries.",
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: "Notes or specific query (optional)",
                border: OutlineInputBorder(),
                hintText: "e.g. Want advice on ELSS vs PPF tax saving",
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(doubtsProvider.notifier).requestCallback(noteController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Callback request placed! An advisor will reach out." : "Failed to place callback request."),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
            child: const Text("Request Call"),
          ),
        ],
      ),
    );
  }
}
