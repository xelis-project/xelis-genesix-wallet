import 'dart:io';

const _agentsDocument = 'AGENTS.md';
const _defaultProjectDocumentLimit = 32 * 1024;
const _canonicalSkillRoot = '.agents/skills';
const _skillMirrorRoots = <String>['.claude/skills', '.github/skills'];
const _agentProfileRoots = <String, String>{
  '.codex/agents': '.toml',
  '.claude/agents': '.md',
  '.github/agents': '.agent.md',
};
const _codexAgentConfigurations = <String, Map<String, String>>{
  'codebase-explorer': {
    'model': 'gpt-5.6-terra',
    'model_reasoning_effort': 'medium',
    'sandbox_mode': 'read-only',
  },
  'quick-implementer': {
    'model': 'gpt-5.6-terra',
    'model_reasoning_effort': 'medium',
  },
  'implementation-worker': {
    'model': 'gpt-5.6-sol',
    'model_reasoning_effort': 'high',
  },
  'code-reviewer': {
    'model': 'gpt-5.6-sol',
    'model_reasoning_effort': 'high',
    'sandbox_mode': 'read-only',
  },
  'security-reviewer': {
    'model': 'gpt-5.6-sol',
    'model_reasoning_effort': 'high',
    'sandbox_mode': 'read-only',
  },
  'ui-ux-designer': {
    'model': 'gpt-5.6-sol',
    'model_reasoning_effort': 'high',
    'sandbox_mode': 'read-only',
  },
  'validation-runner': {
    'model': 'gpt-5.6-terra',
    'model_reasoning_effort': 'medium',
  },
  'guidelines-maintainer': {
    'model': 'gpt-5.6-terra',
    'model_reasoning_effort': 'medium',
  },
};
const _requiredGuidancePaths = <String>[
  _agentsDocument,
  'CLAUDE.md',
  '.github/copilot-instructions.md',
  '.agents/knowledge/PROJECT_NOTES.md',
];

