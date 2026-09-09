import 'package:flutter/material.dart';

import '../models/campaign.dart';
//import '../models/message_template.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final List<Campaign> _campaigns = [];

  Future<void> _createCampaign() async {
    final campaign = await Navigator.push<Campaign>(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateCampaignScreen(),
      ),
    );

    if (campaign == null) return;

    setState(() {
      _campaigns.insert(0, campaign);
    });
  }

  String _statusText(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.scheduled:
        return 'Scheduled';
      case CampaignStatus.processing:
        return 'Processing';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.failed:
        return 'Failed';
      case CampaignStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhatsApp Campaigns',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCampaign,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Campaign'),
      ),
      body: _campaigns.isEmpty
          ? _EmptyCampaigns(
              onCreate: _createCampaign,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ),
              itemCount: _campaigns.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final campaign = _campaigns[index];

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
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.campaign_rounded,
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
                              campaign.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${campaign.totalRecipients} recipients',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _statusText(campaign.status),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (campaign.status ==
                          CampaignStatus.completed)
                        Text(
                          '${campaign.sentCount}/${campaign.totalRecipients}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCampaigns({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 70,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'No campaigns yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a campaign to send special offers to your customers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Campaign'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCampaignScreen extends StatefulWidget {
  const _CreateCampaignScreen();

  @override
  State<_CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState
    extends State<_CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _offerTitleController = TextEditingController();
  final _offerDescriptionController =
      TextEditingController();

  DateTime? _scheduledDate;
  final int _recipientCount = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _offerTitleController.dispose();
    _offerDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );

    if (date == null) return;

    setState(() {
      _scheduledDate = date;
    });
  }

  void _saveCampaign() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final campaign = Campaign(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      name: _nameController.text.trim(),
      templateId: 'special_offer',
      offerTitle: _offerTitleController.text.trim(),
      offerDescription:
          _offerDescriptionController.text.trim(),
      scheduledAt: _scheduledDate,
      totalRecipients: _recipientCount,
      status: _scheduledDate == null
          ? CampaignStatus.draft
          : CampaignStatus.scheduled,
    );

    Navigator.pop(context, campaign);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Campaign',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Name',
                  hintText: 'Example: Monsoon Offer',
                  prefixIcon:
                      Icon(Icons.campaign_outlined),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Campaign name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _offerTitleController,
                decoration: const InputDecoration(
                  labelText: 'Offer Title',
                  hintText: '20% OFF on AC Service',
                  prefixIcon:
                      Icon(Icons.local_offer_outlined),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Offer title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller:
                    _offerDescriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Offer Description',
                  hintText:
                      'Describe the offer and its benefits...',
                  prefixIcon:
                      Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Offer description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.people_alt_outlined,
                ),
                title: const Text(
                  'Recipients',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _recipientCount == 0
                      ? 'Will be calculated by backend'
                      : '$_recipientCount customers',
                ),
              ),

              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.schedule_outlined,
                ),
                title: const Text(
                  'Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _scheduledDate == null
                      ? 'Send manually / schedule later'
                      : 'Scheduled for ${_scheduledDate!.day}/'
                          '${_scheduledDate!.month}/'
                          '${_scheduledDate!.year}',
                ),
                trailing: OutlinedButton(
                  onPressed: _selectDate,
                  child: const Text('Select'),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _saveCampaign,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Save Campaign',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}