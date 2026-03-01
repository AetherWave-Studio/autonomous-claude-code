# Discord Protocol - Autonomous Mode

Activate autonomous coding mode with Discord notifications enabled.

## System Prompt

**FIRST:** Enable Discord notifications by running this bash command:
```bash
touch ~/.claude/notifications-enabled
```

**THEN:** Proceed with autonomous work following the Discord Notification Protocol from CLAUDE.md:

- Write structured STATUS updates at each stop point
- Include: what was done, current state, next step, session ID, modified files, test command
- Stop only for strategic decisions or blockers
- Work autonomously on implementation details

Your final message when stopping becomes the Discord notification sent to the developer's phone.

## What This Command Does

1. Enables Discord webhook notifications (creates toggle file)
2. Loads STATUS protocol formatting from CLAUDE.md
3. Activates autonomous mode
4. Configures for mobile coordination

## Usage
```
/discord-protocol "Analyze the authentication system and create security audit"
```

After running this command, Discord notifications will fire when you stop. The developer can coordinate from their phone.

## To Disable Later

Use `/end-protocol` when finished to turn off notifications.
