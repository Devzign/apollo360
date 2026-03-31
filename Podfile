platform :ios, '16.0'
use_frameworks!

target 'Apollo360' do
  pod 'AzureCommunicationCalling', '2.15.0'
  pod 'AzureCommunicationUICalling', '~> 1.14'
end

post_install do |installer|
  identifiers = File.join(
    installer.sandbox.root.to_s,
    'AzureCommunicationCommon',
    'sdk',
    'communication',
    'AzureCommunicationCommon',
    'Source',
    'Identifiers.swift'
  )

  next unless File.exist?(identifiers)

  content = File.read(identifiers)
  original = '    let scope = segments[0] + ":" + segments[1] + ":"'
  patched = '    let scope = String(segments[0]) + ":" + String(segments[1]) + ":"'

  if content.include?(original)
    File.chmod(0644, identifiers)
    File.write(identifiers, content.sub(original, patched))
  end

  request_string = File.join(
    installer.sandbox.root.to_s,
    'AzureCore',
    'sdk',
    'core',
    'AzureCore',
    'Source',
    'Util',
    'RequestString.swift'
  )

  next unless File.exist?(request_string)

  request_string_content = File.read(request_string)
  request_string_original = '    static func == (lhs: RequestStringConvertible, rhs: RequestStringConvertible) -> Bool {'
  request_string_patched = '    static func == (lhs: Self, rhs: Self) -> Bool {'

  if request_string_content.include?(request_string_original)
    File.chmod(0644, request_string)
    File.write(request_string, request_string_content.sub(request_string_original, request_string_patched))
  end
end
