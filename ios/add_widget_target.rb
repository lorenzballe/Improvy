#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds the WidgetKit extension to Runner.xcodeproj.
#
# Why this exists: a widget extension is a separate build target, and targets
# live in project.pbxproj — a file that must not be hand-edited. The old
# instructions told the developer to add it in Xcode, which never happened
# because this app is built on Codemagic and there is no Mac in the loop. So
# the project change is scripted instead: run it once, commit the result.
#
#   gem install xcodeproj && ruby ios/add_widget_target.rb
#
# Idempotent — running it again on a project that already has the target exits
# without touching anything.

require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
PROJECT = File.join(ROOT, 'ios', 'Runner.xcodeproj')
TARGET_NAME = 'ImprovyWidget'
BUNDLE_ID = 'com.improvy.app.ImprovyWidget'
GROUP_DIR = 'ImprovyWidget'
SOURCES = %w[ImprovyKit.swift ImprovyWidgets.swift].freeze

project = Xcodeproj::Project.open(PROJECT)
app = project.targets.find { |t| t.name == 'Runner' } or abort 'No Runner target'

if project.targets.any? { |t| t.name == TARGET_NAME }
  puts "#{TARGET_NAME} already present — nothing to do."
  exit 0
end

# ── The extension target ─────────────────────────────────────────────────────
ext = project.new_target(
  :app_extension, TARGET_NAME, :ios, '16.0', nil, :swift
)

group = project.main_group.find_subpath(GROUP_DIR, true)
group.set_source_tree('SOURCE_ROOT')
group.set_path(GROUP_DIR)

SOURCES.each do |name|
  ref = group.files.find { |f| f.path == name } || group.new_reference(name)
  ext.add_file_references([ref])
end
%w[Info.plist ImprovyWidget.entitlements].each do |name|
  group.new_reference(name) unless group.files.any? { |f| f.path == name }
end

ext.build_configurations.each do |config|
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => BUNDLE_ID,
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'INFOPLIST_FILE' => "#{GROUP_DIR}/Info.plist",
    'CODE_SIGN_ENTITLEMENTS' => "#{GROUP_DIR}/ImprovyWidget.entitlements",
    'CODE_SIGN_STYLE' => 'Automatic',
    'IPHONEOS_DEPLOYMENT_TARGET' => '16.0',
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SKIP_INSTALL' => 'YES',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    # An extension is never the thing being launched; without this Xcode warns
    # on every build about a missing @UIApplicationMain.
    'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES' => 'NO',
    'SWIFT_EMIT_LOC_STRINGS' => 'YES'
  )
end

# ── Embed it in the app ──────────────────────────────────────────────────────
# The extension has to be copied into Runner.app/PlugIns and built first.
app.add_dependency(ext)
embed = app.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
    phase.name == 'Embed App Extensions'
end
unless embed
  embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed.name = 'Embed App Extensions'
  embed.symbol_dst_subfolder_spec = :plug_ins
  # Where Xcode itself puts it: after Resources, before the Flutter phases that
  # walk the finished bundle.
  after = app.build_phases.index(app.resources_build_phase) || app.build_phases.size - 1
  app.build_phases.insert(after + 1, embed)
end
build_file = embed.add_file_reference(ext.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# ── The app's own side of the App Group ──────────────────────────────────────
# The entitlements file has been in the repo all along, but nothing pointed at
# it, so the app never had the shared container the widgets read from.
app.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

project.save
puts "Added #{TARGET_NAME} (#{BUNDLE_ID}) and embedded it in Runner."
