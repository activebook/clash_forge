enum NotificationStatus { success, error, warning, info }

const String kSupportedUrlMessage =
    'Supported: https, vmess, vless, trojan, ss, ssr, hysteria2, tuic, anytls, local file.'
    '\nHttps url can be a subscription url. You can also drag the local config file to import it.';

const String kDnsResolveInfoMessage =
    'When enabled, server domains will be automatically resolved to IP addresses. '
    'This improves reliability when DNS is blocked but IP addresses are available. '
    '\n\nPS. This may increase processing time.'
    '\n\nYou should always use DNSPub, Tencent or CNNIC as your primary DNS choice.';
