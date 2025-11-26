import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

const project = 'webdav_x';
const _path_ = '..';

/// 转换路径为 Windows 风格反斜杠
String toWindowsPath(String path) => path.replaceAll('/', r'\');

final start =
    '''<?xml version="1.0" encoding="windows-1252"?>
<>
  <InputFile>${toWindowsPath(p.join(_path_, 'build/windows/x64/runner/Release/$project.exe'))}</InputFile>
  <OutputFile>${toWindowsPath(p.join(_path_, '.release/${project}_windows_x64_boxed.exe'))}</OutputFile>
  <Files>
    <Enabled>True</Enabled>
    <DeleteExtractedOnExit>True</DeleteExtractedOnExit>
    <CompressFiles>True</CompressFiles>
    <Files>
      <File>
        <Type>3</Type>
        <Name>%DEFAULT FOLDER%</Name>
        <Action>0</Action>
        <OverwriteDateTime>False</OverwriteDateTime>
        <OverwriteAttributes>False</OverwriteAttributes>
        <HideFromDialogs>0</HideFromDialogs>
        <Files>''';

final end = '''
</Files>
      </File>
    </Files>
  </Files>
  <Registries>
    <Enabled>False</Enabled>
    <Registries>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Classes</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>User</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Machine</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Users</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Config</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
    </Registries>
  </Registries>
  <Packaging>
    <Enabled>False</Enabled>
  </Packaging>
  <Options>
    <ShareVirtualSystem>False</ShareVirtualSystem>
    <MapExecutableWithTemporaryFile>True</MapExecutableWithTemporaryFile>
    <TemporaryFileMask/>
    <AllowRunningOfVirtualExeFiles>True</AllowRunningOfVirtualExeFiles>
    <ProcessesOfAnyPlatforms>False</ProcessesOfAnyPlatforms>
  </Options>
  <Storage>
    <Files>
      <Enabled>False</Enabled>
      <Folder>%DEFAULT FOLDER%\\</Folder>
      <RandomFileNames>False</RandomFileNames>
      <EncryptContent>False</EncryptContent>
    </Files>
  </Storage>
</>
''';

String build(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return '';

  final buffer = StringBuffer();

  for (var entity in dir.listSync()) {
    final name = p.basename(entity.path);

    if (entity is File && name != '$project.exe') {
      buffer.writeln('''<File>
            <Type>2</Type>
            <Name>$name</Name>
            <File>${toWindowsPath(entity.path)}</File>
            <ActiveX>False</ActiveX>
            <ActiveXInstall>False</ActiveXInstall>
            <Action>0</Action>
            <OverwriteDateTime>False</OverwriteDateTime>
            <OverwriteAttributes>False</OverwriteAttributes>
            <PassCommandLine>False</PassCommandLine>
            <HideFromDialogs>0</HideFromDialogs>
        </File>''');
    } else if (entity is Directory) {
      buffer.writeln('''<File>
            <Type>3</Type>
            <Name>$name</Name>
            <Action>0</Action>
            <OverwriteDateTime>False</OverwriteDateTime>
            <OverwriteAttributes>False</OverwriteAttributes>
            <HideFromDialogs>0</HideFromDialogs>
            <Files>${build(entity.path)}</Files>
        </File>''');
    }
  }

  return buffer.toString();
}

void main() {
  final releasePath = p.join(_path_, 'build/windows/x64/runner/Release/');
  final result = build(releasePath);

  File(
    'pack.evb',
  ).writeAsStringSync(start + result + end, encoding: Utf8Codec());
  print('pack.evb generated successfully!');
}
