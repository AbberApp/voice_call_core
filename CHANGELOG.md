# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release of Voice Call Core
- Call recording functionality with cloud storage integration
- Secure configuration system with no hardcoded sensitive data
- Firebase Storage integration for automatic recording uploads
- WebRTC quality configuration presets (high quality, balanced, low bandwidth)
- Connection statistics and quality monitoring
- Environment-based configuration support
- Comprehensive example application
- Full API documentation

### Security
- No hardcoded URLs, credentials, or sensitive data
- Configuration injection required for all sensitive values
- Environment variable support for easy deployment
- Secure by default design

### Features
- **Call Recording**: High-quality audio recording with configurable settings
- **Cloud Storage**: Automatic upload to Firebase Storage with metadata
- **Quality Control**: Configurable audio quality presets
- **State Management**: Comprehensive state tracking for recording and uploads
- **Error Handling**: Robust error handling with detailed error messages
- **Performance**: Optimized for production use with minimal overhead

### Models
- `CallEntity`: Complete call information model
- `CallState`: Comprehensive call state management
- `ConnectionStats`: Real-time connection quality metrics
- `CloudUploadResult`: Upload result with detailed information
- `CloudRecordingInfo`: Cloud recording metadata

### Configuration
- `SensitiveConfig`: Abstract interface for sensitive configuration
- `DefaultSensitiveConfig`: Default implementation that requires configuration
- `EnvironmentConfig`: Environment variable-based configuration
- `CoreSDKConfig`: Main SDK configuration
- `WebRTCQualityConfig`: Audio quality presets
- `CallRecordingConfig`: Recording configuration options

### Managers
- `CallRecordingManager`: Complete recording lifecycle management
- `CloudStorageManager`: Firebase Storage operations

### Documentation
- Comprehensive README with examples
- API reference documentation
- Security guidelines
- Configuration examples
- Example application

## [Unreleased]

### Planned
- WebRTC call management (voice calls)
- CallKit integration
- Performance monitoring
- Audio route management
- Call duration tracking
- Advanced error recovery