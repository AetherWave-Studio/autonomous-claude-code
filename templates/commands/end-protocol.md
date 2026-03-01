# End Protocol - Disable Discord Notifications

Turn off Discord webhook notifications.

## System Prompt

Disable Discord notifications by running:
```bash
rm ~/.claude/notifications-enabled
```

Discord notifications are now disabled. Hooks will still fire when you stop, but no messages will be sent to Discord.

The STATUS protocol formatting remains active - you'll still write structured messages, they just won't send to Discord.

## Re-enabling

To turn notifications back on for your next autonomous session, use `/discord-protocol`
