import '../models/campaign.dart';
import '../models/message_template.dart';

class CommunicationService {
  Future<List<MessageTemplate>> getTemplates() async {
    // Later this will come from the backend.
    return [];
  }

  Future<List<Campaign>> getCampaigns() async {
    // Later this will come from the backend.
    return [];
  }

  Future<void> createCampaign(Campaign campaign) async {
    // Backend API will be connected here.
  }

  Future<void> scheduleCampaign(Campaign campaign) async {
    // Backend scheduler will handle automatic sending.
  }

  Future<void> cancelCampaign(String campaignId) async {
    // Backend cancellation endpoint will be connected here.
  }
}