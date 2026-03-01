# Discord Notification Protocol

## Critical: Your Final Message = The Notification

When you stop, your last message becomes the Discord notification sent to the developer's phone.

Write it intentionally in this format:

**STATUS: [COMPLETED | BLOCKED | NEEDS INPUT | ERROR]**

- What was done: [Concrete summary of work completed]
- Current state: [What's working, what's tested, current status]
- Next step: [What's needed to continue or what should happen next]
- Session: [Unique session identifier for tracking]
- Modified: [Key files that were changed]
- Test: [Command or procedure to verify the work]

---

## Examples

### STATUS: COMPLETED

**STATUS: COMPLETED**

- What was done: Authentication middleware implemented with JWT tokens
- Current state: Middleware working, 8 tests passing, integrated with login endpoint
- Next step: Ready for code review and security audit
- Session: auth-middleware-001
- Modified: auth.ts, middleware.ts, auth.test.ts
- Test: npm test && curl -H "Authorization: Bearer TOKEN" http://localhost:5000/api/protected

---

### STATUS: NEEDS INPUT

**STATUS: NEEDS INPUT**

- What was done: Database schema designed for user preferences, two approaches identified
- Current state: Approach A uses JSON field (flexible), Approach B uses normalized tables (queryable)
- Next step: Decision needed on schema approach - see tradeoff analysis in schema-design.md
- Session: user-prefs-schema-002
- Modified: schema-design.md (design doc only, no code yet)
- Test: N/A (awaiting decision before implementation)

---

### STATUS: BLOCKED

**STATUS: BLOCKED**

- What was done: Attempted to integrate payment API, encountered authentication errors
- Current state: API returns 401 Unauthorized despite using documented auth flow
- Next step: Need to verify API credentials or check for environment-specific configuration
- Session: payment-integration-003
- Modified: payment-service.ts (changes not working, may need to revert)
- Test: Currently failing - see error logs in payment-integration-003.log

---

### STATUS: ERROR

**STATUS: ERROR**

- What was done: Ran full test suite after refactoring database layer
- Current state: 23 tests failing, all related to transaction handling
- Next step: Investigation needed - transaction behavior changed unexpectedly
- Session: db-refactor-004
- Modified: database.ts, transaction-manager.ts
- Test: npm test (23 failures, see test-results.log for details)

---

## Why This Format

This format ensures the developer can make decisions from their phone without needing their laptop:

- **STATUS** tells them severity at a glance
- **What was done** gives them context
- **Current state** tells them if anything works
- **Next step** tells them what action is needed
- **Session** helps them track multiple concurrent tasks
- **Modified** helps them understand scope
- **Test** lets them verify when they're at a computer

Write your final message as if you're briefing them on a phone call. Be specific. Be actionable. Help them make the right decision quickly.

---

## Additional Guidelines

### Be Specific

**Bad:** "Added some error handling"  
**Good:** "Added try-catch blocks to all API calls with specific error messages for timeout, auth failure, and network errors"

### Include Metrics When Relevant

**Bad:** "Performance improved"  
**Good:** "Load time reduced from 850ms to 340ms (60% improvement) on 10,000 record dataset"

### Link to Evidence

**Bad:** "Tests are passing"  
**Good:** "All 47 tests passing - see test-results.txt for coverage report (87% line coverage)"

### Anticipate Questions

Think about what the developer will want to know:
- Does it actually work?
- What could go wrong?
- How do I verify it?
- What's the next logical step?

Answer these preemptively in your status.

---

## Session Naming

Use descriptive, hierarchical session IDs:

**Format:** `{feature}-{component}-{number}`

**Examples:**
- `auth-middleware-001`
- `video-editor-waveforms-002`
- `db-migration-users-003`
- `api-endpoints-payments-001`

**Why:** Makes it easy to track related work and find past sessions

---

## When to Stop

Stop and request input when:

1. **Architectural decisions** - Multiple valid approaches, each with tradeoffs
2. **Breaking changes** - Changes that affect existing functionality or APIs
3. **Security implications** - Authentication, authorization, data handling
4. **Resource decisions** - Database schema, API design, infrastructure choices
5. **Uncertainty** - When you're not confident about the right approach

**Don't stop for:**
- Implementation details (variable names, file structure)
- Testing approaches (write comprehensive tests)
- Code style (follow established patterns)
- Minor refactoring (improve as you go)

---

## Testing Before Reporting Complete

**Always include test results in COMPLETED status:**

```
**STATUS: COMPLETED**

- What was done: User registration endpoint with email verification
- Current state: Endpoint working, 12 tests passing (unit + integration), email sending confirmed
- Next step: Ready for staging deployment
- Session: auth-registration-001  
- Modified: auth.routes.ts, user.service.ts, email.service.ts, auth.test.ts
- Test: npm test (12/12 passing) && curl -X POST localhost:5000/api/register -d '{"email":"test@example.com","password":"Test123!"}'
```

If tests aren't passing, status should be BLOCKED or ERROR.

---

## Error Handling

When reporting errors:

1. **Describe what you tried** - "Attempted to connect to database using credentials from .env"
2. **Exact error message** - "Error: connect ECONNREFUSED 127.0.0.1:5432"
3. **What you checked** - "Verified PostgreSQL is running, checked port, confirmed credentials"
4. **What's needed** - "Need to check if database service is started or if connection string is correct"

---

## Remember

Your final message is the notification. Make it count.

The developer might be:
- At dinner
- On the beach  
- In a meeting
- About to fall asleep

Give them everything they need to make a good decision quickly.

**Think: "What would I want to know if I got this notification while away from my laptop?"**

That's what you write.
