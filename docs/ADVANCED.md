# Advanced Patterns
### Multi-agent coordination, supervisor layers, and scaling

This guide covers advanced autonomous coding patterns beyond single-agent workflows.

---

## Multi-Agent Coordination

Running multiple Claude Code instances simultaneously for parallel development.

### Use Cases

- **Feature parallelism:** Frontend + Backend teams
- **Component isolation:** Video editor + DAW + Image generator
- **Analysis + Implementation:** One agent analyzes, another implements
- **Different languages/stacks:** Python service + Node API + React frontend

### Basic Multi-Agent Setup

**Terminal 1 - Frontend Work:**
```bash
cd ~/project/frontend
SESSION_ID="frontend-$(date +%s)" claude code --dangerously-skip-permissions
```

**Terminal 2 - Backend Work:**
```bash
cd ~/project/backend  
SESSION_ID="backend-$(date +%s)" claude code --dangerously-skip-permissions
```

**Both send notifications to same Discord channel.** You coordinate from your phone.

### Color-Coded Notifications

Modify `discord-notify.sh` to color-code by session:

```bash
# Add near the top of the script
case "$SESSION_ID" in
  frontend*)
    COLOR="3447003"  # Blue for frontend
    ;;
  backend*)
    COLOR="15105570"  # Orange for backend
    ;;
  database*)
    COLOR="10181046"  # Purple for database
    ;;
  *)
    COLOR="$COLOR_STOP"  # Default
    ;;
esac
```

Now notifications are visually distinct!

### Separate Discord Threads

Create a forum channel in Discord, then use thread-specific webhooks:

**Frontend notifications:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/ID/TOKEN?thread_id=FRONTEND_THREAD_ID"
```

**Backend notifications:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/ID/TOKEN?thread_id=BACKEND_THREAD_ID"
```

### Session Naming Convention

Use hierarchical session IDs:

```
{project}-{component}-{feature}-{timestamp}

Examples:
- aetherwave-frontend-waveforms-1234567890
- aetherwave-backend-auth-1234567891
- aetherwave-database-migration-1234567892
```

### Coordination Strategy

**Mobile workflow:**

1. Start both agents with clear, non-overlapping tasks
2. Monitor notifications on phone
3. When conflicts arise (both need same file), pause one:
   - "Pause work and wait for backend team to finish auth.ts"
4. Resume when clear:
   - "Backend finished. Continue with your task."

**Example coordination:**

```
11:23 PM - 🔵 Frontend: "Need API endpoint structure for /api/waveforms"
11:24 PM - You: "Backend, define that endpoint"
11:47 PM - 🟧 Backend: "Endpoint defined, documented in api-docs.md"
11:48 PM - You: "Frontend, implement using endpoint from api-docs.md"
12:15 AM - 🔵 Frontend: "Waveform display implemented, working with endpoint"
```

---

## Supervisor Pattern

Add a third Claude instance that monitors Discord and handles routine decisions.

### Architecture

```
Worker 1 (Frontend)  ──┐
                        ├─→ Discord Thread ←─→ Supervisor Claude
Worker 2 (Backend)  ───┘                              ↓
                                                  (Escalates critical decisions)
                                                       ↓
                                                   Human (Phone)
```

### Setup

**Terminal 3 - Supervisor:**
```bash
claude code
```

Then give it this role:

```
You are a supervisor coordinating autonomous development work.

Monitor Discord thread: [THREAD_URL]

Your responsibilities:
1. Read STATUS updates from worker agents
2. Handle routine decisions (approach A vs B, both valid)
3. Escalate critical decisions to human (architecture changes, breaking changes)
4. Track progress across all workers
5. Identify conflicts (two workers editing same file)

Decision framework:
- Implementation details → Decide autonomously
- Strategic choices with clear tradeoffs → Decide autonomously
- Architecture changes → Escalate
- Breaking changes → Escalate
- Security implications → Escalate

When workers ask for input:
- If routine: Respond with decision and reasoning
- If critical: Notify human and wait

Provide hourly summary of all worker progress.
```

### Supervisor Capabilities

