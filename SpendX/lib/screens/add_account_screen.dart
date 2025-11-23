import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? accountToEdit;

  const AddAccountScreen({Key? key, this.accountToEdit}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedType = 'Bank';
  String _selectedLogo = '';

  List<String> _filteredBanks = [];
  bool _showBankSuggestions = false;

  // --- LOGO/BANK LISTS ---

  final List<Map<String, String>> _bankLogos = [
    {'name': 'SBI', 'path': 'assets/img/bank/sbi.png'},
    {'name': 'Yes Bank', 'path': 'assets/img/bank/yes.png'},
    {'name': 'Bank of Baroda', 'path': 'assets/img/bank/bob.png'},
    {'name': 'Axis Bank', 'path': 'assets/img/bank/axis.png'},
    {'name': 'HDFC Bank', 'path': 'assets/img/bank/hdfc.png'},
    {'name': 'Federal Bank', 'path': 'assets/img/bank/federal.png'},
    {'name': 'ICICI Bank', 'path': 'assets/img/bank/icici.png'},
    {'name': 'Others', 'path': 'assets/img/bank/others.png'},
  ];

  final List<Map<String, String>> _cashLogos = [
    {'name': 'Cash', 'path': 'assets/img/cash/cash.png'},
  ];

  final List<String> _allBanks = [
    'State Bank of India', 'Bank of Baroda', 'Punjab National Bank', 'Canara Bank',
    'Union Bank of India', 'Bank of India', 'Central Bank of India', 'Indian Bank',
    'Indian Overseas Bank', 'UCO Bank', 'Bank of Maharashtra', 'Punjab & Sind Bank',
    'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra Bank', 'IndusInd Bank',
    'IDBI Bank', 'Yes Bank Ltd.', 'IDFC First Bank', 'Federal Bank', 'RBL Bank',
    'South Indian Bank', 'Bandhan Bank', 'DCB Bank', 'City Union Bank',
    'Karnataka Bank Ltd.', 'Karur Vysya Bank Ltd.', 'Tamilnad Mercantile Bank Ltd.',
    'CSB Bank Ltd.', 'Dhanlaxmi Bank Ltd.', 'Jammu & Kashmir Bank Ltd.',
    'The Nainital Bank Ltd.', 'AU Small Finance Bank Limited',
    'Capital Small Finance Bank Limited', 'Equitas Small Finance Bank Limited',
    'ESAF Small Finance Bank Limited', 'Fincare Small Finance Bank Limited',
    'Jana Small Finance Bank Limited', 'North East Small Finance Bank Limited',
    'Suryoday Small Finance Bank Limited', 'Ujjivan Small Finance Bank Limited',
    'Utkarsh Small Finance Bank Limited', 'Unity Small Finance Bank Limited',
    'Shivalik Small Finance Bank Limited', 'Airtel Payments Bank Limited',
    'India Post Payments Bank Limited', 'Fino Payments Bank Limited',
    'Paytm Payments Bank Limited', 'AB Bank PLC', 'American Express Banking Corporation',
    'Australia and New Zealand Banking Group Ltd.', 'Bank of America',
    'Bank of Bahrain and Kuwait B.S.C.', 'Bank of Ceylon', 'Bank of China Limited',
    'Bank of Nova Scotia', 'Barclays Bank Plc.', 'BNP Paribas', 'Citibank N.A.',
    'Credit Suisse A.G.', 'DBS Bank India Limited', 'Deutsche Bank', 'HSBC Ltd.',
    'J.P. Morgan Chase Bank N.A.', 'Standard Chartered Bank', 'Societe Generale',
    'Sumitomo Mitsui Banking Corporation', 'Woori Bank'
  ];

  // -------------------------

  @override
  void initState() {
    super.initState();

    if (widget.accountToEdit != null) {
      _nameController.text = widget.accountToEdit!.name;
      _balanceController.text = widget.accountToEdit!.balance.toString();
      _selectedType = widget.accountToEdit!.type;
      _selectedLogo = widget.accountToEdit!.imagePath ?? '';
    } else {
      // Automatically select the first available logo to prevent empty selection
      if (_selectedType == 'Bank' && _bankLogos.isNotEmpty) {
        _selectedLogo = _bankLogos.first['path']!;
      } else if (_selectedType == 'Cash' && _cashLogos.isNotEmpty) {
        _selectedLogo = _cashLogos.first['path']!;
      }
    }

    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_selectedType == 'Bank') {
      final text = _nameController.text;
      if (text.length >= 3) {
        setState(() {
          _filteredBanks = _allBanks
              .where((bank) => bank.toLowerCase().contains(text.toLowerCase()))
              .toList();
          _showBankSuggestions = _filteredBanks.isNotEmpty;
        });
      } else {
        setState(() {
          _filteredBanks = [];
          _showBankSuggestions = false;
        });
      }
    } else {
      setState(() {
        _showBankSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Palette
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final accentGreen = const Color(0xFF2ECC71);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.accountToEdit == null ? 'New Wallet' : 'Edit Wallet',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Type Selector (Segmented Control)
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTypeTab('Bank', isDark),
                  _buildTypeTab('Cash', isDark),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 2. Input Fields
            Text(
              'DETAILS',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: _selectedType == 'Bank' ? 'Bank Name' : 'Account Name',
                  hint: _selectedType == 'Bank' ? 'e.g. State Bank of India' : 'e.g. Petty Cash',
                  icon: FontAwesomeIcons.tag,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                // Suggestions List
                if (_showBankSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredBanks.length,
                      itemBuilder: (context, index) {
                        final bankName = _filteredBanks[index];
                        return ListTile(
                          title: Text(
                            bankName,
                            style: TextStyle(color: primaryText, fontSize: 14),
                          ),
                          onTap: () {
                            _nameController.text = bankName;
                            // Move cursor to end
                            _nameController.selection = TextSelection.fromPosition(
                              TextPosition(offset: bankName.length),
                            );
                            setState(() {
                              _showBankSuggestions = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _balanceController,
              label: 'Current Balance',
              hint: '0.00',
              icon: FontAwesomeIcons.indianRupeeSign,
              isDark: isDark,
              surfaceColor: surfaceColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
              isNumber: true,
            ),

            const SizedBox(height: 32),

            // 3. Logo Selection
            Text(
              'CHOOSE ICON',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamically show list based on type selection
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: (_selectedType == 'Bank' ? _bankLogos : _cashLogos)
                  .map((logo) => _buildLogoItem(logo, isDark, accentGreen))
                  .toList(),
            ),

            const SizedBox(height: 40),

            // 4. Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: accentGreen.withOpacity(0.4),
                ),
                child: Text(
                  widget.accountToEdit == null ? 'Create Wallet' : 'Update Wallet',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTypeTab(String label, bool isDark) {
    final isSelected = _selectedType == label;
    const accentColor = Color(0xFF2ECC71);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = label;
            // Switch default selected logo when tab changes based on available list
            if (widget.accountToEdit == null || widget.accountToEdit!.type != label) {
                if (label == 'Bank') {
                _selectedLogo = _bankLogos.isNotEmpty ? _bankLogos.first['path']! : '';
              } else {
                _selectedLogo = _cashLogos.isNotEmpty ? _cashLogos.first['path']! : '';
              }
            } else {
              // If switching back to original type, restore original logo
              _selectedLogo = widget.accountToEdit!.imagePath ?? '';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? accentColor.withOpacity(0.2) : accentColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? accentColor : Colors.white)
                  : (isDark ? Colors.grey : Colors.black54),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color surfaceColor,
    required Color primaryText,
    required Color? secondaryText,
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: TextStyle(color: primaryText, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, color: secondaryText, size: 18),
          labelText: label,
          labelStyle: TextStyle(color: secondaryText),
          hintText: hint,
          hintStyle: TextStyle(color: secondaryText?.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildLogoItem(Map<String, String> logo, bool isDark, Color accentColor) {
    final isSelected = _selectedLogo == logo['path'];

    return GestureDetector(
      onTap: () => setState(() => _selectedLogo = logo['path']!),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: Image.asset(
              logo['path']!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  _selectedType == 'Bank'
                      ? FontAwesomeIcons.buildingColumns
                      : FontAwesomeIcons.wallet,
                  color: isSelected ? accentColor : Colors.grey,
                  size: 24,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            logo['name']!,
            style: TextStyle(
              color: isSelected ? accentColor : (isDark ? Colors.grey : Colors.black54),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- BUSINESS LOGIC & MODAL ---

  void _saveAccount() {
    if (_nameController.text.trim().isEmpty ||
        _balanceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final bool isEditing = widget.accountToEdit != null;
    final String successMessage = isEditing ? 'Wallet Updated Successfully!' : 'Wallet Created Successfully!';

    if (isEditing) {
      // Update existing account
      final updatedAccount = Account(
        id: widget.accountToEdit!.id, // Keep original ID
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.tryParse(_balanceController.text.trim()) ?? 0,
        imagePath: _selectedLogo,
        isDefault: widget.accountToEdit!.isDefault,
      );
      context.read<AccountProvider>().updateAccount(updatedAccount);
    } else {
      // Create new account
      final account = Account(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.tryParse(_balanceController.text.trim()) ?? 0,
        imagePath: _selectedLogo,
        isDefault: false,
      );
      context.read<AccountProvider>().addAccount(account);
    }

    // Call the premium success modal function
    _showSuccessModal(context, successMessage);
  }

  void _showSuccessModal(BuildContext context, String message) {
    Future.microtask(() {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (dialogContext) {
          // Auto-dismiss and navigate back after 1.8 seconds
          Future.delayed(const Duration(milliseconds: 1800), () {
            // Dismiss the success dialog
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop(); 
            }
            // Navigate back to the previous screen (the account list)
            if (Navigator.of(this.context).canPop()) {
              Navigator.of(this.context).pop();
            }
          });

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final accentGreen = const Color(0xFF2ECC71);
          final accentBlue = const Color(0xFF4EA8DE);
          final primaryText = isDark ? Colors.white : const Color(0xFF1A1A2E);
          final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E1E1E),
                          const Color(0xFF2D2D2D),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF8F9FA),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentGreen.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with gradient background
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentGreen.withOpacity(0.8),
                            accentBlue.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentGreen.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        FontAwesomeIcons.circleCheck,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Title
                    Text(
                      message,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    
                    // Subtitle
                    Text(
                      'Changes have been saved successfully.',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}