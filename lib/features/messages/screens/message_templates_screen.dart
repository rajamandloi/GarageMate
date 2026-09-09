import 'package:flutter/material.dart';

class MessageTemplatesScreen extends StatefulWidget {
  const MessageTemplatesScreen({super.key});

  @override
  State<MessageTemplatesScreen> createState() =>
      _MessageTemplatesScreenState();
}

class _MessageTemplatesScreenState
    extends State<MessageTemplatesScreen> {
  final List<_MessageTemplate> _templates = [
    _MessageTemplate(
      title: 'Service Reminder',
      type: 'Service',
      message:
          'Hello {customerName}, your {vehicleModel} is due for service. Please contact us to schedule your service.',
      icon: Icons.build_rounded,
    ),
    _MessageTemplate(
      title: 'Special Offer',
      type: 'Special Offer',
      message:
          'Hello {customerName}, we have a special offer for you at GarageMate. Contact us to know more.',
      icon: Icons.local_offer_rounded,
    ),
    _MessageTemplate(
      title: 'Payment Reminder',
      type: 'Payment',
      message:
          'Hello {customerName}, your payment of {amount} is pending. Please contact us for more details.',
      icon: Icons.payments_rounded,
    ),
  ];

  void _showTemplateEditor({
    _MessageTemplate? template,
    int? index,
  }) {
    final titleController = TextEditingController(
      text: template?.title ?? '',
    );

    final messageController = TextEditingController(
      text: template?.message ?? '',
    );

    String selectedType = template?.type ?? 'Service';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template == null
                          ? 'New Message Template'
                          : 'Edit Message Template',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        prefixIcon:
                            Icon(Icons.title_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Message Type',
                        prefixIcon:
                            Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Service',
                          child: Text('Service'),
                        ),
                        DropdownMenuItem(
                          value: 'Special Offer',
                          child: Text('Special Offer'),
                        ),
                        DropdownMenuItem(
                          value: 'Payment',
                          child: Text('Payment'),
                        ),
                        DropdownMenuItem(
                          value: 'General',
                          child: Text('General'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: messageController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText:
                            'Write your WhatsApp message...',
                        alignLabelWithHint: true,
                        prefixIcon:
                            Icon(Icons.message_outlined),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Available variables: {customerName}, {vehicleModel}, {amount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () {
                          final title =
                              titleController.text.trim();
                          final message =
                              messageController.text.trim();

                          if (title.isEmpty ||
                              message.isEmpty) {
                            return;
                          }

                          setState(() {
                            final newTemplate =
                                _MessageTemplate(
                              title: title,
                              type: selectedType,
                              message: message,
                              icon: _iconForType(
                                selectedType,
                              ),
                            );

                            if (index != null) {
                              _templates[index] =
                                  newTemplate;
                            } else {
                              _templates.add(newTemplate);
                            }
                          });

                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(
                          Icons.save_rounded,
                        ),
                        label: const Text(
                          'Save Template',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteTemplate(int index) {
    setState(() {
      _templates.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template deleted.'),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Service':
        return Icons.build_rounded;
      case 'Special Offer':
        return Icons.local_offer_rounded;
      case 'Payment':
        return Icons.payments_rounded;
      default:
        return Icons.message_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Message Templates',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _showTemplateEditor();
        },
        icon: const Icon(Icons.add),
        label: const Text('Template'),
      ),
      body: _templates.isEmpty
          ? const Center(
              child: Text(
                'No message templates yet.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ),
              itemCount: _templates.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final template = _templates[index];

                return _TemplateCard(
                  template: template,
                  onEdit: () {
                    _showTemplateEditor(
                      template: template,
                      index: index,
                    );
                  },
                  onDelete: () {
                    _deleteTemplate(index);
                  },
                );
              },
            ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _MessageTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              template.icon,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.type,
                  style: TextStyle(
                    color:
                        theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  template.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageTemplate {
  final String title;
  final String type;
  final String message;
  final IconData icon;

  const _MessageTemplate({
    required this.title,
    required this.type,
    required this.message,
    required this.icon,
  });
}