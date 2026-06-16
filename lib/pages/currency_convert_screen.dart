import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/currency_service.dart';

class CurrencyConvertScreen extends StatefulWidget {
  const CurrencyConvertScreen({super.key});

  @override
  State<CurrencyConvertScreen> createState() => _CurrencyConvertScreenState();
}

class _CurrencyConvertScreenState extends State<CurrencyConvertScreen> {
  static const _primary = Color(0xFF2A52BE);
  static const _bg = Color(0xFFF8F9FA);

  final _amountController = TextEditingController();

  String _selectedCurrency = 'USD';
  double _result = 0;
  bool _isLoading = false;
  String _errorMsg = '';
  Map<String, double> _cachedRates = {};

  static const Map<String, _CurrencyInfo> _currencies = {
    'USD': _CurrencyInfo('Dollar Amerika', Icons.attach_money),
    'EUR': _CurrencyInfo('Euro', Icons.euro),
    'GBP': _CurrencyInfo('Pound Inggris', Icons.currency_pound),
    'JPY': _CurrencyInfo('Yen Jepang', Icons.currency_yen),
    'CNY': _CurrencyInfo('Yuan China', Icons.currency_yuan),
    'SGD': _CurrencyInfo('Dollar Singapura', Icons.monetization_on),
  };

  void _recalculate() {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(raw) ?? 0;
    if (_cachedRates.containsKey(_selectedCurrency)) {
      setState(() {
        _result = amount * _cachedRates[_selectedCurrency]!;
      });
    }
  }

  Future<void> _convert() async {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _errorMsg = 'Masukkan jumlah rupiah yang valid.');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = ''; });
    try {
      _cachedRates = await CurrencyService.getRates();
      _recalculate();
      setState(() => _isLoading = false);
    } catch (_) {
      setState(() {
        _errorMsg = 'Gagal mengambil kurs. Periksa koneksi internet.';
        _isLoading = false;
      });
    }
  }

  String _formatResult(double value) {
    if (value == 0) return '-';
    if (value >= 1000) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(4);
    return value.toStringAsFixed(6);
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Konversi Kurs'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Rupiah ke mata uang dunia',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Input Rupiah ──────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JUMLAH RUPIAH',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Rp',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                  color: Color(0xFFCBD5E1), fontSize: 30),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) {
                              if (_cachedRates.isNotEmpty) _recalculate();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Currency Selector ─────────────────────────────────────
              _card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PILIH MATA UANG',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currencies.keys.map((code) {
                        final isSelected = _selectedCurrency == code;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCurrency = code);
                            if (_cachedRates.isNotEmpty) _recalculate();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currencies[code]!.icon,
                                  size: 16,
                                  color:
                                      isSelected ? Colors.white : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  code,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Result ────────────────────────────────────────────────
              _card(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'HASIL KONVERSI',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatResult(_result),
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currencies[_selectedCurrency]!.icon,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_selectedCurrency — ${_currencies[_selectedCurrency]!.name}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMsg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMsg,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _convert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: _primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Konversi Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyInfo {
  final String name;
  final IconData icon;
  const _CurrencyInfo(this.name, this.icon);
}