import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BankingSetupWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const BankingSetupWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<BankingSetupWidget> createState() => _BankingSetupWidgetState();
}

class _BankingSetupWidgetState extends State<BankingSetupWidget> {
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _mobileWalletController = TextEditingController();

  String? _selectedBank;
  String? _selectedMobileWallet;
  bool _bankAccountLinked = false;
  bool _mobileWalletLinked = false;

  final List<Map<String, dynamic>> _localBanks = [
    {
      'code': 'BIBD',
      'name': 'Bank Islam Brunei Darussalam (BIBD)',
      'logo': 'account_balance',
    },
    {
      'code': 'SCB',
      'name': 'Standard Chartered Bank',
      'logo': 'account_balance',
    },
    {
      'code': 'TAIB',
      'name': 'Tabung Amanah Islam Brunei (TAIB)',
      'logo': 'account_balance',
    },
    {
      'code': 'BOC',
      'name': 'Bank of China',
      'logo': 'account_balance',
    },
    {
      'code': 'UOB',
      'name': 'United Overseas Bank',
      'logo': 'account_balance',
    },
  ];

  final List<Map<String, dynamic>> _mobileWallets = [
    {
      'code': 'BIBD_nexgen',
      'name': 'BIBD Nexgen',
      'logo': 'account_balance_wallet',
    },
    {
      'code': 'baiduri_aspire',
      'name': 'Baiduri Aspire',
      'logo': 'account_balance_wallet',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _selectedBank = widget.initialData['selectedBank'];
    _selectedMobileWallet = widget.initialData['selectedMobileWallet'];
    _accountNumberController.text = widget.initialData['accountNumber'] ?? '';
    _accountHolderController.text = widget.initialData['accountHolder'] ?? '';
    _mobileWalletController.text =
        widget.initialData['mobileWalletNumber'] ?? '';
    _bankAccountLinked = widget.initialData['bankAccountLinked'] ?? false;
    _mobileWalletLinked = widget.initialData['mobileWalletLinked'] ?? false;
  }

  void _updateData() {
    bool isComplete = _bankAccountLinked || _mobileWalletLinked;

    widget.onDataChanged({
      'selectedBank': _selectedBank,
      'selectedMobileWallet': _selectedMobileWallet,
      'accountNumber': _accountNumberController.text,
      'accountHolder': _accountHolderController.text,
      'mobileWalletNumber': _mobileWalletController.text,
      'bankAccountLinked': _bankAccountLinked,
      'mobileWalletLinked': _mobileWalletLinked,
      'isComplete': isComplete,
    });
  }

  void _linkBankAccount() {
    if (_selectedBank != null &&
        _accountNumberController.text.trim().isNotEmpty &&
        _accountHolderController.text.trim().isNotEmpty) {
      setState(() {
        _bankAccountLinked = true;
      });
      _updateData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank account linked successfully'),
        ),
      );
    }
  }

  void _linkMobileWallet() {
    if (_selectedMobileWallet != null &&
        _mobileWalletController.text.trim().isNotEmpty) {
      setState(() {
        _mobileWalletLinked = true;
      });
      _updateData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile wallet linked successfully'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Payment Methods',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Link at least one payment method to receive your earnings',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        // Bank Account Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _bankAccountLinked
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName:
                        _bankAccountLinked ? 'check_circle' : 'account_balance',
                    color: _bankAccountLinked
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Account',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Link your local bank account for earnings withdrawal',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_bankAccountLinked) ...[
                SizedBox(height: 3.h),

                // Bank Selection
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  decoration: InputDecoration(
                    labelText: 'Select Bank',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  items: _localBanks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank['code'],
                      child: Text(bank['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBank = value;
                    });
                    _updateData();
                  },
                ),

                SizedBox(height: 2.h),

                // Account Holder Name
                TextFormField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    labelText: 'Account Holder Name',
                    hintText: 'Enter full name as per bank record',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) => _updateData(),
                ),

                SizedBox(height: 2.h),

                // Account Number
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    hintText: 'Enter your account number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.confirmation_number),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateData(),
                ),

                SizedBox(height: 3.h),

                ElevatedButton(
                  onPressed: (_selectedBank != null &&
                          _accountNumberController.text.trim().isNotEmpty &&
                          _accountHolderController.text.trim().isNotEmpty)
                      ? _linkBankAccount
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                  child: const Text('Link Bank Account'),
                ),
              ] else ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.colorScheme.tertiary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          const Text('Bank account linked successfully'),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${_localBanks.firstWhere((bank) => bank['code'] == _selectedBank)['name']}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '**** **** ${_accountNumberController.text.length > 4 ? _accountNumberController.text.substring(_accountNumberController.text.length - 4) : _accountNumberController.text}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Mobile Wallet Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _mobileWalletLinked
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: _mobileWalletLinked
                        ? 'check_circle'
                        : 'account_balance_wallet',
                    color: _mobileWalletLinked
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobile Wallet',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Link your mobile wallet for instant transfers',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_mobileWalletLinked) ...[
                SizedBox(height: 3.h),

                // Mobile Wallet Selection
                DropdownButtonFormField<String>(
                  value: _selectedMobileWallet,
                  decoration: InputDecoration(
                    labelText: 'Select Mobile Wallet',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                  ),
                  items: _mobileWallets.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet['code'],
                      child: Text(wallet['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMobileWallet = value;
                    });
                    _updateData();
                  },
                ),

                SizedBox(height: 2.h),

                // Mobile Wallet Number
                TextFormField(
                  controller: _mobileWalletController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Wallet Number',
                    hintText: '+673 XXXXXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => _updateData(),
                ),

                SizedBox(height: 3.h),

                ElevatedButton(
                  onPressed: (_selectedMobileWallet != null &&
                          _mobileWalletController.text.trim().isNotEmpty)
                      ? _linkMobileWallet
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                  child: const Text('Link Mobile Wallet'),
                ),
              ] else ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.colorScheme.tertiary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          const Text('Mobile wallet linked successfully'),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${_mobileWallets.firstWhere((wallet) => wallet['code'] == _selectedMobileWallet)['name']}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _mobileWalletController.text,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        if (!_bankAccountLinked && !_mobileWalletLinked) ...[
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.errorContainer
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.error
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'warning',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Please link at least one payment method to continue',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _mobileWalletController.dispose();
    super.dispose();
  }
}
