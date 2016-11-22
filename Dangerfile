# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 300

# Warn pod spec changes
warn("KDEAudioPlayer.podspec changed") if git.modified_files.include?("KDEAudioPlayer.podspec")

# Added (or removed) library files need to be added (or removed) from the
# Carthage Xcode project to avoid breaking things for our Carthage users.
added_swift_library_files = git.added_files.grep(/AudioPlayer\/AudioPlayer.*\.swift/).empty?
deleted_swift_library_files = git.deleted_files.grep(/AudioPlayer\/AudioPlayer.*\.swift/).empty?
modified_carthage_xcode_project = !(git.deleted_files.grep(/AudioPlayer\/AudioPlayer\.xcodeproj/).empty?)
if (added_swift_library_files || deleted_swift_library_files) && modified_carthage_xcode_project
  fail("Added or removed library files require the Carthage Xcode project to be updated.")
end

# Run SwiftLint
swiftlint.lint_files

# Asserts the test coverage meets the threshold
xcov.report(scheme: 'AudioPlayer iOS', project: 'AudioPlayer/AudioPlayer.xcodeproj', minimum_coverage_percentage: 50)
