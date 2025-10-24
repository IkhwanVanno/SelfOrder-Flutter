class ReservationPaymentMethod {
  final String paymentMethod;
  final String paymentName;
  final String paymentImage;
  final int totalFee;
  final String paymentGroup;

  ReservationPaymentMethod({
    required this.paymentMethod,
    required this.paymentName,
    required this.paymentImage,
    required this.totalFee,
    required this.paymentGroup,
  });

  factory ReservationPaymentMethod.fromJson(Map<String, dynamic> json) {
    return ReservationPaymentMethod(
      paymentMethod: json['paymentMethod'] ?? '',
      paymentName: json['paymentName'] ?? '',
      paymentImage: json['paymentImage'] ?? '',
      totalFee: int.tryParse(json['totalFee'].toString()) ?? 0,
      paymentGroup: json['paymentGroup'] ?? 'other',
    );
  }
}
