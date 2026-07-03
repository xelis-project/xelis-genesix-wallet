const supportedNewsLanguages = {
  'ar',
  'bg',
  'de',
  'en',
  'es',
  'fr',
  'hi',
  'it',
  'ja',
  'ko',
  'ms',
  'nl',
  'pl',
  'pt',
  'ru',
  'tr',
  'uk',
  'zh',
};

const allowedNewsTypes = {'update', 'security', 'network', 'announcement'};

const allowedNewsSeverities = {'info', 'warning', 'critical'};

const allowedNewsNetworks = {'mainnet', 'testnet', 'devnet', 'stagenet'};

const allowedNewsPlatforms = {
  'android',
  'ios',
  'windows',
  'linux',
  'macos',
  'web',
};

const allowedNewsLinkHosts = {
  'github.com',
  'xelis.io',
  'docs.xelis.io',
  'explorer.xelis.io',
  'testnet-explorer.xelis.io',
  'xelis-project.github.io',
};

bool isAllowedNewsUrl(Uri url) {
  if (url.scheme != 'https') {
    return false;
  }

  final host = url.host.toLowerCase();
  return allowedNewsLinkHosts.contains(host) || host.endsWith('.xelis.io');
}