**What supervisors handle well:**
- Approach selection (Canvas vs WebGL, both work)
- Priority ordering (fix bug A before bug B)
- Resource allocation (optimize this component first)
- Conflict resolution (merge strategy for concurrent edits)
- Progress tracking (summarize what's done)

**What supervisors escalate:**
- Novel architectural decisions
- API design changes
- Database schema modifications
- Security-sensitive code
- Major refactorings

### Result

With supervisor: **80-90% fewer notifications to your phone.**

You only see:
- Critical decisions
- Blockers that supervisor can't resolve
- Hourly progress summaries

---

## Scaling Patterns

### Sequential Handoffs

Complete one phase before starting next:

**Phase 1 - Analysis (Opus 1):**
```bash
claude code
"Analyze video editor codebase. Document architecture, find bugs, propose features. Create comprehensive report in docs/analysis.md"
```

**Wait for completion.**

**Phase 2 - Implementation (Opus 2):**
```bash
claude code
"Read docs/analysis.md. Implement the top 3 quick wins identified. Test thoroughly."
```

**Phase 3 - Review (Opus 3):**
```bash
claude code  
"Review the implementations from Opus 2. Verify tests, check edge cases, suggest improvements."
```

### Parallel Specialization

Assign agents to specific domains:

**Agent A - Performance:**
- Profile slow operations
- Optimize bottlenecks
- Benchmark improvements

**Agent B - Testing:**
- Write missing tests
- Increase coverage
- Add edge case tests

**Agent C - Documentation:**
- Document functions
- Create user guides
- Update API docs

**Agent D - Refactoring:**
- Extract duplicated code
- Improve naming
- Simplify complex functions

All run simultaneously, different codebases areas.

### Time-Based Coordination

Leverage time zones for 24-hour development:

**9 PM (Your evening):**
Start 3 agents on independent features

**Sleep 8 hours**

**5 AM (Wake up):**
- Review 3 completed features
- Merge if tests pass
- Start 3 new agents on next features

**Result:** 6 features implemented per day with 8 hours sleep.

---

## Advanced Protocol Patterns

### Context-Aware Protocols

Different protocols for different project types:

**Web Development Protocol:**
```markdown
## Web Dev Additions to STATUS

- Deployed: [URL if deployed to staging]
- Browser tested: [Chrome/Firefox/Safari - which ones]
- Responsive: [Mobile/Tablet - tested or not]
- Accessibility: [WCAG compliance notes]
```

**Data Science Protocol:**
```markdown
## Data Science Additions to STATUS

- Dataset: [rows × columns, source]
- Model performance: [accuracy/precision/recall]
- Visualizations: [saved to /outputs/plots/]
- Reproducibility: [random seed, requirements.txt updated]
```

**Infrastructure Protocol:**
```markdown
## DevOps Additions to STATUS

- Environment: [dev/staging/prod]
- Rollback plan: [how to revert if needed]
- Monitoring: [metrics/alerts configured]
- Cost impact: [estimated $/month change]
```

### Progressive Enhancement

Start simple, add complexity:

**Week 1:** Basic notifications
**Week 2:** Add color coding
**Week 3:** Add supervisor
**Week 4:** Add project-specific protocols
**Week 5:** Add analytics/dashboards

Don't try to implement everything at once.

---

## Monitoring & Analytics

### Track Productivity

Add logging to your workflow:

**track-autonomous.sh:**
```bash
#!/bin/bash
# Log autonomous work sessions

LOG_FILE="$HOME/.autonomous-analytics.csv"

# Initialize if doesn't exist
if [ ! -f "$LOG_FILE" ]; then
  echo "timestamp,session_id,task,duration_mins,status" > "$LOG_FILE"
fi

# Usage: track-autonomous.sh SESSION_ID "Task description" DURATION STATUS
echo "$(date +%s),$1,$2,$3,$4" >> "$LOG_FILE"
```

**Usage:**
```bash
# When starting
START=$(date +%s)
claude code --dangerously-skip-permissions

# When finished (manually or via hook)
END=$(date +%s)
DURATION=$(( ($END - $START) / 60 ))
./track-autonomous.sh "auth-001" "Implement JWT auth" "$DURATION" "COMPLETED"
```

**Analysis:**
```bash
# Total autonomous minutes this month
cat ~/.autonomous-analytics.csv | grep "2026-02" | awk -F, '{sum+=$4} END {print sum " minutes"}'

# Success rate
cat ~/.autonomous-analytics.csv | grep "COMPLETED" | wc -l
cat ~/.autonomous-analytics.csv | wc -l
```

### Dashboard (Optional)

Build a simple web dashboard:

**analytics.html:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Autonomous Analytics</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
  <h1>Autonomous Development Stats</h1>
  <canvas id="productivityChart"></canvas>
  <script>
    // Load ~/.autonomous-analytics.csv
    // Parse and display
    // Show:
    // - Total hours autonomous work
    // - Success rate by task type
    // - Average session duration
    // - Productivity trends
  </script>
</body>
</html>
```

---

## Team Collaboration

### Shared Autonomous Workspace

Multiple developers using the same autonomous system:

**Setup:**
- Shared Discord server
- Separate channels per developer
- Team-wide "autonomous-feed" channel
- Shared protocol repository

**Workflow:**
```
Dev A: Starts agent on feature X
       → Posts to #dev-a-autonomous
       
Dev B: Starts agent on feature Y
       → Posts to #dev-b-autonomous

Both: Cross-posted summaries to #autonomous-feed

Result: Team visibility into all autonomous work
```

### Handoff Protocol

When passing autonomous work between team members:

**Handoff STATUS:**
```markdown
**STATUS: HANDOFF**

- What was done: [completed work]
- Current state: [what works, what doesn't]
- Next developer should: [clear next steps]
- Context files: [docs/handoff-notes.md]
- Branch: [feature/autonomous-work-123]
- Tests: [npm test - 15/15 passing]
```

---

## Best Practices at Scale

### 1. Start Conservative

- Begin with 1 agent
- Add 2nd when comfortable
- Add supervisor when coordinating 3+
- Scale gradually

### 2. Clear Boundaries

Each agent should have:
- Specific directory/module ownership
- Non-overlapping file sets
- Clear deliverables
- Independent test suites

### 3. Regular Checkpoints

Don't let agents run for days unsupervised:
- 4-8 hour work sessions max
- Human review at milestones
- Merge frequently (avoid mega-branches)

### 4. Version Control Discipline

- One branch per agent
- Atomic commits
- Clear commit messages
- Easy to rollback

### 5. Test Coverage Required

Autonomous work must have tests:
- Existing tests pass
- New tests for new features
- Coverage maintained or improved
- No untested code merged

---

## Advanced Debugging

### Hook Logging

Enhanced hook script with detailed logging:

```bash
#!/bin/bash
# Add to discord-notify.sh

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/hook-$(date +%Y%m%d).log"

# Log everything
{
  echo "=== Hook fired at $(date) ==="
  echo "Event: $EVENT_NAME"
  echo "Session: $SESSION_ID"
  echo "Message: $LAST_MESSAGE"
  echo "---"
} >> "$LOG_FILE"

# Normal notification code...

# Log result
echo "Notification sent successfully" >> "$LOG_FILE"
```

### Notification History

Track all notifications:

```bash
#!/bin/bash
# notification-history.sh
# Searches hook logs for specific sessions

SESSION=$1
grep "Session: $SESSION" ~/.claude/logs/*.log
```

### Performance Profiling

Track how long each autonomous session takes:

```bash
# Add to CLAUDE.md
## Performance Tracking

Include in COMPLETED status:
- Started: [timestamp when work began]
- Completed: [timestamp when finished]
- Duration: [total time in minutes]
- Efficiency: [lines changed per hour]
```

---

## Experimental Patterns

### Meta-Agent

An agent that creates other agents:

```
Meta-Agent: "Analyze this project. Create 5 autonomous tasks for other agents."

Output:
1. Task for Agent A: Performance optimization
2. Task for Agent B: Test coverage
3. Task for Agent C: Documentation
4. Task for Agent D: Refactoring
5. Task for Agent E: Security audit

Then: Start 5 agents with those tasks
```

### Self-Improving Protocols

Agents that update their own CLAUDE.md:

```
Task: "After completing work, analyze what worked well in your STATUS 
messages and what didn't. Propose improvements to CLAUDE.md protocol."
```

### Autonomous Code Review

One agent writes, another reviews:

**Agent 1:** Implements feature
**Agent 2:** Reviews PR, requests changes
**Agent 1:** Addresses feedback
**Repeat until Agent 2 approves**

Human only steps in for disputes.

---

## Limits & Warnings

### What Not to Automate

- Security-critical code without extensive review
- Payment processing without testing
- Database migrations in production
- Customer-facing UI without user testing
- Legal/compliance-related code

### Cognitive Load Management

Too many agents = too many notifications.

**Practical limits:**
- Solo developer: 2-3 active agents
- With supervisor: 5-7 active agents
- Team setting: 10-15 active agents total

Beyond this, you're just managing agents, not developing.

### When to Stop

Signs autonomous work isn't helping:
- Spending more time managing than coding
- AI generates more bugs than features
- Review process takes longer than writing
- Team confusion about what's autonomous vs manual
- Quality degradation

**Solution:** Scale back, refine protocols, improve testing.

---

## Future Possibilities

Ideas for where this could go:

**Integration with CI/CD:**
- Agent pushes code
- CI runs tests
- If tests pass, agent continues
- If tests fail, agent fixes

**Natural Language PRs:**
- Agent creates PR with natural language description
- Automated reviewers comment
- Agent addresses feedback
- Auto-merge when approved

**Autonomous Debugging:**
- Production error occurs
- Agent analyzes logs
- Creates fix
- Submits PR with explanation

**Learning System:**
- Track success/failure rates by task type
- Agents learn which patterns work
- Protocol evolves based on outcomes

---

## Conclusion

Start with one agent. Master that workflow.

Add complexity when you understand the basics.

The goal isn't to automate everything - it's to amplify human capability.

**You're the conductor. The agents are the orchestra.**

---

*Advanced patterns require advanced discipline. Scale thoughtfully.*
