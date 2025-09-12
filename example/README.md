# Voice Call Core Example

This example demonstrates how to use the Voice Call Core plugin.

## Features Demonstrated

- Plugin initialization
- Recording manager creation
- Call recording start/stop
- Cloud storage integration
- Status monitoring

## Running the Example

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. The app will automatically initialize the Voice Call Core plugin
2. Use the "Start Recording" button to begin recording
3. Use the "Stop Recording" button to end recording
4. Monitor the status for feedback

## Configuration

The example uses a demo configuration with placeholder values. In a real app, you would:

1. Implement your own `SensitiveConfig` class
2. Use real API endpoints and credentials
3. Configure proper Firebase settings
4. Set up actual STUN/TURN servers