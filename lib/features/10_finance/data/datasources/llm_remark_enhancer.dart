/// Abstract interface for LLM-based remark enhancement
/// 
/// This interface allows for optional integration with LLM services
/// (OpenAI, Claude, etc.) to enhance system remarks with AI-generated
/// human-friendly explanations of transaction purposes.
/// 
/// Implementation is optional - the rule-based RemarkExtractionEngine
/// works independently without requiring an LLM.
abstract class LLMRemarkEnhancer {
  /// Enhances the system remark using LLM analysis of the SMS body
  /// 
  /// Returns an enhanced system_remark if LLM is available and configured,
  /// otherwise returns null to fallback to rule-based system remark.
  /// 
  /// [smsBody] - The raw SMS message body
  /// [rawRemark] - The extracted raw remark (merchant name, reference, etc.)
  /// [systemRemark] - The rule-based system remark (fallback)
  /// 
  /// Returns null if LLM is not configured or if enhancement fails.
  Future<String?> enhanceSystemRemark(
    String smsBody,
    String? rawRemark,
    String? systemRemark,
  );
}
