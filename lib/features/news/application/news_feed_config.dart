const newsIndexUrlEnvironmentKey = 'GENESIX_NEWS_INDEX_URL';

const defaultNewsIndexUrl =
    'https://xelis-project.github.io/xelis-genesix-wallet/news/index.json';

const resolvedNewsIndexUrl = String.fromEnvironment(
  newsIndexUrlEnvironmentKey,
  defaultValue: defaultNewsIndexUrl,
);

const bundledNewsFeedAssetPath = 'news/index.json';

const newsFeedRefreshInterval = Duration(hours: 6);

const visibleNewsItemLimit = 3;