void main() {
  final failures = <String>[];

  _validateRequiredPaths(failures);
  final skillNames = _validateSkillMirrors(failures);
  final agentNames = _validateAgentProfiles(failures);
  _validateAgentsDocument(skillNames, agentNames, failures);
  _validateAdapters(failures);
  _validateStaleReferences(failures);

  if (failures.isNotEmpty) {
    stderr.writeln('AI guideline validation failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Validated ${skillNames.length} skill(s), '
    '${agentNames.length} agent profile(s), and guidance entrypoints.',
  );
}

void _validateRequiredPaths(List<String> failures) {
  for (final path in _requiredGuidancePaths) {
    if (!FileSystemEntity.isFileSync(path)) {
      failures.add('Missing required guidance file: $path');
    }
  }
}

Set<String> _validateSkillMirrors(List<String> failures) {
  final canonicalNames = _directoryNames(_canonicalSkillRoot, failures);

  for (final skillName in canonicalNames) {
    final canonicalPath = '$_canonicalSkillRoot/$skillName/SKILL.md';
    final canonicalFile = File(canonicalPath);
    if (!canonicalFile.existsSync()) {
      failures.add('Missing canonical skill file: $canonicalPath');
      continue;
    }
    _validateDeclaredSkillName(canonicalFile, skillName, failures);
  }

  for (final mirrorRoot in _skillMirrorRoots) {
    final mirrorNames = _directoryNames(mirrorRoot, failures);
    _compareNameSets(
      expected: canonicalNames,
      actual: mirrorNames,
      label: 'skills in $mirrorRoot',
      failures: failures,
    );

    for (final skillName in canonicalNames.intersection(mirrorNames)) {
      final canonicalPath = '$_canonicalSkillRoot/$skillName/SKILL.md';
      final mirrorPath = '$mirrorRoot/$skillName/SKILL.md';
      final canonicalFile = File(canonicalPath);
      final mirrorFile = File(mirrorPath);

      if (!canonicalFile.existsSync()) {
        continue;
      }
      if (!mirrorFile.existsSync()) {
        failures.add('Missing mirrored skill file: $mirrorPath');
        continue;
      }
      if (!_sameBytes(
        canonicalFile.readAsBytesSync(),
        mirrorFile.readAsBytesSync(),
      )) {
        failures.add('Skill mirror differs from canonical source: $mirrorPath');
      }
    }
  }

  return canonicalNames;
}

void _validateDeclaredSkillName(
  File file,
  String expectedName,
  List<String> failures,
) {
  final content = file.readAsStringSync();
  final declaredName = _frontmatterValue(content, 'name');

  if (declaredName == null) {
    failures.add('Missing skill name declaration: ${file.path}');
  } else if (declaredName != expectedName) {
    failures.add(
      'Skill name "$declaredName" does not match directory name '
      '"$expectedName": ${file.path}',
    );
  }
}

Set<String> _validateAgentProfiles(List<String> failures) {
  final namesByRoot = <String, Set<String>>{};

  for (final entry in _agentProfileRoots.entries) {
    final root = Directory(entry.key);
    if (!root.existsSync()) {
      failures.add('Missing agent profile directory: ${entry.key}');
      namesByRoot[entry.key] = <String>{};
      continue;
    }

    final names = <String>{};
    for (final entity in root.listSync()) {
      if (entity is! File || !entity.path.endsWith(entry.value)) {
        continue;
      }

      final fileName = _basename(entity.path);
      final profileName = fileName.substring(
        0,
        fileName.length - entry.value.length,
      );
      names.add(profileName);
      _validateDeclaredAgentName(entity, profileName, failures);
      if (entry.key == '.codex/agents') {
        _validateCodexAgentConfiguration(entity, profileName, failures);
      }
    }
    namesByRoot[entry.key] = names;
  }

  final referenceNames =
      namesByRoot[_agentProfileRoots.keys.first] ?? <String>{};
  _compareNameSets(
    expected: _codexAgentConfigurations.keys.toSet(),
    actual: referenceNames,
    label: 'configured Codex agent profiles',
    failures: failures,
  );
  for (final entry in namesByRoot.entries.skip(1)) {
    _compareNameSets(
      expected: referenceNames,
      actual: entry.value,
      label: 'agent profiles in ${entry.key}',
      failures: failures,
    );
  }

  return referenceNames;
}

void _validateCodexAgentConfiguration(
  File file,
  String profileName,
  List<String> failures,
) {
  final content = file.readAsStringSync();
  final expected = _codexAgentConfigurations[profileName];
  if (expected == null) {
    failures.add('Missing expected Codex configuration: $profileName');
    return;
  }

  for (final entry in expected.entries) {
    final actualValue = _tomlStringValue(content, entry.key);
    if (actualValue != entry.value) {
      failures.add(
        'Invalid Codex ${entry.key} for $profileName: expected '
        '"${entry.value}", found "${actualValue ?? 'missing'}"',
      );
    }
  }

  if (!expected.containsKey('sandbox_mode') &&
      _tomlStringValue(content, 'sandbox_mode') != null) {
    failures.add('Unexpected Codex sandbox_mode: ${file.path}');
  }
}

void _validateDeclaredAgentName(
  File file,
  String expectedName,
  List<String> failures,
) {
  final content = file.readAsStringSync();
  final isToml = file.path.endsWith('.toml');
  final declaredName = isToml
      ? RegExp(
          r'^name\s*=\s*"([^"]+)"\s*$',
          multiLine: true,
        ).firstMatch(content)?.group(1)
      : _frontmatterValue(content, 'name');

  if (declaredName == null) {
    failures.add('Missing agent name declaration: ${file.path}');
  } else if (declaredName != expectedName) {
    failures.add(
      'Agent name "$declaredName" does not match file name '
      '"$expectedName": ${file.path}',
    );
  }
}

void _validateAgentsDocument(
  Set<String> skillNames,
  Set<String> agentNames,
  List<String> failures,
) {
  final file = File(_agentsDocument);
  if (!file.existsSync()) {
    return;
  }

  final content = file.readAsStringSync();
  final size = file.lengthSync();
  if (size > _defaultProjectDocumentLimit) {
    failures.add(
      '$_agentsDocument is $size bytes, above the default Codex project '
      'document limit of $_defaultProjectDocumentLimit bytes',
    );
  }

  for (final skillName in skillNames) {
    if (!content.contains('`$skillName`')) {
      failures.add('Skill is not listed in $_agentsDocument: $skillName');
    }
  }
  for (final agentName in agentNames) {
    if (!content.contains('`$agentName`')) {
      failures.add(
        'Agent profile is not listed in $_agentsDocument: $agentName',
      );
    }
  }
}

void _validateAdapters(List<String> failures) {
  for (final path in const ['CLAUDE.md', '.github/copilot-instructions.md']) {
    final file = File(path);
    if (file.existsSync() &&
        !file.readAsStringSync().contains(_agentsDocument)) {
      failures.add('Tool adapter does not reference $_agentsDocument: $path');
    }
  }
}

void _validateStaleReferences(List<String> failures) {
  final files = <File>[
    for (final path in _requiredGuidancePaths)
      if (File(path).existsSync()) File(path),
    ..._filesUnder('.agents/skills', '.md'),
    ..._filesUnder('.codex/agents', '.toml'),
    ..._filesUnder('.claude/agents', '.md'),
    ..._filesUnder('.github/agents', '.md'),
  ];

  for (final file in files) {
    if (file.readAsStringSync().contains('docs/ai/')) {
      failures.add('Stale docs/ai reference: ${file.path}');
    }
  }
}

Set<String> _directoryNames(String path, List<String> failures) {
  final directory = Directory(path);
  if (!directory.existsSync()) {
    failures.add('Missing directory: $path');
    return <String>{};
  }

  return {
    for (final entity in directory.listSync())
      if (entity is Directory) _basename(entity.path),
  };
}

List<File> _filesUnder(String path, String suffix) {
  final directory = Directory(path);
  if (!directory.existsSync()) {
    return const [];
  }

  return [
    for (final entity in directory.listSync(recursive: true))
      if (entity is File && entity.path.endsWith(suffix)) entity,
  ];
}

void _compareNameSets({
  required Set<String> expected,
  required Set<String> actual,
  required String label,
  required List<String> failures,
}) {
  final missing = expected.difference(actual).toList()..sort();
  final extra = actual.difference(expected).toList()..sort();
  if (missing.isNotEmpty) {
    failures.add('Missing $label: ${missing.join(', ')}');
  }
  if (extra.isNotEmpty) {
    failures.add('Unexpected $label: ${extra.join(', ')}');
  }
}

bool _sameBytes(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}

String? _frontmatterValue(String content, String key) {
  final lines = content.split(RegExp(r'\r?\n'));
  if (lines.isEmpty || lines.first.trim() != '---') {
    return null;
  }

  final closingIndex = lines.indexWhere((line) => line.trim() == '---', 1);
  if (closingIndex < 0) {
    return null;
  }

  final pattern = RegExp('^${RegExp.escape(key)}:\\s*(\\S.*?)\\s*\$');
  for (final line in lines.sublist(1, closingIndex)) {
    final value = pattern.firstMatch(line)?.group(1);
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _tomlStringValue(String content, String key) {
  return RegExp(
    '^${RegExp.escape(key)}\\s*=\\s*"([^"]+)"\\s*\$',
    multiLine: true,
  ).firstMatch(content)?.group(1);
}
