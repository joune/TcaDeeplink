This is a very basic test case to reproduce an issue/question I have about the usage of TCA.

# Scenario

Open the app, click the button.

It opens a feature view for the "button" state, and displays "button" inputs from a publisher.

After a few seconds, at timer im the parent reducer updates the destination to another feature view -emulating a deeplink from a notification.

The expected behaviour would be for a new feature view -and a new publisher- to be instanciated, instead the view is reused, its reducer state is forced to the new value, but the underlying publisher is not invalidated or recreated; it continues to publish events for the previous state, thus creaing an inconsistent view.


# Update

The solution for this case is to add `.id(viewStore.id)` to the feature view, which must be set AFTER the `.task`. This restarts the view lifecycle and the task is called again.
