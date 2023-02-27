enum Languages {
  english,
  french;
}

Languages getLanguage(String language) {
  switch (language) {
    case 'english':
      return Languages.english;
    case 'french':
      return Languages.french;
    default:
      return Languages.english;
  }
}
