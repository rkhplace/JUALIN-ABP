const fs = require('fs');
const path = require('path');

const basePath = 'C:\\Users\\ASUS\\Downloads\\IMPAL\\mobile_app';
const libPath = path.join(basePath, 'lib');

const screens = [
    'home_screen.dart',
    'not_found_screen.dart',
    'products_screen.dart',
    'auth_screen.dart',
    'login_screen.dart',
    'register_screen.dart',
    'forgot_password_screen.dart',
    'reset_password_screen.dart',
    'dashboard_screen.dart',
    'product_screen.dart',
    'product_detail_screen.dart',
    'profile_screen.dart',
    'profile_edit_screen.dart',
    'chat_screen.dart',
    'seller_dashboard_screen.dart',
    'seller_products_screen.dart',
    'seller_product_new_screen.dart',
    'seller_product_edit_screen.dart'
];

const widgets = [
    'auth/login_form.dart',
    'auth/register_form.dart',
    'chat/chat_bubble.dart',
    'chat/chat_header.dart',
    'chat/chat_interface.dart',
    'chat/chat_input.dart',
    'chat/chat_item.dart',
    'chat/chat_list.dart',
    'chat/chat_skeleton.dart',
    'chat/chat_sidebar.dart',
    'chat/chat_window.dart',
    'common/header.dart',
    'forms/product_form.dart',
    'payment/payment_method_modal.dart',
    'product/product_filter.dart',
    'profile/payment_history_list.dart',
    'profile/profile_form.dart',
    'profile/profile_image_uploader.dart',
    'ui/app_chrome.dart',
    'ui/badge.dart',
    'ui/button.dart',
    'ui/confirmation_modal.dart',
    'ui/dropdown_menu.dart',
    'ui/error_boundary.dart',
    'ui/error_fallback.dart',
    'ui/footer.dart',
    'ui/help_center.dart',
    'ui/input.dart',
    'ui/logo.dart',
    'ui/navbar.dart',
    'ui/page_loader.dart',
    'ui/pagination.dart',
    'ui/search_bar.dart',
    'ui/select.dart',
    'ui/spinner.dart',
    'ui/text_button.dart',
    'ui/toast.dart',
    'ui/top_bar.dart',
    'ui/skeleton/list_skeleton.dart',
    'ui/skeleton/product_card_skeleton.dart',
    'ui/skeleton/product_detail_skeleton.dart',
    'ui/skeleton/skeleton.dart',
    'wallet/withdraw_modal.dart'
];

function getClassName(filename) {
    const name = path.basename(filename, '.dart');
    return name.split(/[_/-]/).map(word => {
        if (!word) return '';
        return word.charAt(0).toUpperCase() + word.slice(1);
    }).join('');
}

function generateTemplate(className, name) {
    return `import 'package:flutter/material.dart';

class ${className} extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${name}")),
      body: Center(child: Text("${name} Screen")),
    );
  }
}
`;
}

// Ensure base dir exists
if (!fs.existsSync(basePath)) {
    fs.mkdirSync(basePath, { recursive: true });
}

// Create directories
['screens', 'widgets', 'services', 'models'].forEach(dir => {
    fs.mkdirSync(path.join(libPath, dir), { recursive: true });
});

// Create main.dart
fs.writeFileSync(path.join(libPath, 'main.dart'), `import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile App',
      home: HomeScreen(),
    );
  }
}
`);

// Create screens
screens.forEach(file => {
    const className = getClassName(file);
    const name = className.replace(/Screen$/, ' Screen').trim();
    const filePath = path.join(libPath, 'screens', file);
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, generateTemplate(className, name));
});

// Create widgets
widgets.forEach(file => {
    const className = getClassName(file);
    const name = className;
    const filePath = path.join(libPath, 'widgets', file);
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, generateTemplate(className, name));
});

console.log('Flutter structure generated successfully in ' + basePath);
